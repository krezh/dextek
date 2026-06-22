package main

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	infisical "github.com/infisical/go-sdk"
	"github.com/pulumi/pulumi-command/sdk/go/command/remote"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/pulumiverse/pulumi-matchbox/sdk/go/matchbox"
	talosclient "github.com/pulumiverse/pulumi-talos/sdk/go/talos/client"
	talosimgfactory "github.com/pulumiverse/pulumi-talos/sdk/go/talos/imagefactory"
	talosmachine "github.com/pulumiverse/pulumi-talos/sdk/go/talos/machine"
	"gopkg.in/yaml.v3"
)

const (
	infisicalProjectID = "5e13949c-f810-489d-88bd-0749b9474dbb"
	infisicalEnv       = "default"
	matchboxURL        = "http://matchbox.int.plexuz.xyz:8080"
	matchboxAPIAddr    = "matchbox.int.plexuz.xyz:8081"
)

type Cluster struct {
	TalosVersion      string `yaml:"talosVersion"`
	KubernetesVersion string `yaml:"kubernetesVersion"`
	ClusterName       string `yaml:"clusterName"`
	ClusterEndpoint   string `yaml:"clusterEndpoint"`
}

// Node is discovered from the node/ directory tree, not from cluster.yaml.
type Node struct {
	Host     string
	Role     string // "controlplane" or "worker" (Talos native value)
	MACs     []string
	Platform string // talos.platform from patch YAML, defaults to "metal"
	IP       string // first static IP found in addresses fields, used for bootstrap
}

// machineSecrets holds either raw values from Infisical or a reference to the
// generated Pulumi resource (used when secrets didn't exist yet).
type machineSecrets struct {
	// Set when read from Infisical
	clusterID                 string
	clusterSecret             string
	bootstrapToken            string
	secretboxEncryptionSecret string
	aescbcEncryptionSecret    string
	trustdToken               string
	etcdCert, etcdKey         string
	k8sCert, k8sKey           string
	k8sAggregatorCert         string
	k8sAggregatorKey          string
	k8sServiceaccountKey      string
	osCert, osKey             string
	clientCACert              string
	clientCert                string
	clientKey                 string

	// Set when freshly generated
	resource      *talosmachine.Secrets
	infisicalDone *pulumi.StringOutput // non-nil only when secrets were just generated
}

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		cluster, err := loadCluster()
		if err != nil {
			return fmt.Errorf("load cluster.yaml: %w", err)
		}

		schematicContent, err := os.ReadFile("schematic.yaml")
		if err != nil {
			return fmt.Errorf("read schematic.yaml: %w", err)
		}
		schematic, err := talosimgfactory.NewSchematic(ctx, "schematic", &talosimgfactory.SchematicArgs{
			Schematic: pulumi.StringPtr(string(schematicContent)),
		})
		if err != nil {
			return fmt.Errorf("create schematic: %w", err)
		}
		schematicID := schematic.ID().ToStringOutput()

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

		mbProvider, err := matchbox.NewProvider(ctx, "matchbox", &matchbox.ProviderArgs{
			Endpoint:   pulumi.String(matchboxAPIAddr),
			ClientCert: pulumi.String(matchboxSecrets["CLIENT_CRT"]),
			ClientKey:  pulumi.String(matchboxSecrets["CLIENT_KEY"]),
			Ca:         pulumi.String(matchboxSecrets["CA_CRT"]),
		})
		if err != nil {
			return err
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
			return err
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
				MachineType:       pulumi.String(node.Role), // already "controlplane"/"worker" (Talos native)
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
				return err
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
					return err
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
				return err
			}
		}

		return nil
	})
}

func loadCluster() (*Cluster, error) {
	data, err := os.ReadFile("cluster.yaml")
	if err != nil {
		return nil, err
	}
	var c Cluster
	return &c, yaml.Unmarshal(data, &c)
}

