locals {
  talos_factory_id   = talos_image_factory_schematic.machine.id
  hash_short         = substr("${local.talos_factory_id}", 0, 10)
  factory_kernel_url = "${var.matchbox.url}/assets/talos/factory/${local.hash_short}/${local.cluster.talos_version}/kernel-amd64"
  factory_initrd_url = "${var.matchbox.url}/assets/talos/factory/${local.hash_short}/${local.cluster.talos_version}/initramfs-amd64.xz"
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


variable "template_vars" {
  description = "Additional variables to pass to all patch file templates"
  type        = map(string)
  default     = {}
}