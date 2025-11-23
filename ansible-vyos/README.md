# VyOS Ansible Configuration

Ansible automation for VyOS 1.5+ with zone-based firewall.

## Quick Start

```bash
# Install dependencies
ansible-galaxy collection install -r requirements.yml
pip3 install -r requirements.txt

# Deploy full configuration
ansible-playbook -i inventory/hosts.yml vyos.yaml

# Deploy specific components
ansible-playbook -i inventory/hosts.yml vyos.yaml --tags network
ansible-playbook -i inventory/hosts.yml vyos.yaml --tags firewall
ansible-playbook -i inventory/hosts.yml vyos.yaml --tags nat

# Or use make commands
make firewall
make network
```

## Configuration

Edit `group_vars/vyos_routers.yml` to customize:
- Network zones and VLANs
- Firewall rules (North-South, East-West, LOCAL)
- NAT rules
- DNS settings

Edit `inventory/hosts.yml` for router connection details.

## Zones

- **WAN** (eth0) - Internet
- **MGMT** (vlan 10) - Management network
- **DMZCLOUD** (vlan 11) - DMZ Cloud services
- **DMZWEB** (vlan 12) - DMZ Web services
- **VPN** (vlan 20) - VPN network
- **LOCAL** - Router itself

## Verification

```bash
# Check connectivity
ansible vyos_routers -m ping

# On VyOS router
show firewall zone
show firewall ipv4
show nat source rules
```

## Documentation

See `docs/vyos-zone-firewall-guide.md` for detailed VyOS 1.5 zone-based firewall documentation.
