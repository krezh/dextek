package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
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
	Host string
	Role string // "controlplane" or "worker" (Talos native value)
	MACs []string
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
	resource *talosmachine.Secrets
}

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		cluster, err := loadCluster()
		if err != nil {
			return fmt.Errorf("load cluster.yaml: %w", err)
		}

		schematicID, err := resolveSchematicID("schematic.yaml")
		if err != nil {
			return fmt.Errorf("resolve schematic: %w", err)
		}

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
		if writeMachineConfigs || writeTalosconfig {
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

		hashShort := schematicID[:10]
		kernelURL := fmt.Sprintf("%s/assets/talos/factory/%s/%s/kernel-amd64", matchboxURL, hashShort, cluster.TalosVersion)
		initrdURL := fmt.Sprintf("%s/assets/talos/factory/%s/%s/initramfs-amd64.xz", matchboxURL, hashShort, cluster.TalosVersion)

		assetDir := fmt.Sprintf("/var/lib/matchbox/assets/talos/factory/%s/%s", hashShort, cluster.TalosVersion)
		downloadCmd := fmt.Sprintf(
			`set -e; if [ ! -f "%s/kernel-amd64" ] || [ ! -f "%s/initramfs-amd64.xz" ]; then `+
				`mkdir -p "%s"; `+
				`curl --fail -Lo "%s/kernel-amd64" "https://factory.talos.dev/image/%s/%s/kernel-amd64"; `+
				`curl --fail -Lo "%s/initramfs-amd64.xz" "https://factory.talos.dev/image/%s/%s/initramfs-amd64.xz"; `+
				`fi`,
			assetDir, assetDir, assetDir,
			assetDir, schematicID, cluster.TalosVersion,
			assetDir, schematicID, cluster.TalosVersion,
		)
		_, err = remote.NewCommand(ctx, "get-talos", &remote.CommandArgs{
			Connection: remote.ConnectionArgs{
				Host:       pulumi.String("matchbox.int.plexuz.xyz"),
				User:       pulumi.StringPtr("matchbox"),
				PrivateKey: pulumi.StringPtr(matchboxSecrets["SSHKEY"]),
			},
			Create: pulumi.StringPtr(downloadCmd),
			Triggers: pulumi.Array{
				pulumi.String(schematicID),
				pulumi.String(cluster.TalosVersion),
			},
		})
		if err != nil {
			return err
		}

		for _, node := range nodes {
			tplCtx := TemplateContext{
				ClusterName:       cluster.ClusterName,
				ClusterEndpoint:   cluster.ClusterEndpoint,
				TalosVersion:      cluster.TalosVersion,
				KubernetesVersion: cluster.KubernetesVersion,
				SchematicID:       schematicID,
				Data: map[string]any{
					"factoryRepoUrl": "factory.talos.dev",
				},
				Node: NodeContext{
					Host: node.Host,
					Role: node.Role,
				},
			}

			patches, err := nodePatches(node, tplCtx, sf)
			if err != nil {
				return fmt.Errorf("patches for %s: %w", node.Host, err)
			}

			machineCfg := talosmachine.GetConfigurationOutput(ctx, talosmachine.GetConfigurationOutputArgs{
				ClusterName:       pulumi.String(cluster.ClusterName),
				ClusterEndpoint:   pulumi.String("https://" + cluster.ClusterEndpoint + ":6443"),
				MachineType:       pulumi.String(node.Role), // already "controlplane"/"worker" (Talos native)
				MachineSecrets:    ms.toInput(),
				ConfigPatches:     pulumi.ToStringArray(patches),
				TalosVersion:      pulumi.StringPtr(cluster.TalosVersion),
				KubernetesVersion: pulumi.StringPtr(cluster.KubernetesVersion),
				Docs:              pulumi.BoolPtr(false),
				Examples:          pulumi.BoolPtr(false),
			}, nil)

			if writeMachineConfigs {
				host := node.Host
				machineCfg.MachineConfiguration().ApplyT(func(cfg string) (string, error) {
					return "", os.WriteFile(filepath.Join("machineConfigs", host+".yaml"), []byte(cfg), 0600)
				})
			}

			profile, err := matchbox.NewProfile(ctx, "profile-"+node.Host, &matchbox.ProfileArgs{
				Name:    pulumi.String(node.Role + "-" + node.Host),
				Kernel:  pulumi.StringPtr(kernelURL),
				Initrds: pulumi.StringArray{pulumi.String(initrdURL)},
				Args: pulumi.StringArray{
					pulumi.String("initrd=initramfs-amd64.xz"),
					pulumi.String("init_on_alloc=1"),
					pulumi.String("slab_nomerge"),
					pulumi.String("pti=on"),
					pulumi.String("printk.devkmsg=on"),
					pulumi.String("panic=60"),
					pulumi.String("talos.platform=metal"),
					pulumi.String(fmt.Sprintf("talos.config=%s/ignition?mac=${mac:hexhyp}", matchboxURL)),
				},
				RawIgnition: machineCfg.MachineConfiguration().ApplyT(func(s string) *string { return &s }).(pulumi.StringPtrOutput),
			}, pulumi.Provider(mbProvider))
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

		ctx.Export("talosconfig", pulumi.ToSecret(talosconfig.TalosConfig()))

		if writeTalosconfig {
			talosconfig.TalosConfig().ApplyT(func(cfg string) (string, error) {
				return "", os.WriteFile(filepath.Join("machineConfigs", "talosconfig"), []byte(cfg), 0600)
			})
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

		nodes = append(nodes, node)
	}

	sort.Slice(nodes, func(i, j int) bool { return nodes[i].Host < nodes[j].Host })
	return nodes, nil
}

func resolveSchematicID(schematicFile string) (string, error) {
	content, err := os.ReadFile(schematicFile)
	if err != nil {
		return "", err
	}
	resp, err := http.Post("https://factory.talos.dev/schematics", "application/yaml", bytes.NewReader(content))
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("factory API returned %d", resp.StatusCode)
	}
	var result struct {
		ID string `json:"id"`
	}
	return result.ID, json.NewDecoder(resp.Body).Decode(&result)
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
	secrets, err := client.Secrets().List(infisical.ListSecretsOptions{
		ProjectID:   infisicalProjectID,
		Environment: infisicalEnv,
		SecretPath:  path,
	})
	if err != nil {
		return nil, err
	}
	out := make(map[string]string, len(secrets))
	for _, s := range secrets {
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

	// Write to Infisical once outputs are known. The result is exported so Pulumi
	// guarantees this ApplyT executes rather than treating it as unreferenced.
	infisicalDone := pulumi.All(generated.MachineSecrets, generated.ClientConfiguration).ApplyT(func(args []any) (string, error) {
		ms := args[0].(talosmachine.MachineSecrets)
		cc := args[1].(talosmachine.ClientConfiguration)
		return "", writeMachineSecretsToInfisical(client, ms, cc)
	}).(pulumi.StringOutput)
	ctx.Export("_infisicalReady", pulumi.ToSecret(infisicalDone))

	return &machineSecrets{resource: generated}, nil
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
