package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/template"
)

type TemplateContext struct {
	ClusterName       string
	ClusterEndpoint   string
	TalosVersion      string
	KubernetesVersion string
	SchematicID       string
	Data              map[string]any
	Node              NodeContext
}

type NodeContext struct {
	Host string
	Role string
}

// roleDir maps Talos machine type ("controlplane") to the patch directory name ("control-plane").
func roleDir(role string) string {
	if role == "controlplane" {
		return "control-plane"
	}
	return role
}

func nodePatches(node Node, ctx TemplateContext, sf *secretFetcher) ([]string, error) {
	var patches []string
	dirs := []string{"all", roleDir(node.Role), filepath.Join("node", node.Host)}
	for _, dir := range dirs {
		dirPatches, err := loadDir(dir, ctx, sf)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", dir, err)
		}
		patches = append(patches, dirPatches...)
	}
	return patches, nil
}

func loadDir(dir string, ctx TemplateContext, sf *secretFetcher) ([]string, error) {
	entries, err := os.ReadDir(dir)
	if os.IsNotExist(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	var names []string
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		name := e.Name()
		if strings.HasSuffix(name, ".yaml") || strings.HasSuffix(name, ".yaml.tmpl") {
			names = append(names, name)
		}
	}
	sort.Strings(names)

	var patches []string
	for _, name := range names {
		raw, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil {
			return nil, err
		}
		var content string
		if strings.HasSuffix(name, ".tmpl") {
			content, err = renderTemplate(string(raw), ctx, sf)
			if err != nil {
				return nil, fmt.Errorf("%s: %w", name, err)
			}
		} else {
			content = string(raw)
		}
		patches = append(patches, splitYAMLDocs(content)...)
	}
	return patches, nil
}

func splitYAMLDocs(content string) []string {
	var docs []string
	var cur strings.Builder
	for _, line := range strings.SplitAfter(content, "\n") {
		if strings.TrimRight(line, "\r\n") == "---" {
			if s := strings.TrimSpace(cur.String()); s != "" {
				docs = append(docs, s)
			}
			cur.Reset()
		} else {
			cur.WriteString(line)
		}
	}
	if s := strings.TrimSpace(cur.String()); s != "" {
		docs = append(docs, s)
	}
	return docs
}

func renderTemplate(tmpl string, ctx TemplateContext, sf *secretFetcher) (string, error) {
	t, err := template.New("").Funcs(template.FuncMap{
		"secret": sf.get,
	}).Parse(tmpl)
	if err != nil {
		return "", err
	}
	var buf bytes.Buffer
	if err := t.Execute(&buf, ctx); err != nil {
		return "", err
	}
	return buf.String(), nil
}
