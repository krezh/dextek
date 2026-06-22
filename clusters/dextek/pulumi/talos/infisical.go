package main

import (
	"context"
	"fmt"
	"os"

	infisical "github.com/infisical/go-sdk"
)

const (
	infisicalProjectID = "5e13949c-f810-489d-88bd-0749b9474dbb"
	infisicalEnv       = "default"
)

func newInfisicalClient() (infisical.InfisicalClientInterface, error) {
	clientID := os.Getenv("INFISICAL_UNIVERSAL_AUTH_CLIENT_ID")
	clientSecret := os.Getenv("INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET")
	if clientID == "" || clientSecret == "" {
		return nil, fmt.Errorf("INFISICAL_UNIVERSAL_AUTH_CLIENT_ID and INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET must be set")
	}
	client := infisical.NewInfisicalClient(context.Background(), infisical.Config{
		SiteUrl: "https://eu.infisical.com",
	})
	_, err := client.Auth().UniversalAuthLogin(clientID, clientSecret)
	if err != nil {
		return nil, fmt.Errorf("infisical auth: %w", err)
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

type secretFetcher struct {
	client infisical.InfisicalClientInterface
	cache  map[string]map[string]string
}

func newSecretFetcher(client infisical.InfisicalClientInterface) *secretFetcher {
	return &secretFetcher{client: client, cache: make(map[string]map[string]string)}
}

func (sf *secretFetcher) get(path, key string) (string, error) {
	if _, ok := sf.cache[path]; !ok {
		secrets, err := readFolder(sf.client, path)
		if err != nil {
			return "", fmt.Errorf("secret %s: %w", path, err)
		}
		sf.cache[path] = secrets
	}
	v, ok := sf.cache[path][key]
	if !ok {
		return "", fmt.Errorf("secret %s/%s not found", path, key)
	}
	return v, nil
}
