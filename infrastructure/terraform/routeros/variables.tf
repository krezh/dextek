variable "comment" {
  description = "String used as comment to indicate resource managed by Terraform"
  type        = string
  default     = "Managed by Terraform"
}

variable "ingress_filtering" {
  description = "Enable ingress filtering on bridge ports"
  type        = bool
  default     = false
}
