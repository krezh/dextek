locals {
  talos_factory_id   = talos_image_factory_schematic.machine.id
  factory_kernel_url = "https://factory.talos.dev/image/${local.talos_factory_id}/${var.talos_version}/kernel-amd64"
  factory_initrd_url = "https://factory.talos.dev/image/${local.talos_factory_id}/${var.talos_version}/initramfs-amd64.xz"
}

variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster_name must not be empty."
  }
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster"
  type        = string
  validation {
    condition     = !can(regex("^https?://[^/]", var.cluster_endpoint))
    error_message = "The cluster_endpoint must not start with https:// or http://."
  }
}

variable "talos_version" {
  description = "The Talos version"
  type        = string
  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.talos_version))
    error_message = "The talos_version must be in the format vX.Y.Z."
  }
}

variable "kubernetes_version" {
  description = "The Kubernetes version"
  type        = string
  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "The kubernetes_version must be in the format vX.Y.Z."
  }
}

variable "talos_factory_schematic_endpoint" {
  description = "The api endpoint for factory schematics"
  type        = string
  default     = "https://factory.talos.dev/schematics"
  validation {
    condition     = can(regex("^https?://", var.talos_factory_schematic_endpoint))
    error_message = "The talos_factory_schematic_endpoint must be a valid URL."
  }
}

variable "matchbox_url" {
  description = "The Url to Matchbox"
  type        = string
  validation {
    condition     = can(regex("^https?://", var.matchbox_url))
    error_message = "The matchbox_url must be a valid URL."
  }
}

variable "matchbox_api" {
  description = "The API endpoint for Matchbox"
  type        = string
  validation {
    condition     = !can(regex("^https?://", var.matchbox_api))
    error_message = "The matchbox_api must not start with https:// or http://"
  }
}

variable "matchbox_private_key" {
  description = "The private key for Matchbox host"
  type        = string
  validation {
    condition     = length(var.matchbox_private_key) > 0
    error_message = "The matchbox_private_key must not be empty."
  }
}
variable "matchbox_client_cert" {
  description = "The client certificate for Matchbox"
  type        = string
  validation {
    condition     = length(var.matchbox_client_cert) > 0
    error_message = "The matchbox_client_cert must not be empty."
  }
}
variable "matchbox_client_key" {
  description = "The client key for Matchbox"
  type        = string
  validation {
    condition     = length(var.matchbox_client_key) > 0
    error_message = "The matchbox_client_key must not be empty."
  }
}
variable "matchbox_ca" {
  description = "The CA certificate for Matchbox"
  type        = string
  validation {
    condition     = length(var.matchbox_ca) > 0
    error_message = "The matchbox_ca must not be empty."
  }
}

variable "factory_repo_url" {
  description = "The Url to Registry for Factory Images"
  type        = string
  default     = "factory.talos.dev"
}

variable "factory_schematic_file" {
  description = "The file path to the Talos factory schematic"
  type        = string
  default     = "schematic.yaml"
  validation {
    condition     = length(var.factory_schematic_file) > 0
    error_message = "The factory_schematic_file must not be empty."
  }
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

variable "cluster_subnet" {
  description = "The subnet for the cluster"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.cluster_subnet))
    error_message = "The cluster_subnet must be a valid CIDR notation."
  }
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

variable "upsmonHost" {
  description = "The host for the NUT UPS monitoring"
  type        = string
  validation {
    condition     = length(var.upsmonHost) > 0
    error_message = "The upsmonHost must not be empty."
  }
}
variable "upsmonPasswd" {
  description = "The password for the NUT UPS monitoring"
  type        = string
  validation {
    condition     = length(var.upsmonPasswd) > 0
    error_message = "The upsmonPasswd must not be empty."
  }
}

variable "cluster_vip" {
  description = "VIP address for the controlplane"
  type        = string
  validation {
    condition     = can(cidrnetmask("${var.cluster_vip}/24"))
    error_message = "The VIP address must be a valid IPv4 address."
  }
}
