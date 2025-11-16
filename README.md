# VyOS Router Deployment and maintenances tools

Iac for deploying and configuring VyOS routers, here on Proxmox VE with zone-based firewall.

## Project Structure

- **terraform-vyos/** - Terraform configuration for VM provisioning and cloud-init setup
- **ansible-vyos/** - Ansible playbooks and roles for VyOS router configuration

## Prerequisites

1. Proxmox VE server
2. VyOS cloud-init enabled template (see [Building VyOS Image](#building-vyos-cloud-init-image) below)
3. Terraform and Ansible installed locally

## Quick Start

```bash
# 1. Deploy VMs with Terraform
cd terraform-vyos
terraform init
terraform apply

# 2. Configure VyOS with Ansible
cd ../ansible-vyos
pip3 install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

## Cloud-Init Template

The Terraform deployment uses [templates/cloud-init.yml.tftpl](terraform-vyos/templates/cloud-init.yml.tftpl) to configure VyOS on first boot.

**What it configures:**
- System hostname and timezone
- User accounts (vyos and ansible users)
- SSH key deployment and authentication
- Network interfaces (WAN/eth0)
- Default gateway and DNS servers
- SSH service with key-based auth

**Template variables:**
- `hostname` - Router hostname
- `vyos_password`, `ansible_password` - User passwords
- `ssh_keys` - SSH public keys for ansible user
- `wan_ip`, `wan_gateway` - WAN interface configuration

Cloud-init runs once during first boot. Subsequent configuration is managed by Ansible.

## Common Tasks

**Backup Configuration:**
```bash
cd ansible-vyos
ansible-playbook playbooks/backup-config.yml
```

**Update Firewall Rules:**
```bash
vim ansible-vyos/group_vars/vyos.yml
ansible-playbook site.yml --tags firewall
```

**Add New Zone:**
1. Update `zone_interfaces` in terraform-vyos/terraform.tfvars
2. Run `terraform apply`
3. Update ansible-vyos/inventory/hosts.yml and group_vars/vyos.yml
4. Run `ansible-playbook site.yml`

**Destroy Infrastructure:**
```bash
cd terraform-vyos
terraform destroy
```

## Troubleshooting

```bash
# Verify Terraform changes
terraform plan

# Test Ansible connectivity
ansible vyos_routers -m ping

# VyOS CLI verification
ssh ansible@<router-ip>
show zone-policy
show firewall
show interfaces
```

---

## Building VyOS Cloud-Init Image

Build a custom VyOS rolling release image with cloud-init and QEMU guest agent support.

### Requirements

- Docker installed and running
- Git for cloning repositories
- 10GB free disk space
- Sudo/root privileges for privileged Docker mode

### Build Steps

**1. Clone VyOS build repository:**
```bash
git clone -b current --single-branch https://github.com/vyos/vyos-build
cd vyos-build
```

**2. Start build container:**
```bash
docker run --rm -it --privileged -v $(pwd):/vyos -w /vyos vyos/vyos-build:current bash
```

**3. Create build flavor configuration:**
```bash
cat > data/build-flavors/qcow2-cloudinit.toml << 'EOF'
image_format = "qcow2"
packages = ["cloud-init", "qemu-guest-agent"]

default_config = """
interfaces {
    loopback lo {
    }
}
system {
    config-management {
        commit-revisions "100"
    }
    console {
        device ttyS0 {
            speed "115200"
        }
    }
    host-name "vyos"
    login {
        user vyos {
            authentication {
                plaintext-password "vyos"
            }
        }
    }
}
"""

[[includes_chroot]]
path = "etc/cloud/cloud.cfg.d/90_dpkg.cfg"
data = "datasource_list: [NoCloud]"
EOF
```

**4. Build the image:**
```bash
sudo ./build-vyos-image qcow2-cloudinit
exit
```

Build takes 5-10 minutes. Image will be in `build/*.qcow2`.

### Upload to Proxmox

**1. Copy image:**
```bash
scp build/vyos-*.qcow2 user@proxmox:/var/lib/vz/template/qcow/
```

**2. Create VM template on Proxmox:**
```bash
qm create 9400 --name vyos-cloud-template --memory 1024 --net0 virtio,bridge=vmbr0
qm importdisk 9400 /var/lib/vz/template/qcow/vyos-*.qcow2 local-lvm
qm set 9400 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9400-disk-0
qm set 9400 --boot c --bootdisk scsi0
qm set 9400 --serial0 socket --vga serial0
qm set 9400 --agent enabled=1
qm template 9400
```

### Cloud-Init Configuration Example

```yaml
#cloud-config
vyos_config_commands:
  - set system host-name 'vyos-router'
  - set system time-zone 'UTC'
  - set system login user ansible authentication public-keys key-01 key 'AAAAB3NzaC...'
  - set system login user ansible authentication public-keys key-01 type 'ssh-rsa'
  - set interfaces ethernet eth0 address '192.168.1.1/24'
  - set interfaces ethernet eth0 description 'WAN'
  - set protocols static route 0.0.0.0/0 next-hop '192.168.1.254'
  - set service ssh port '22'
```

**Note:** VyOS cloud-init only supports `vyos_config_commands` and `write_files`. Standard cloud-init directives like `users:` are not supported.

### Common Build Issues

**Build fails with dependency errors:**
- Ensure using official `vyos/vyos-build:current` container

**Permission denied:**
- Run container with `--privileged` flag

**Cloud-init not working:**
- Verify cloud-init drive attached as IDE/CDROM
- Check syntax: values must be in single quotes
- Use `vyos_config_commands` instead of standard user creation

---

## Resources

- [VyOS Documentation](https://docs.vyos.io/)
- [VyOS Cloud-Init Guide](https://docs.vyos.io/en/latest/automation/cloud-init.html)
- [Zone-Based Firewall](https://docs.vyos.io/en/latest/configuration/firewall/zone.html)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/)
- [VyOS Ansible Collection](https://galaxy.ansible.com/vyos/vyos)
