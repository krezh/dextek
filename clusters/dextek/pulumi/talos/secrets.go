package main

import (
	"fmt"
	"os"
	"strings"

	infisical "github.com/infisical/go-sdk"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	talosclient "github.com/pulumiverse/pulumi-talos/sdk/go/talos/client"
	talosmachine "github.com/pulumiverse/pulumi-talos/sdk/go/talos/machine"
)

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

	// RetainOnDelete: on subsequent runs secrets come from Infisical and this
	// resource is dropped from the program — retain prevents the provider from
	// attempting to "delete" generated crypto material.
	generated, err := talosmachine.NewSecrets(ctx, "machine-secrets", &talosmachine.SecretsArgs{
		TalosVersion: pulumi.StringPtr(talosVersion),
	}, pulumi.RetainOnDelete(true))
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