func discoverNodes() ([]Node, error) {
	entries, err := os.ReadDir("node")
	if err != nil {
		return nil, err
	}

	macRe := regexp.MustCompile(`(?i)([0-9a-f]{2}(?::[0-9a-f]{2}){5})`)

	var nodes []Node
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		host := e.Name()
		nodeDir := filepath.Join("node", host)

		files, err := os.ReadDir(nodeDir)
		if err != nil {
			return nil, err
		}

		node := Node{Host: host}

		for _, f := range files {
			if f.IsDir() {
				continue
			}
			name := f.Name()
			if strings.HasSuffix(name, ".tpl") || !strings.HasSuffix(name, ".yaml") {
				continue
			}

			raw, err := os.ReadFile(filepath.Join(nodeDir, name))
			if err != nil {
				return nil, err
			}

			dec := yaml.NewDecoder(bytes.NewReader(raw))
			for {
				var doc map[string]any
				if err := dec.Decode(&doc); err != nil {
					break
				}
				if doc == nil {
					continue
				}

				if machine, ok := doc["machine"].(map[string]any); ok {
					if t, ok := machine["type"].(string); ok && t != "" {
						node.Role = t
					}
				}

				if talos, ok := doc["talos"].(map[string]any); ok {
					if p, ok := talos["platform"].(string); ok && p != "" {
						node.Platform = p
					}
				}

				if addrs, ok := doc["addresses"].([]any); ok && node.IP == "" {
					for _, a := range addrs {
						var cidr string
						switch v := a.(type) {
						case string:
							cidr = v
						case map[string]any:
							cidr, _ = v["address"].(string)
						}
						if ip, _, found := strings.Cut(cidr, "/"); found && ip != "" {
							node.IP = ip
							break
						}
					}
				}

				if kind, _ := doc["kind"].(string); kind == "LinkAliasConfig" {
					if sel, ok := doc["selector"].(map[string]any); ok {
						if match, ok := sel["match"].(string); ok {
							for _, mac := range macRe.FindAllString(match, -1) {
								node.MACs = append(node.MACs, strings.ToLower(mac))
							}
						}
					}
				}
			}
		}

		if node.Role == "" {
			return nil, fmt.Errorf("node %s: no machine.type found in any patch file", host)
		}
		if len(node.MACs) == 0 {
			return nil, fmt.Errorf("node %s: no MAC addresses found in any patch file", host)
		}
		if node.Platform == "" {
			node.Platform = "metal"
		}

		nodes = append(nodes, node)
	}

	sort.Slice(nodes, func(i, j int) bool { return nodes[i].Host < nodes[j].Host })
	return nodes, nil
}

func newInfisicalClient() (infisical.InfisicalClientInterface, error) {
	client := infisical.NewInfisicalClient(context.Background(), infisical.Config{
		SiteUrl: "https://eu.infisical.com",
	})
	// Reads INFISICAL_UNIVERSAL_AUTH_CLIENT_ID and INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET from env
	_, err := client.Auth().UniversalAuthLogin("", "")
	if err != nil {
		return nil, err
	}
	return client, nil
}

func readFolder(client infisical.InfisicalClientInterface, path string) (map[string]string, error) {
	result, err := client.Secrets().ListSecrets(infisical.ListSecretsOptions{
		ProjectID:   infisicalProjectID,
		Environment: infisicalEnv,
		SecretPath:  path,
	})
	if err != nil {
		return nil, err
	}
	out := make(map[string]string, len(result.Secrets))
	for _, s := range result.Secrets {
		out[s.SecretKey] = s.SecretValue
	}
	return out, nil
}

