resource "routeros_interface_bridge_port" "ether1" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether1"
  pvid      = 1
  comment   = "Heimdall: ${var.comment}"
}

resource "routeros_interface_bridge_port" "asgard_eth0" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether2"
  pvid      = 20
  comment   = "Asgard Eth0: ${var.comment}"
}

resource "routeros_interface_bridge_port" "vanaheim_eth0" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether3"
  pvid      = 20
  comment   = "Vanaheim Eth0: ${var.comment}"
}

resource "routeros_interface_bridge_port" "alfheim_eth0" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether4"
  pvid      = 20
  comment   = "Alfheim Eth0: ${var.comment}"
}

resource "routeros_interface_bridge_port" "ms01-01_eth0" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether5"
  pvid      = 20
  comment   = "ms01-01 Eth0: ${var.comment}"
}

resource "routeros_interface_bridge_port" "ether6" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether6"
  pvid      = 20
  comment   = var.comment
}

resource "routeros_interface_bridge_port" "ether7" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether7"
  pvid      = 20
  comment   = var.comment
}

resource "routeros_interface_bridge_port" "ether9" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether9"
  pvid      = 1
  comment   = "Jotunheim: ${var.comment}"
}

resource "routeros_interface_bridge_port" "ether20" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether20"
  pvid      = 1
  comment   = var.comment
}

resource "routeros_interface_bridge_port" "ether21" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether21"
  pvid      = 1
  comment   = "RPI01: ${var.comment}"
}

resource "routeros_interface_bridge_port" "ether22" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether22"
  pvid      = 1
  comment   = "RPI02: ${var.comment}"
}

resource "routeros_interface_bridge_port" "ether23" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether23"
  pvid      = 1
  comment   = "UAP-PRO-U: ${var.comment}"
}

resource "routeros_interface_bridge_port" "ether24" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether24"
  pvid      = 1
  comment   = "UAP-PRO-N: ${var.comment}"
}

resource "routeros_interface_bridge_port" "ether40" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether40"
  pvid      = 1
  comment   = var.comment
}

resource "routeros_interface_bridge_port" "ether48" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "ether48"
  pvid      = 100
  comment   = "Sector Alarm Controller: ${var.comment}"
}

resource "routeros_interface_bridge_port" "sfp-sfpplus1" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "sfp-sfpplus1"
  pvid      = 200
  comment   = "Jotunheim: ${var.comment}"
}

resource "routeros_interface_bridge_port" "sfp-sfpplus2" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "sfp-sfpplus2"
  pvid      = 200
  comment   = "Alfheim: ${var.comment}"
}

resource "routeros_interface_bridge_port" "sfp-sfpplus3" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "sfp-sfpplus3"
  pvid      = 200
  comment   = "Vanaheim: ${var.comment}"
}

resource "routeros_interface_bridge_port" "sfp-sfpplus4" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "sfp-sfpplus4"
  pvid      = 200
  comment   = "Asgard: ${var.comment}"
}

resource "routeros_interface_bridge_port" "qsfpplus1-1" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "qsfpplus1-1"
  pvid      = 200
  comment   = "ms01-01: ${var.comment}"
}

resource "routeros_interface_bridge_port" "qsfpplus1-2" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "qsfpplus1-2"
  pvid      = 200
  comment   = "ms01-02: ${var.comment}"
}

resource "routeros_interface_bridge_port" "qsfpplus1-3" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "qsfpplus1-3"
  pvid      = 200
  comment   = "ms01-03: ${var.comment}"
}

resource "routeros_interface_bridge_port" "qsfpplus1-4" {
  bridge    = routeros_interface_bridge.bridge.name
  interface = "qsfpplus1-4"
  pvid      = 200
  comment   = "ms01-04: ${var.comment}"
}