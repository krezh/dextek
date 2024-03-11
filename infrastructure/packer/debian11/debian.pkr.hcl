variable "proxmox_url" {
  type    = string
  default = "https://alfheim.usr.int.plexuz.xyz:8006/api2/json"
}

variable "proxmox_username" {
  type    = string
  default = "root@pam"
}

variable "vm_id" {
  type    = string
  default = "2000"
}

source "proxmox" "debian11" {
  boot_command = [
    "<wait5>",
    "<down> e",
    "<wait1>",
    "<down><down><down><END>",
    "<wait1>",
    "auto=true url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "<wait2>",
    "priority=critical",
    "<wait1>",
    "<F10>"
  ]
  boot_wait       = "6s"
  cpu_type        = "kvm64"
  bios            = "ovmf"
  efidisk         = "ceph-vmpool"
  onboot          = true
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size         = "8G"
    storage_pool      = "ceph-vmpool"
    storage_pool_type = "rbd"
    type              = "scsi"
    io_thread         = "true"
    cache_mode        = "writeback"
  }
  http_directory   = "http"
  iso_file         = "Jotunheim:iso/debian-11.4.0-amd64-netinst.iso"
  iso_storage_pool = "Jotunheim"
  memory           = 4096
  cores            = 4
  sockets          = 1
  os               = "l26"
  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    vlan_tag = "10"
    firewall = false
  }
  node                    = "alfheim"
  cloud_init              = true
  cloud_init_storage_pool = "ceph-vmpool"
  qemu_agent              = true
  proxmox_url             = var.proxmox_url
  ssh_username            = "packer"
  ssh_password            = "packer"
  ssh_timeout             = "20m"
  template_name           = "debian11"
  vm_id                   = var.vm_id
  unmount_iso             = true
  username                = var.proxmox_username

}

build {
  sources = ["source.proxmox.debian11"]

  provisioner "shell" {
    execute_command   = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    expect_disconnect = true
    skip_clean        = true

    scripts = [
      "scripts/install-saltstack.sh",
      "scripts/salt-minion.sh",
      "scripts/cleanup.sh"
    ]
  }
}
