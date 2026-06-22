package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pulumi/pulumi-command/sdk/go/command/remote"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/pulumiverse/pulumi-matchbox/sdk/go/matchbox"
	talosclient "github.com/pulumiverse/pulumi-talos/sdk/go/talos/client"
	talosimgfactory "github.com/pulumiverse/pulumi-talos/sdk/go/talos/imagefactory"
	talosmachine "github.com/pulumiverse/pulumi-talos/sdk/go/talos/machine"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		cluster, err := loadCluster()
		if err != nil {
			return fmt.Errorf("load talos-cluster.yaml: %w", err)
		}

		schematicContent, err := os.ReadFile("schematic.yaml")
		if err != nil {
			return fmt.Errorf("read schematic.yaml: %w", err)
		}
		fmt.Fprintln(os.Stderr, "connecting to factory.talos.dev...")
		schematic, err := talosimgfactory.NewSchematic(ctx, "schematic", &talosimgfactory.SchematicArgs{
			Schematic: pulumi.StringPtr(string(schematicContent)),
		})
		if err != nil {
			return fmt.Errorf("create schematic (factory.talos.dev): %w", err)
		}
		schematicID := schematic.ID().ToStringOutput()

		fmt.Fprintln(os.Stderr, "connecting to eu.infisical.com...")
		ic, err := newInfisicalClient()
		if err != nil {
			return fmt.Errorf("infisical client: %w", err)
		}

		matchboxSecrets, err := readFolder(ic, "/Talos/Matchbox")
		if err != nil {
			return fmt.Errorf("read /Talos/Matchbox: %w", err)
		}

		nodes, err := discoverNodes()
		if err != nil {
			return fmt.Errorf("discover nodes: %w", err)
		}

		sf := newSecretFetcher(ic)

		ms, err := getOrCreateMachineSecrets(ctx, ic, cluster.TalosVersion)
		if err != nil {
			return fmt.Errorf("machine secrets: %w", err)
		}

		writeMachineConfigs := os.Getenv("WRITE_MACHINE_CONFIGS") != ""
		writeTalosconfig := os.Getenv("WRITE_TALOSCONFIG") != ""
		if writeMachineConfigs {
			if err := os.MkdirAll("machineConfigs", 0700); err != nil {
				return fmt.Errorf("create machineConfigs dir: %w", err)
			}
		}

		fmt.Fprintf(os.Stderr, "connecting to matchbox (%s)...\n", matchboxAPIAddr)
		mbProvider, err := matchbox.NewProvider(ctx, "matchbox", &matchbox.ProviderArgs{
			Endpoint:   pulumi.String(matchboxAPIAddr),
			ClientCert: pulumi.String(matchboxSecrets["CLIENT_CRT"]),
			ClientKey:  pulumi.String(matchboxSecrets["CLIENT_KEY"]),
			Ca:         pulumi.String(matchboxSecrets["CA_CRT"]),
		})
		if err != nil {
			return fmt.Errorf("matchbox provider (%s): %w", matchboxAPIAddr, err)
		}

		// Truncated to 10 chars to keep matchbox asset paths short.
		kernelURL := schematicID.ApplyT(func(id string) string {
			return fmt.Sprintf("%s/assets/talos/factory/%s/%s/kernel-amd64", matchboxURL, id[:10], cluster.TalosVersion)
		}).(pulumi.StringOutput)
		initrdURL := schematicID.ApplyT(func(id string) string {
			return fmt.Sprintf("%s/assets/talos/factory/%s/%s/initramfs-amd64.xz", matchboxURL, id[:10], cluster.TalosVersion)
		}).(pulumi.StringOutput)

		downloadCmd := schematicID.ApplyT(func(id string) string {
			assetDir := fmt.Sprintf("/var/lib/matchbox/assets/talos/factory/%s/%s", id[:10], cluster.TalosVersion)
			return fmt.Sprintf(`set -e
mkdir -p "%s"
curl --fail -Lo "%s/kernel-amd64"       "https://factory.talos.dev/image/%s/%s/kernel-amd64"
curl --fail -Lo "%s/initramfs-amd64.xz" "https://factory.talos.dev/image/%s/%s/initramfs-amd64.xz"`,
				assetDir,
				assetDir, id, cluster.TalosVersion,
				assetDir, id, cluster.TalosVersion,
			)
		}).(pulumi.StringOutput)

		getTalosCmd, err := remote.NewCommand(ctx, "get-talos", &remote.CommandArgs{
			Connection: remote.ConnectionArgs{
				Host:       pulumi.String("matchbox.int.plexuz.xyz"),
				User:       pulumi.StringPtr("matchbox"),
				PrivateKey: pulumi.StringPtr(matchboxSecrets["SSHKEY"]),
			},
			Create: downloadCmd.ApplyT(func(s string) *string { return &s }).(pulumi.StringPtrOutput),
			Triggers: pulumi.Array{
				schematic.ID(),
				pulumi.String(cluster.TalosVersion),
			},
		})
		if err != nil {
			return fmt.Errorf("remote command get-talos (matchbox.int.plexuz.xyz): %w", err)
		}

		for _, node := range nodes {
			nodeCopy := node

			patchesOutput := schematicID.ApplyT(func(id string) ([]string, error) {
				tplCtx := TemplateContext{
					ClusterName:       cluster.ClusterName,
					ClusterEndpoint:   cluster.ClusterEndpoint,
					TalosVersion:      cluster.TalosVersion,
					KubernetesVersion: cluster.KubernetesVersion,
					SchematicID:       id,
					Data: map[string]any{
						"factoryRepoUrl": "factory.talos.dev",
					},
					Node: NodeContext{
						Host: nodeCopy.Host,
						Role: nodeCopy.Role,
					},
				}
				return nodePatches(nodeCopy, tplCtx, sf)
			}).(pulumi.StringArrayOutput)

			machineCfg := talosmachine.GetConfigurationOutput(ctx, talosmachine.GetConfigurationOutputArgs{
				ClusterName:       pulumi.String(cluster.ClusterName),
				ClusterEndpoint:   pulumi.String("https://" + cluster.ClusterEndpoint + ":6443"),
				MachineType:       pulumi.String(node.Role),
				MachineSecrets:    ms.toInput(),
				ConfigPatches:     patchesOutput,
				TalosVersion:      pulumi.StringPtr(cluster.TalosVersion),
				KubernetesVersion: pulumi.StringPtr(cluster.KubernetesVersion),
				Docs:              pulumi.BoolPtr(false),
				Examples:          pulumi.BoolPtr(false),
			}, nil)

			cfgOutput := machineCfg.MachineConfiguration()
			if writeMachineConfigs {
				host := node.Host
				cfgOutput = cfgOutput.ApplyT(func(cfg string) (string, error) {
					if err := os.WriteFile(filepath.Join("machineConfigs", host+".yaml"), []byte(cfg), 0600); err != nil {
						return "", fmt.Errorf("write machine config for %s: %v", host, err)
					}
					return cfg, nil
				}).(pulumi.StringOutput)
			}

			profile, err := matchbox.NewProfile(ctx, "profile-"+node.Host, &matchbox.ProfileArgs{
				Name:    pulumi.String(node.Role + "-" + node.Host),
				Kernel:  kernelURL.ApplyT(func(s string) *string { return &s }).(pulumi.StringPtrOutput),
				Initrds: initrdURL.ApplyT(func(s string) []string { return []string{s} }).(pulumi.StringArrayOutput),
				Args: pulumi.StringArray{
					pulumi.String("initrd=initramfs-amd64.xz"),
					pulumi.String("init_on_alloc=1"),
					pulumi.String("slab_nomerge"),
					pulumi.String("pti=on"),
					pulumi.String("printk.devkmsg=on"),
					pulumi.String("panic=60"),
					pulumi.String("talos.platform=" + node.Platform),
					pulumi.String(fmt.Sprintf("talos.config=%s/ignition?mac=${mac:hexhyp}", matchboxURL)),
				},
				RawIgnition: cfgOutput.ApplyT(func(s string) *string { return &s }).(pulumi.StringPtrOutput),
			}, pulumi.Provider(mbProvider), pulumi.DependsOn([]pulumi.Resource{getTalosCmd}))
			if err != nil {
				return fmt.Errorf("matchbox profile for node %s: %w", node.Host, err)
			}

			for _, mac := range node.MACs {
				safeName := node.Host + "-" + strings.ReplaceAll(mac, ":", "-")
				_, err = matchbox.NewGroup(ctx, "group-"+safeName, &matchbox.GroupArgs{
					Name:    pulumi.String(safeName),
					Profile: profile.Name,
					Selector: pulumi.StringMap{
						"mac": pulumi.String(strings.ToLower(mac)),
					},
				}, pulumi.Provider(mbProvider))
				if err != nil {
					return fmt.Errorf("matchbox group for node %s mac %s: %w", node.Host, mac, err)
				}
			}
		}

		cpHosts := filterHosts(nodes, "controlplane")
		allHosts := allHostnames(nodes)

		talosconfig := talosclient.GetConfigurationOutput(ctx, talosclient.GetConfigurationOutputArgs{
			ClusterName:         pulumi.String(cluster.ClusterName),
			ClientConfiguration: ms.clientConfigArgs(),
			Endpoints:           pulumi.ToStringArray(cpHosts),
			Nodes:               pulumi.ToStringArray(allHosts),
		}, nil)

		// Build talosconfig output, gated on Infisical write when secrets are freshly generated.
		var tcOutput pulumi.StringOutput
		if ms.infisicalDone != nil {
			tcOutput = pulumi.All(*ms.infisicalDone, talosconfig.TalosConfig()).ApplyT(
				func(args []any) (string, error) { return args[1].(string), nil },
			).(pulumi.StringOutput)
		} else {
			tcOutput = talosconfig.TalosConfig()
		}
		if writeTalosconfig {
			written := tcOutput.ApplyT(func(cfg string) (bool, error) {
				if err := os.MkdirAll("machineConfigs", 0700); err != nil {
					return false, err
				}
				return true, os.WriteFile("machineConfigs/talosconfig", []byte(cfg), 0600)
			}).(pulumi.BoolOutput)
			ctx.Export("talosconfig-written", written)
		}
		ctx.Export("schematicId", schematic.ID())

		if os.Getenv("BOOTSTRAP") != "" {
			cpNodes := filterNodes(nodes, "controlplane")
			if len(cpNodes) == 0 {
				return fmt.Errorf("bootstrap requested but no controlplane nodes found")
			}
			cp := cpNodes[0]
			endpoint := cp.IP
			if endpoint == "" {
				endpoint = cp.Host
			}
			_, err = talosmachine.NewBootstrap(ctx, "bootstrap", &talosmachine.BootstrapArgs{
				ClientConfiguration: ms.bootstrapClientConfig(),
				Node:                pulumi.String(endpoint),
				Endpoint:            pulumi.StringPtr(endpoint),
			})
			if err != nil {
				return fmt.Errorf("bootstrap node %s: %w", endpoint, err)
			}
		}

		return nil
	})
}
