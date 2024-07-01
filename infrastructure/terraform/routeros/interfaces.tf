variable "ether_range" {
  type = map(number)
  default = {
    "start" = 2
    "end"   = 48
  }
}

variable "sfpplus_range" {
  type = map(number)
  default = {
    "start" = 1
    "end"   = 4
  }
}

variable "qsfpplus1_range" {
  type = map(number)
  default = {
    "start" = 1
    "end"   = 4
  }
}

variable "qsfpplus2_range" {
  type = map(number)
  default = {
    "start" = 1
    "end"   = 4
  }
}

locals {
  sfpplus_interfaces = {
    for i in range(var.sfpplus_range.start, var.sfpplus_range.end + 1) :
    "sfp-sfpplus${i}" => {
      name    = "sfp-sfpplus${i}"
      comment = "${var.comment}"
    }
  }
  ether_interfaces = {
    for i in range(var.ether_range.start, var.ether_range.end + 1) :
    "ether${i}" => {
      name    = "ether${i}"
      comment = "${var.comment}"
    }
  }
  qsfpplus1_interfaces = {
    for i in range(var.qsfpplus1_range.start, var.qsfpplus1_range.end + 1) :
    "qsfpplus1-${i}" => {
      name    = "qsfpplus1-${i}"
      comment = "${var.comment}"
    }
  }
  qsfpplus2_interfaces = {
    for i in range(var.qsfpplus2_range.start, var.qsfpplus2_range.end + 1) :
    "qsfpplus2-${i}" => {
      name    = "qsfpplus2-${i}"
      comment = "${var.comment}"
    }
  }
}

resource "routeros_interface_ethernet" "ether" {
  for_each = local.ether_interfaces

  factory_name = each.value.name
  name         = each.value.name
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = each.value.comment
}

resource "routeros_interface_ethernet" "sfpplus" {
  for_each = local.sfpplus_interfaces

  factory_name             = each.value.name
  name                     = each.value.name
  mtu                      = 9000
  sfp_shutdown_temperature = 95
  comment                  = each.value.comment
}

resource "routeros_interface_ethernet" "qsfpplus1" {
  for_each = local.qsfpplus1_interfaces

  factory_name             = each.value.name
  name                     = each.value.name
  mtu                      = 9000
  sfp_shutdown_temperature = 95
  comment                  = each.value.comment
}

resource "routeros_interface_ethernet" "qsfpplus2" {
  for_each = local.qsfpplus2_interfaces

  factory_name             = each.value.name
  name                     = each.value.name
  mtu                      = 9000
  sfp_shutdown_temperature = 95
  comment                  = each.value.comment
}
