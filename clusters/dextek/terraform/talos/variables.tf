locals {
  talos_factory_id      = talos_image_factory_schematic.machine.id
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
}

variable "talos_version" {
  description = "The Talos version"
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version"
  type        = string
}

variable "talos_factory_schematic_endpoint" {
  description = "The api endpoint for factory schematics"
  type        = string
  default     = "https://factory.talos.dev/schematics"
}

variable "matchbox_url" {
  description = "The Url to Matchbox"
  type        = string
}

variable "zot_factory_url" {
  description = "The Url to Zot Registry for Factory Images"
  type        = string
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
    role       = string # controlplane, worker
    mac_addr   = string
    disk_model = string
    driver     = string
    driver_10g = string
  }))
  validation {
    condition     = length(var.nodes) > 0
    error_message = "The nodes variable must contain at least one node."
  }
  validation {
    condition     = alltrue([for node in var.nodes : contains(["controlplane", "worker"], node.role)])
    error_message = "The role must be either controlplane or worker."
  }
  validation {
    condition     = alltrue([for node in var.nodes : length(node.hostname) > 0])
    error_message = "The hostname must not be empty."
  }
  validation {
    condition     = alltrue([for node in var.nodes : length(node.mac_addr) > 0])
    error_message = "The mac_addr must not be empty."
  }
  validation {
    condition     = alltrue([for node in var.nodes : length(node.disk_model) > 0])
    error_message = "The disk_model must not be empty."
  }
  validation {
    condition     = alltrue([for node in var.nodes : length(node.driver) > 0])
    error_message = "The driver must not be empty."
  }
  validation {
    condition     = alltrue([for node in var.nodes : length(node.driver_10g) > 0])
    error_message = "The driver_10g must not be empty."
  }
}

variable "vip" {
  description = "VIP address for the controlplane"
  type        = string
  validation {
    condition     = can(cidrnetmask("${var.vip}/24"))
    error_message = "The VIP address must be a valid IPv4 address."
  }
}
