#!/bin/bash
set -euo pipefail

# Upload cloud-init snippet to Proxmox
# Usage: ./upload-snippet.sh <cloud-init-file> <proxmox-host>

CLOUD_INIT_FILE="${1:-}"
PROXMOX_HOST="${2:-192.168.15.101}"
SNIPPETS_DIR="/var/lib/vz/snippets"
PROXMOX_USER="ansible"

if [[ -z "$CLOUD_INIT_FILE" ]] || [[ ! -f "$CLOUD_INIT_FILE" ]]; then
    echo "Usage: $0 <cloud-init-file> [proxmox-host]"
    echo "Example: $0 cloud-init-vyos01.yml 192.168.15.101"
    exit 1
fi

SNIPPET_NAME=$(basename "$CLOUD_INIT_FILE")

echo "Uploading $CLOUD_INIT_FILE to $PROXMOX_HOST..."

# Upload to /tmp first (writable by ansible user)
scp "$CLOUD_INIT_FILE" "$PROXMOX_USER@$PROXMOX_HOST:/tmp/$SNIPPET_NAME"

# Move to snippets directory with sudo
ssh "$PROXMOX_USER@$PROXMOX_HOST" "sudo mv /tmp/$SNIPPET_NAME $SNIPPETS_DIR/$SNIPPET_NAME && sudo chmod 644 $SNIPPETS_DIR/$SNIPPET_NAME"

echo "✓ Snippet uploaded: $SNIPPETS_DIR/$SNIPPET_NAME"
echo "✓ Use in Terraform: local:snippets/$SNIPPET_NAME"
