locals {
  talos_factory_id   = talos_image_factory_schematic.machine.id
  hash_short         = substr("${local.talos_factory_id}", 0, 10)
  factory_kernel_url = "${var.matchbox.url}/assets/talos/factory/${local.hash_short}/${var.talos_version}/kernel-amd64"
  factory_initrd_url = "${var.matchbox.url}/assets/talos/factory/${local.hash_short}/${var.talos_version}/initramfs-amd64.xz"
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

variable "cluster_vip" {
  description = "VIP address for the controlplane"
  type        = string
  validation {
    condition     = can(cidrnetmask("${var.cluster_vip}/24"))
    error_message = "The VIP address must be a valid IPv4 address."
  }
}

variable "cluster_subnet" {
  description = "The subnet for the cluster"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.cluster_subnet))
    error_message = "The cluster_subnet must be a valid CIDR notation."
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

variable "factory_schematic_endpoint" {
  description = "The api endpoint for factory schematics"
  type        = string
  default     = "https://factory.talos.dev/schematics"
  validation {
    condition     = can(regex("^https?://", var.factory_schematic_endpoint))
    error_message = "The factory_schematic_endpoint must be a valid URL."
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
}

variable "matchbox" {
  description = "Matchbox configuration"
  type = object({
    url         = string
    api         = string
    host        = string
    user        = string
    private_key = string
    client_cert = string
    client_key  = string
    ca          = string
  })
  validation {
    condition     = can(regex("^https?://", var.matchbox.url))
    error_message = "The matchbox.url must be a valid URL."
  }
  validation {
    condition     = !can(regex("^https?://", var.matchbox.api))
    error_message = "The matchbox.api must not start with https:// or http://"
  }
  validation {
    condition     = length(var.matchbox.host) > 0
    error_message = "The matchbox.host must not be empty."
  }
  validation {
    condition     = length(var.matchbox.user) > 0
    error_message = "The matchbox.user must not be empty."
  }
  validation {
    condition     = length(var.matchbox.private_key) > 0
    error_message = "The matchbox.private_key must not be empty."
  }
  validation {
    condition     = length(var.matchbox.client_cert) > 0
    error_message = "The matchbox.client_cert must not be empty."
  }
  validation {
    condition     = length(var.matchbox.client_key) > 0
    error_message = "The matchbox.client_key must not be empty."
  }
  validation {
    condition     = length(var.matchbox.ca) > 0
    error_message = "The matchbox.ca must not be empty."
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

variable "nodes" {
  description = "A map of node data"
  type = map(object({
    hostname     = string
    platform     = optional(string, "metal") # metal, etc.
    role         = string                    # controlplane, worker
    mac_addr     = string
    mac_addr2    = string
    mac_addr_10g = optional(string, "none")
    disk_model   = string
    driver       = string
    driver_10g   = optional(string, "none")
    node_labels  = optional(map(string), {})
    interfaces   = optional(any)
    static_ip_10g = optional(string, "none")
  }))
  validation {
    condition     = length(var.nodes) > 0
    error_message = "The nodes variable must contain at least one node."
  }
  validation {
    condition     = alltrue([for node in var.nodes : contains(["metal"], node.platform)])
    error_message = "The platform must only contain alphanumeric characters and hyphens."
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
    condition     = alltrue([for node in var.nodes : can(regex("^[a-fA-F0-9:]+$", node.mac_addr))])
    error_message = "The mac_addr must be a valid MAC address."
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
    condition = alltrue([
      for node in var.nodes : (
        node.node_labels == null ||
        alltrue([
          for k, v in node.node_labels :
          can(regex("^(?:(?:[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?)*)\\/)?[a-zA-Z0-9]([-a-zA-Z0-9_.]*[a-zA-Z0-9])?$", k)) &&
          can(regex("^([a-zA-Z0-9]([-a-zA-Z0-9_.]*[a-zA-Z0-9])?)?$", v))
        ])
      )
    ])
    error_message = "All node_labels keys and values must conform to Kubernetes label requirements."
  }
}

variable "upsmon" {
  description = "Configuration for the NUT UPS monitoring"
  type = object({
    host     = string
    password = string
  })
  validation {
    condition     = length(var.upsmon.host) > 0
    error_message = "The upsmon.host must not be empty."
  }
  validation {
    condition     = length(var.upsmon.password) > 0
    error_message = "The upsmon.password must not be empty."
  }
}
