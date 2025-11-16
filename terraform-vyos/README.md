# VyOS Terraform Deployment

Terraform configuration for deploying VyOS routers on Proxmox VE with cloud-init.

## Prerequisites

- Proxmox VE with API access
- Terraform 
- VyOS cloud-init image (built using included script)
- SSH public keys

## Quick Start

### 1. Build VyOS Image

See readme at root of the repo

### 2. Configure

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

Configure your Proxmox endpoint, API token, SSH keys, and network zones.

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## Network Zones

Define VLAN-tagged zones for microsegmentation:

```hcl
zone_interfaces = [
  { name = "dmz",     bridge = "vmbr0", vlan_id = 10 },
  { name = "trusted", bridge = "vmbr0", vlan_id = 20 },
  { name = "guest",   bridge = "vmbr0", vlan_id = 30 },
  { name = "iot",     bridge = "vmbr0", vlan_id = 40 }
]
```

## Cloud-Init

The [cloud-init template](templates/cloud-init.yml.tftpl) configures:
- Hostname and timezone
- User accounts (vyos, ansible) with SSH keys
- WAN interface and gateway
- Basic system settings (NTP, DNS, SSH)

You have to upload it too proxmox as a snippet

## Next Steps

After deployment, configure VyOS with Ansible:

```bash
cd ../vyos-ansible-proxmox
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

## Troubleshooting

**Cloud-init not applied:**
```bash
ssh ansible@<vyos-ip>
show log cloud-init
```

**VM won't start:**
```bash
qm status <vm-id>
qm config <vm-id>
```

## References

- [VyOS Documentation](https://docs.vyos.io/)
- [Proxmox Terraform Provider](https://registry.terraform.io/providers/bpg/proxmox/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
