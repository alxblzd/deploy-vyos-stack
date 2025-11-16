# VyOS Ansible Configuration

Ansible automation for VyOS.

## Features

- VLAN-based network zones (DMZ, Trusted, Guest, IoT)
- Zone-based firewall (North-South and East-West rules)
- Source NAT for internal networks
- DHCP and DNS services per zone

## Prerequisites

- VyOS router with SSH access

## Quick Start

```bash
# Install dependencies
ansible-galaxy collection install -r requirements.yml
pip3 install -r requirements.txt

# Configure inventory
# Edit inventory/hosts.yml with your router details

# Deploy configuration
ansible-playbook site.yml

# Deploy specific components
ansible-playbook site.yml --tags network
ansible-playbook site.yml --tags firewall
```

## Configuration

Edit [group_vars/vyos.yml](group_vars/vyos.yml) to customize:

- Network zones and VLANs
- Firewall rules (North-South and East-West)
- NAT configuration
- DHCP and DNS settings

## Verification

```bash
# Test connectivity
ansible vyos_routers -m ping

# Verify on VyOS
ssh ansible@<router-ip>
show zone-policy
show firewall
show nat source rules
```

## Troubleshooting

**Collection not found**: Run `ansible-galaxy collection install -r requirements.yml`

**SSH authentication fails**: Verify SSH keys are configured and test with `ssh ansible@<router-ip>`

**Host key verification failed**: Add host key with `ssh-keyscan -H <router-ip> >> ~/.ssh/known_hosts`

**Changes not persisting**: Ensure `save: true` is set in playbooks (default)

**Verbose output**: Add `-vvv` to any ansible-playbook command

## References

- [VyOS Documentation](https://docs.vyos.io/)
- [VyOS Ansible Collection](https://galaxy.ansible.com/vyos/vyos)