func getOrCreateMachineSecrets(ctx *pulumi.Context, client infisical.InfisicalClientInterface, talosVersion string) (*machineSecrets, error) {
	existing, err := readFolder(client, "/Talos/Machine")
	if err != nil {
		return nil, err
	}

	if existing["CLUSTER_ID"] != "" {
		return &machineSecrets{
			clusterID:                 existing["CLUSTER_ID"],
			clusterSecret:             existing["CLUSTER_SECRET"],
			bootstrapToken:            existing["BOOTSTRAP_TOKEN"],
			secretboxEncryptionSecret: existing["SECRETBOX_ENCRYPTION_SECRET"],
			aescbcEncryptionSecret:    existing["AESCBC_ENCRYPTION_SECRET"],
			trustdToken:               existing["TRUSTDINFO_TOKEN"],
			etcdCert:                  existing["ETCD_CERT"],
			etcdKey:                   existing["ETCD_KEY"],
			k8sCert:                   existing["K8S_CERT"],
			k8sKey:                    existing["K8S_KEY"],
			k8sAggregatorCert:         existing["K8S_AGGREGATOR_CERT"],
			k8sAggregatorKey:          existing["K8S_AGGREGATOR_KEY"],
			k8sServiceaccountKey:      existing["K8S_SERVICEACCOUNT_KEY"],
			osCert:                    existing["OS_CERT"],
			osKey:                     existing["OS_KEY"],
			clientCACert:              existing["CLIENT_CA_CERT"],
			clientCert:                existing["CLIENT_CERT"],
			clientKey:                 existing["CLIENT_KEY"],
		}, nil
	}

	generated, err := talosmachine.NewSecrets(ctx, "machine-secrets", &talosmachine.SecretsArgs{
		TalosVersion: pulumi.StringPtr(talosVersion),
	})
	if err != nil {
		return nil, err
	}

	done := pulumi.All(generated.MachineSecrets, generated.ClientConfiguration).ApplyT(func(args []any) (string, error) {
		ms := args[0].(talosmachine.MachineSecrets)
		cc := args[1].(talosmachine.ClientConfiguration)
		return "", writeMachineSecretsToInfisical(client, ms, cc)
	}).(pulumi.StringOutput)

	return &machineSecrets{resource: generated, infisicalDone: &done}, nil
}

func writeMachineSecretsToInfisical(client infisical.InfisicalClientInterface, ms talosmachine.MachineSecrets, cc talosmachine.ClientConfiguration) error {
	type kv struct{ key, value string }
	pairs := []kv{
		{"CLUSTER_ID", ms.Cluster.Id},
		{"CLUSTER_SECRET", ms.Cluster.Secret},
		{"BOOTSTRAP_TOKEN", ms.Secrets.BootstrapToken},
		{"SECRETBOX_ENCRYPTION_SECRET", ms.Secrets.SecretboxEncryptionSecret},
		{"TRUSTDINFO_TOKEN", ms.Trustdinfo.Token},
		{"ETCD_CERT", ms.Certs.Etcd.Cert},
		{"ETCD_KEY", ms.Certs.Etcd.Key},
		{"K8S_CERT", ms.Certs.K8s.Cert},
		{"K8S_KEY", ms.Certs.K8s.Key},
		{"K8S_AGGREGATOR_CERT", ms.Certs.K8sAggregator.Cert},
		{"K8S_AGGREGATOR_KEY", ms.Certs.K8sAggregator.Key},
		{"K8S_SERVICEACCOUNT_KEY", ms.Certs.K8sServiceaccount.Key},
		{"OS_CERT", ms.Certs.Os.Cert},
		{"OS_KEY", ms.Certs.Os.Key},
		{"CLIENT_CA_CERT", cc.CaCertificate},
		{"CLIENT_CERT", cc.ClientCertificate},
		{"CLIENT_KEY", cc.ClientKey},
	}
	if ms.Secrets.AescbcEncryptionSecret != nil {
		pairs = append(pairs, kv{"AESCBC_ENCRYPTION_SECRET", *ms.Secrets.AescbcEncryptionSecret})
	}

	var errs []string
	for _, p := range pairs {
		if p.value == "" {
			continue
		}
		_, err := client.Secrets().Create(infisical.CreateSecretOptions{
			ProjectID:   infisicalProjectID,
			Environment: infisicalEnv,
			SecretPath:  "/Talos/Machine",
			SecretKey:   p.key,
			SecretValue: p.value,
		})
		if err != nil {
			fmt.Fprintf(os.Stderr, "warn: infisical create %s failed (%v), attempting update\n", p.key, err)
			_, err = client.Secrets().Update(infisical.UpdateSecretOptions{
				ProjectID:      infisicalProjectID,
				Environment:    infisicalEnv,
				SecretPath:     "/Talos/Machine",
				SecretKey:      p.key,
				NewSecretValue: p.value,
			})
			if err != nil {
				errs = append(errs, fmt.Sprintf("%s: %v", p.key, err))
			}
		}
	}
	if len(errs) > 0 {
		return fmt.Errorf("infisical write errors: %s", strings.Join(errs, "; "))
	}
	return nil
}

