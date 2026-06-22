package main

import (
	"os"

	"gopkg.in/yaml.v3"
)

const (
	matchboxURL     = "http://matchbox.int.plexuz.xyz:8080"
	matchboxAPIAddr = "matchbox.int.plexuz.xyz:8081"
)

type Cluster struct {
	TalosVersion      string `yaml:"talosVersion"`
	KubernetesVersion string `yaml:"kubernetesVersion"`
	ClusterName       string `yaml:"clusterName"`
	ClusterEndpoint   string `yaml:"clusterEndpoint"`
}

func loadCluster() (*Cluster, error) {
	data, err := os.ReadFile("talos-cluster.yaml")
	if err != nil {
		return nil, err
	}
	var c Cluster
	return &c, yaml.Unmarshal(data, &c)
}
