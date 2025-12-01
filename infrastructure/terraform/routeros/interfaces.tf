# ============================================================================
# Ethernet Interfaces (ether1-48)
# ============================================================================
# Active interfaces are uncommented and have descriptive comments
# Unused interfaces are commented out and marked as UNUSED

# ether1 - Heimdall
resource "routeros_interface_ethernet" "ether1" {
  factory_name = "ether1"
  name         = "ether1"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether2 - Asgard Eth0
resource "routeros_interface_ethernet" "ether2" {
  factory_name = "ether2"
  name         = "ether2"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether3 - Vanaheim Eth0
resource "routeros_interface_ethernet" "ether3" {
  factory_name = "ether3"
  name         = "ether3"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether4 - Alfheim Eth0
resource "routeros_interface_ethernet" "ether4" {
  factory_name = "ether4"
  name         = "ether4"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether5 - ms01-01 Eth0
resource "routeros_interface_ethernet" "ether5" {
  factory_name = "ether5"
  name         = "ether5"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether6 - ms01-02 Eth0
resource "routeros_interface_ethernet" "ether6" {
  factory_name = "ether6"
  name         = "ether6"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether7 - ms01-03 Eth0
resource "routeros_interface_ethernet" "ether7" {
  factory_name = "ether7"
  name         = "ether7"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# UNUSED
# resource "routeros_interface_ethernet" "ether8" {
#   factory_name = "ether8"
#   name         = "ether8"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# ether9 - Jotunheim
resource "routeros_interface_ethernet" "ether9" {
  factory_name = "ether9"
  name         = "ether9"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether10 - Jotunheim
resource "routeros_interface_ethernet" "ether10" {
  factory_name = "ether10"
  name         = "ether10"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether11 - Jotunheim
resource "routeros_interface_ethernet" "ether11" {
  factory_name = "ether11"
  name         = "ether11"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# UNUSED
# resource "routeros_interface_ethernet" "ether12" {
#   factory_name = "ether12"
#   name         = "ether12"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# ether13 - Switch U
resource "routeros_interface_ethernet" "ether13" {
  factory_name = "ether13"
  name         = "ether13"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# UNUSED
# resource "routeros_interface_ethernet" "ether14" {
#   factory_name = "ether14"
#   name         = "ether14"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether15" {
#   factory_name = "ether15"
#   name         = "ether15"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether16" {
#   factory_name = "ether16"
#   name         = "ether16"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether17" {
#   factory_name = "ether17"
#   name         = "ether17"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether18" {
#   factory_name = "ether18"
#   name         = "ether18"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether19" {
#   factory_name = "ether19"
#   name         = "ether19"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# ether20
resource "routeros_interface_ethernet" "ether20" {
  factory_name = "ether20"
  name         = "ether20"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether21 - RPI01
resource "routeros_interface_ethernet" "ether21" {
  factory_name = "ether21"
  name         = "ether21"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether22 - RPI02
resource "routeros_interface_ethernet" "ether22" {
  factory_name = "ether22"
  name         = "ether22"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether23 - UAP-PRO-U
resource "routeros_interface_ethernet" "ether23" {
  factory_name = "ether23"
  name         = "ether23"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether24 - UAP-PRO-N
resource "routeros_interface_ethernet" "ether24" {
  factory_name = "ether24"
  name         = "ether24"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# UNUSED
# resource "routeros_interface_ethernet" "ether25" {
#   factory_name = "ether25"
#   name         = "ether25"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether26" {
#   factory_name = "ether26"
#   name         = "ether26"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether27" {
#   factory_name = "ether27"
#   name         = "ether27"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether28" {
#   factory_name = "ether28"
#   name         = "ether28"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether29" {
#   factory_name = "ether29"
#   name         = "ether29"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether30" {
#   factory_name = "ether30"
#   name         = "ether30"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# ether31 - TESMART KVM
resource "routeros_interface_ethernet" "ether31" {
  factory_name = "ether31"
  name         = "ether31"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ether32 - PIKVM
resource "routeros_interface_ethernet" "ether32" {
  factory_name = "ether32"
  name         = "ether32"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# UNUSED
# resource "routeros_interface_ethernet" "ether33" {
#   factory_name = "ether33"
#   name         = "ether33"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether34" {
#   factory_name = "ether34"
#   name         = "ether34"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether35" {
#   factory_name = "ether35"
#   name         = "ether35"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether36" {
#   factory_name = "ether36"
#   name         = "ether36"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether37" {
#   factory_name = "ether37"
#   name         = "ether37"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether38" {
#   factory_name = "ether38"
#   name         = "ether38"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether39" {
#   factory_name = "ether39"
#   name         = "ether39"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# ether40
resource "routeros_interface_ethernet" "ether40" {
  factory_name = "ether40"
  name         = "ether40"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# UNUSED
# resource "routeros_interface_ethernet" "ether41" {
#   factory_name = "ether41"
#   name         = "ether41"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether42" {
#   factory_name = "ether42"
#   name         = "ether42"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether43" {
#   factory_name = "ether43"
#   name         = "ether43"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether44" {
#   factory_name = "ether44"
#   name         = "ether44"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether45" {
#   factory_name = "ether45"
#   name         = "ether45"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether46" {
#   factory_name = "ether46"
#   name         = "ether46"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "ether47" {
#   factory_name = "ether47"
#   name         = "ether47"
#   mtu          = 1500
#   poe_out      = "auto-on"
#   poe_priority = 10
#   comment      = var.comment
# }

# ether48 - Sector Alarm Controller
resource "routeros_interface_ethernet" "ether48" {
  factory_name = "ether48"
  name         = "ether48"
  mtu          = 1500
  poe_out      = "auto-on"
  poe_priority = 10
  comment      = var.comment
}

# ============================================================================
# SFP+ Interfaces (sfp-sfpplus1-4)
# ============================================================================
# All SFP+ interfaces are in use

# sfp-sfpplus1 - Jotunheim
resource "routeros_interface_ethernet" "sfp_sfpplus1" {
  factory_name             = "sfp-sfpplus1"
  name                     = "sfp-sfpplus1"
  mtu                      = 1500
  sfp_shutdown_temperature = 95
  comment                  = var.comment
}

# sfp-sfpplus2 - Alfheim
resource "routeros_interface_ethernet" "sfp_sfpplus2" {
  factory_name             = "sfp-sfpplus2"
  name                     = "sfp-sfpplus2"
  mtu                      = 1500
  sfp_shutdown_temperature = 95
  comment                  = var.comment
}

# sfp-sfpplus3 - Vanaheim
resource "routeros_interface_ethernet" "sfp_sfpplus3" {
  factory_name             = "sfp-sfpplus3"
  name                     = "sfp-sfpplus3"
  sfp_shutdown_temperature = 95
  comment                  = var.comment
}

# sfp-sfpplus4 - Asgard
resource "routeros_interface_ethernet" "sfp_sfpplus4" {
  factory_name             = "sfp-sfpplus4"
  name                     = "sfp-sfpplus4"
  mtu                      = 1500
  sfp_shutdown_temperature = 95
  comment                  = var.comment
}

# ============================================================================
# QSFP+1 Interfaces (qsfpplus1-1-4)
# ============================================================================
# All QSFP+1 interfaces are in use

# qsfpplus1-1 - ms01-01
resource "routeros_interface_ethernet" "qsfpplus1_1" {
  factory_name             = "qsfpplus1-1"
  name                     = "qsfpplus1-1"
  disable_running_check    = false
  mtu                      = 1500
  sfp_shutdown_temperature = 95
  comment                  = var.comment
}

# qsfpplus1-2 - ms01-02
resource "routeros_interface_ethernet" "qsfpplus1_2" {
  factory_name             = "qsfpplus1-2"
  name                     = "qsfpplus1-2"
  disable_running_check    = false
  mtu                      = 1500
  sfp_shutdown_temperature = 95
  comment                  = var.comment
}

# qsfpplus1-3 - ms01-03
resource "routeros_interface_ethernet" "qsfpplus1_3" {
  factory_name             = "qsfpplus1-3"
  name                     = "qsfpplus1-3"
  disable_running_check    = false
  mtu                      = 1500
  sfp_shutdown_temperature = 95
  comment                  = var.comment
}

# qsfpplus1-4 - ms01-04
resource "routeros_interface_ethernet" "qsfpplus1_4" {
  factory_name             = "qsfpplus1-4"
  name                     = "qsfpplus1-4"
  disable_running_check    = false
  mtu                      = 1500
  sfp_shutdown_temperature = 95
  comment                  = var.comment
}

# ============================================================================
# QSFP+2 Interfaces (qsfpplus2-1-4)
# ============================================================================
# All QSFP+2 interfaces are currently UNUSED and commented out

# UNUSED
# resource "routeros_interface_ethernet" "qsfpplus2_1" {
#   factory_name             = "qsfpplus2-1"
#   name                     = "qsfpplus2-1"
#   disable_running_check    = false
#   mtu                      = 1500
#   sfp_shutdown_temperature = 95
#   comment                  = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "qsfpplus2_2" {
#   factory_name             = "qsfpplus2-2"
#   name                     = "qsfpplus2-2"
#   disable_running_check    = false
#   mtu                      = 1500
#   sfp_shutdown_temperature = 95
#   comment                  = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "qsfpplus2_3" {
#   factory_name             = "qsfpplus2-3"
#   name                     = "qsfpplus2-3"
#   disable_running_check    = false
#   mtu                      = 1500
#   sfp_shutdown_temperature = 95
#   comment                  = var.comment
# }

# UNUSED
# resource "routeros_interface_ethernet" "qsfpplus2_4" {
#   factory_name             = "qsfpplus2-4"
#   name                     = "qsfpplus2-4"
#   disable_running_check    = false
#   mtu                      = 1500
#   sfp_shutdown_temperature = 95
#   comment                  = var.comment
# }
