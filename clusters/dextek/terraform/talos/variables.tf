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
