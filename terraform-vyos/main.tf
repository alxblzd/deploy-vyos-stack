terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.86"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  api_token = var.proxmox.api_token
  insecure  = var.proxmox.insecure

  ssh {
    agent       = false
    private_key = file("~/.ssh/id_rsa")
    username = var.proxmox.ssh_username
  }

}

# Parse SSH keys once for reuse
locals {
  ssh_keys_parsed = [
    for key in var.ssh_public_keys : {
      type = split(" ", key)[0]
      key  = split(" ", key)[1]
    }
  ]
}

resource "proxmox_virtual_environment_file" "vyos_userdata" {
  for_each     = { for vm in var.vyos_vms : vm.name => vm }
  datastore_id = var.datastore_snippet_id
  node_name    = var.proxmox.node_name
  content_type = "snippets" 

  source_raw {
    file_name = "cloud-init-${each.key}.yml"
    data = templatefile("${path.module}/cloud-init-vyos.tpl.yml", {
      hostname     = each.value.hostname
      wan_ip       = each.value.wan_ip
      wan_gateway  = each.value.wan_gateway
      timezone     = var.timezone
      ntp_server_1 = var.ntp_servers[0]
      ntp_server_2 = var.ntp_servers[1]
      ssh_port     = var.ssh_port
      ssh_keys     = local.ssh_keys_parsed
    })
  }
}

resource "proxmox_virtual_environment_vm" "vyos" {
  for_each = { for vm in var.vyos_vms : vm.name => vm }

  name        = each.value.name
  node_name   = var.proxmox.node_name
  description = "VyOS Router - Managed by Terraform\nHostname: ${each.value.hostname}\nZones: ${join(", ", [for zone in each.value.zone_interfaces : zone.name])}"
  tags        = concat(var.tags, ["router", "microsegmentation"])

  clone {
    vm_id        = var.vyos_template_id
    full         = true
    datastore_id = var.datastore_id
    retries      = 3
  }

  agent {
    enabled = true
    type    = "virtio"
  }

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = each.value.disk_gb
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge  = each.value.wan_bridge
    model   = "virtio"
    vlan_id = try(each.value.wan_vlan, null)
  }

  dynamic "network_device" {
    for_each = each.value.zone_interfaces
    content {
      bridge  = network_device.value.bridge
      model   = "virtio"
      vlan_id = try(network_device.value.vlan_id, null)
    }
  }

  # Cloud-Init Initialization
  initialization {
    type              = "nocloud"
    datastore_id      = var.datastore_id
    user_data_file_id = proxmox_virtual_environment_file.vyos_userdata[each.key].id
  }

  boot_order = var.boot_order
  started    = var.started

  lifecycle {
    ignore_changes = [
      network_device,
      started,
    ]
  }
}