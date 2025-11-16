# Cloud-Init Configuration for VyOS VMs
#
# This file handles:
# 1. Generating cloud-init user-data files from templates
# 2. Uploading them to Proxmox as snippets
# 3. Attaching them to VyOS VMs for first-boot configuration

# Generate cloud-init user-data from template
# Creates a separate cloud-init file for each VyOS VM
resource "local_file" "cloud_init" {
  for_each = { for vm in var.vyos_vms : vm.name => vm }

  filename = "${path.module}/generated/cloud-init-${each.value.name}.yml"

  content = templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    hostname         = each.value.hostname
    wan_ip           = each.value.wan_ip
    wan_gateway      = each.value.wan_gateway
    ssh_keys         = var.ssh_public_keys
    ansible_user     = var.ansible_user
    ansible_password = var.ansible_password
    vyos_password    = var.vyos_user_password
  })

  file_permission = "0600"
}

# NOTE: Cloud-init files are managed manually
# Upload cloud-init snippets to Proxmox using the upload-snippet.sh script:
#   ./upload-snippet.sh generated/cloud-init-<vm-name>.yml <proxmox-host>
#
# The files must exist at: local:snippets/cloud-init-<vm-name>.yml
# Terraform will reference them but NOT upload them automatically

# Removed automatic upload resource to avoid SSH authentication issues
# Cloud-init files should be uploaded manually once and updated as needed
