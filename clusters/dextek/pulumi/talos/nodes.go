package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

// Node is discovered from the node/ directory tree, not from talos-cluster.yaml.
type Node struct {
	Host     string
	Role     string // "controlplane" or "worker" (Talos native value)
	MACs     []string
	Platform string // talos.platform from patch YAML, defaults to "metal"
	IP       string // first static IP found in addresses fields, used for bootstrap
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
			if strings.HasSuffix(name, ".tmpl") || !strings.HasSuffix(name, ".yaml") {
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
