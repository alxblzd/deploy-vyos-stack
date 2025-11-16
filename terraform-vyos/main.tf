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
}

# VyOS Virtual Machine Resource
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


  # Enable QEMU Guest Agent for better integration
  agent {
    enabled = true
    type    = "virtio"
  }

  # CPU Configuration
  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  # Memory Configuration
  memory {
    dedicated = each.value.memory_mb
  }


  # Disk Configuration
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = each.value.disk_gb
    iothread     = true
    discard      = "on"
  }

  # WAN Network Interface (eth0)
  network_device {
    bridge  = each.value.wan_bridge
    model   = "virtio"
    vlan_id = try(each.value.wan_vlan, null)
  }

  # Dynamic Zone Network Interfaces (eth1, eth2, eth3, etc.)
  # These will be configured by Ansible with VLANs and IP addresses
  dynamic "network_device" {
    for_each = each.value.zone_interfaces
    content {
      bridge  = network_device.value.bridge
      model   = "virtio"
      vlan_id = network_device.value.vlan_id
    }
  }

  # Cloud-Init Initialization
  # IMPORTANT: For VyOS, we ONLY use user_data_file_id
  # Do NOT use ip_config - it causes Proxmox to override the custom user-data
  # Network configuration is handled via vyos_config_commands in the user-data file
  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = "local:snippets/cloud-init-${each.value.name}.yml"
  }

  # Boot Configuration
  boot_order = var.boot_order
  started    = var.started

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore network device changes made by VyOS
      network_device,
      # Keep VM running state as configured
      started,
    ]
  }
}
