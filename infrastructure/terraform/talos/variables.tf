locals {
  kernel_cached         = "${var.matchbox_url}/assets/talos/${var.talos_version}/vmlinuz-amd64"
  initrd_cached         = "${var.matchbox_url}/assets/talos/${var.talos_version}/initramfs-amd64.xz"
  talos_factory_id      = jsondecode(data.http.factory_id.response_body).id
  hash_short            = substr("${local.talos_factory_id}", 0, 10)
  kernel_cached_factory = "${var.matchbox_url}/assets/talos/factory/${local.hash_short}/${var.talos_version}/kernel-amd64"
  initrd_cached_factory = "${var.matchbox_url}/assets/talos/factory/${local.hash_short}/${var.talos_version}/initramfs-amd64.xz"
}

variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster"
  type        = string
  default     = "https://192.168.20.5:6443"
}

variable "talos_version" {
  description = "The Talos version"
  type        = string
  default     = "v1.7.5" # renovate: datasource=github-releases depName=siderolabs/talos
}

variable "kubernetes_version" {
  description = "The Kubernetes version"
  type        = string
  default     = "v1.30.2" # renovate: datasource=docker depName=ghcr.io/siderolabs/kubelet
}

variable "talos_factory_schematic_endpoint" {
  description = "The api endpoint for factory schematics"
  type        = string
  default     = "https://factory.talos.dev/schematics"
}

variable "matchbox_url" {
  description = "The Url to Matchbox"
  type        = string
  default     = "http://matchbox.int.plexuz.xyz:8080"
}

variable "zot_factory_url" {
  description = "The Url to Zot Registry for Factory Images"
  type        = string
  default     = "zot.int.plexuz.xyz/factory.talos.dev"
}

variable "bootstrap" {
  description = "If set to true, start bootstrap"
  type        = bool
  default     = false
}

variable "talosconfig" {
  description = "If set to true, create talosconfig"
  type        = bool
  default     = false
}

variable "machine_yaml" {
  description = "If set to true, create machine.yaml"
  type        = bool
  default     = false
}

variable "nodes" {
  description = "A map of node data"
  type = map(object({
    hostname   = string
    type       = string
    mac_addr   = string
    disk_model = string
    driver     = string
    driver_10g = string
  }))
}

variable "vip" {
  description = "VIP address for the controlplane"
}
