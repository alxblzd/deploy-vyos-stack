# Terraform Outputs for VyOS Deployment

# Summary of deployed VyOS instances
output "vyos_summary" {
  description = "Summary of deployed VyOS router instances"
  value = {
    count = length(var.vyos_vms)
    vms = { for k, v in proxmox_virtual_environment_vm.vyos :
      k => {
        name       = v.name
        id         = v.id
        vm_id      = v.vm_id
        cpu_cores  = v.cpu[0].cores
        memory_mb  = v.memory[0].dedicated
        wan_ip     = var.vyos_vms[index(var.vyos_vms.*.name, k)].wan_ip
        wan_bridge = var.vyos_vms[index(var.vyos_vms.*.name, k)].wan_bridge
        zone_count = length(var.vyos_vms[index(var.vyos_vms.*.name, k)].zone_interfaces)
      }
    }
  }
}

# Network zones configuration
output "vyos_network_zones" {
  description = "Network zones configured for each VyOS instance"
  value = { for k, v in var.vyos_vms :
    k => {
      hostname = v.hostname
      zones = [for zone in v.zone_interfaces : {
        name    = zone.name
        vlan_id = zone.vlan_id
        bridge  = zone.bridge
      }]
    }
  }
}

# Access information for deployed VMs
output "vyos_access_info" {
  description = "VyOS access information for SSH and management"
  value = { for k, v in proxmox_virtual_environment_vm.vyos :
    k => {
      vm_id       = v.vm_id
      wan_ip      = split("/", var.vyos_vms[index(var.vyos_vms.*.name, k)].wan_ip)[0]
      ssh_user    = var.ansible_user
      ssh_command = "ssh ${var.ansible_user}@${split("/", var.vyos_vms[index(var.vyos_vms.*.name, k)].wan_ip)[0]}"
      note        = "SSH access available via WAN IP. Use provided SSH keys for authentication."
    }
  }
}

# Ansible inventory data
output "vyos_ansible_inventory" {
  description = "Ansible inventory data for automation"
  value = { for k, v in var.vyos_vms :
    k => {
      ansible_host       = split("/", v.wan_ip)[0]
      ansible_user       = var.ansible_user
      ansible_network_os = "vyos"
      ansible_connection = "network_cli"
      hostname           = v.hostname
      zone_interfaces    = v.zone_interfaces
    }
  }
}

# Cloud-init status
output "cloud_init_status" {
  description = "Cloud-init configuration status"
  value = {
    template_id = var.vyos_template_id
    datastore   = var.cloud_init_datastore
    note        = "Cloud-init snippets managed manually via upload-snippet.sh"
  }
}

# Post-deployment steps
output "vyos_post_deployment" {
  description = "Post-deployment configuration steps"
  value       = <<-EOT
    VyOS Router Deployment Complete!

    Next Steps:

    1. Verify VyOS router is accessible:
       ${join("\n       ", [for k, v in var.vyos_vms : "ssh ${var.ansible_user}@${split("/", v.wan_ip)[0]}"])}

    2. Navigate to Ansible directory:
       cd ../vyos-ansible-proxmox

    3. Install VyOS Ansible collection:
       ansible-galaxy collection install vyos.vyos

    4. Update inventory with deployed VMs:
       Review inventory/hosts.yml

    5. Configure VyOS with Ansible:
       ansible-playbook site.yml

    6. Verify zone-based firewall:
       ssh ${var.ansible_user}@${split("/", var.vyos_vms[0].wan_ip)[0]}
       show firewall
       show interfaces

    For detailed configuration, see:
    - ../vyos-ansible-proxmox/README.md
    - ../vyos-ansible-proxmox/group_vars/vyos.yml

    Documentation:
    - VyOS User Guide: https://docs.vyos.io/
    - Zone-Based Firewall: https://docs.vyos.io/en/latest/configuration/firewall/zone.html
  EOT
}
