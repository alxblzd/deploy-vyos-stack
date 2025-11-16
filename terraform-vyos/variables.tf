variable "proxmox" {
  type = object({
    endpoint     = string
    api_token    = string
    insecure     = bool
    node_name    = string
    ssh_username = string
  })
  description = "Proxmox connection configuration"
}

variable "vyos_vms" {
  type = list(object({
    name        = string
    hostname    = string
    cpu_cores   = number
    memory_mb   = number
    disk_gb     = number
    wan_bridge  = string
    wan_vlan    = optional(number)
    wan_ip      = string # CIDR notation: "192.168.15.81/24"
    wan_gateway = string
    zone_interfaces = list(object({
      name    = string
      bridge  = string
      vlan_id = number
    }))
  }))
  description = "VyOS router configurations"

  validation {
    condition = alltrue([
      for vm in var.vyos_vms :
      length(vm.zone_interfaces) == length(distinct([for zone in vm.zone_interfaces : zone.vlan_id]))
    ])
    error_message = "VLAN IDs must be unique within each router. Duplicate VLAN IDs detected in zone_interfaces."
  }

  validation {
    condition = alltrue([
      for vm in var.vyos_vms :
      alltrue([for zone in vm.zone_interfaces : zone.vlan_id >= 1 && zone.vlan_id <= 4094])
    ])
    error_message = "VLAN IDs must be between 1 and 4094 (valid VLAN range)."
  }

  validation {
    condition = alltrue([
      for vm in var.vyos_vms :
      length(vm.zone_interfaces) == length(distinct([for zone in vm.zone_interfaces : zone.name]))
    ])
    error_message = "Zone names must be unique within each router. Duplicate zone names detected."
  }
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "SSH public keys for authentication"
}

variable "ansible_user" {
  type        = string
  default     = "ansible"
  description = "Ansible automation user with sudo rights"
}

variable "ansible_password" {
  type        = string
  sensitive   = true
  description = "Password for ansible user"

  validation {
    condition     = length(var.ansible_password) >= 12
    error_message = "Security Error: ansible_password must be at least 12 characters long."
  }
}

variable "vyos_user_password" {
  type        = string
  sensitive   = true
  description = "Password for vyos default user"
  default     = "vyos"

  validation {
    condition     = var.vyos_user_password != "vyos"
    error_message = "Security Error: vyos_user_password must not be the default 'vyos' password. Set a strong password (16+ characters recommended)."
  }

  validation {
    condition     = length(var.vyos_user_password) >= 12
    error_message = "Security Error: vyos_user_password must be at least 12 characters long."
  }
}

variable "tags" {
  type        = list(string)
  default     = ["terraform", "vyos"]
  description = "Tags to apply to VMs"
}

variable "datastore_id" {
  type        = string
  default     = "local-lvm"
  description = "Datastore for VM disks"
}
variable "datastore_snippet_id" {
  type        = string
  default     = "local"
  description = "Datastore for snippet"
}
variable "cloud_init_datastore" {
  type        = string
  default     = "local"
  description = "Datastore for cloud-init snippets and images"
}

variable "vyos_template_id" {
  type        = number
  description = "VM ID of the VyOS template to clone from"
}

variable "boot_order" {
  type        = list(string)
  default     = ["scsi0"]
  description = "Boot order for VMs"
}

variable "started" {
  type        = bool
  default     = true
  description = "Start VMs after creation"
}

variable "timezone" {
  type        = string
  default     = "UTC"
  description = "Timezone for VyOS routers"
}

variable "ntp_servers" {
  type        = list(string)
  default     = ["0.pool.ntp.org", "1.pool.ntp.org"]
  description = "NTP servers for time synchronization"
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH port for VyOS routers"
}