func (ms *machineSecrets) toInput() talosmachine.MachineSecretsInput {
	if ms.resource != nil {
		return ms.resource.MachineSecrets
	}
	return talosmachine.MachineSecretsArgs{
		Cluster: talosmachine.ClusterArgs{
			Id:     pulumi.String(ms.clusterID),
			Secret: pulumi.String(ms.clusterSecret),
		},
		Secrets: talosmachine.KubernetesSecretsArgs{
			BootstrapToken:            pulumi.String(ms.bootstrapToken),
			SecretboxEncryptionSecret: pulumi.String(ms.secretboxEncryptionSecret),
			AescbcEncryptionSecret:    pulumi.StringPtr(ms.aescbcEncryptionSecret),
		},
		Trustdinfo: talosmachine.TrustdInfoArgs{
			Token: pulumi.String(ms.trustdToken),
		},
		Certs: talosmachine.CertificatesArgs{
			Etcd:              talosmachine.CertificateArgs{Cert: pulumi.String(ms.etcdCert), Key: pulumi.String(ms.etcdKey)},
			K8s:               talosmachine.CertificateArgs{Cert: pulumi.String(ms.k8sCert), Key: pulumi.String(ms.k8sKey)},
			K8sAggregator:     talosmachine.CertificateArgs{Cert: pulumi.String(ms.k8sAggregatorCert), Key: pulumi.String(ms.k8sAggregatorKey)},
			K8sServiceaccount: talosmachine.KeyArgs{Key: pulumi.String(ms.k8sServiceaccountKey)},
			Os:                talosmachine.CertificateArgs{Cert: pulumi.String(ms.osCert), Key: pulumi.String(ms.osKey)},
		},
	}
}

func (ms *machineSecrets) bootstrapClientConfig() talosmachine.ClientConfigurationPtrInput {
	if ms.resource != nil {
		cc := ms.resource.ClientConfiguration
		return talosmachine.ClientConfigurationArgs{
			CaCertificate:     cc.CaCertificate(),
			ClientCertificate: cc.ClientCertificate(),
			ClientKey:         cc.ClientKey(),
		}
	}
	return talosmachine.ClientConfigurationArgs{
		CaCertificate:     pulumi.String(ms.clientCACert),
		ClientCertificate: pulumi.String(ms.clientCert),
		ClientKey:         pulumi.String(ms.clientKey),
	}
}

func (ms *machineSecrets) clientConfigArgs() talosclient.GetConfigurationClientConfigurationArgs {
	if ms.resource != nil {
		cc := ms.resource.ClientConfiguration
		return talosclient.GetConfigurationClientConfigurationArgs{
			CaCertificate:     cc.CaCertificate(),
			ClientCertificate: cc.ClientCertificate(),
			ClientKey:         cc.ClientKey(),
		}
	}
	return talosclient.GetConfigurationClientConfigurationArgs{
		CaCertificate:     pulumi.String(ms.clientCACert),
		ClientCertificate: pulumi.String(ms.clientCert),
		ClientKey:         pulumi.String(ms.clientKey),
	}
}

func filterNodes(nodes []Node, role string) []Node {
	var out []Node
	for _, n := range nodes {
		if n.Role == role {
			out = append(out, n)
		}
	}
	return out
}

func filterHosts(nodes []Node, role string) []string {
	var hosts []string
	for _, n := range nodes {
		if n.Role == role {
			hosts = append(hosts, n.Host)
		}
	}
	return hosts
}

func allHostnames(nodes []Node) []string {
	hosts := make([]string, len(nodes))
	for i, n := range nodes {
		hosts[i] = n.Host
	}
	return hosts
}
