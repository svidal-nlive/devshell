#!/bin/bash
# DevShell Deployment Script for Synology NAS
# This script sets up the devshell stack on your NAS

set -e

echo "=== DevShell NAS Deployment Setup ==="

# Get Docker socket GID
DOCKER_GID=$(stat -c %g /var/run/docker.sock 2>/dev/null || echo "999")
echo "Detected Docker socket GID: $DOCKER_GID"

# Check if we're on the NAS
if [ ! -d "/volume1/docker" ]; then
    echo "ERROR: This script must be run on the Synology NAS"
    echo "Expected /volume1/docker directory not found"
    exit 1
fi

# Create stack directory
STACK_DIR="/volume1/docker/stacks/devshell"
echo "Creating stack directory: $STACK_DIR"
mkdir -p "$STACK_DIR/ssh"

# Prompt for GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME
if [ -z "$GITHUB_USERNAME" ]; then
    echo "ERROR: GitHub username is required"
    exit 1
fi

# Create .env file
echo "Creating .env file..."
cat > "$STACK_DIR/.env" <<EOF
# DevShell Configuration
USERNAME=msn0624c
USER_UID=1026
USER_GID=100
ADMIN_GID=101
DOCKER_GID=$DOCKER_GID
GITHUB_USERNAME=$GITHUB_USERNAME
EOF

# Copy docker-compose.yml
echo "Copying docker-compose.yml..."
cp docker-compose.yml "$STACK_DIR/"

# Check for SSH keys
if [ ! -f "$STACK_DIR/ssh/authorized_keys" ]; then
    echo ""
    echo "WARNING: No SSH authorized_keys file found!"
    echo "You need to add your SSH public key to: $STACK_DIR/ssh/authorized_keys"
    echo ""
    echo "Example:"
    echo "  cat ~/.ssh/id_ed25519.pub >> $STACK_DIR/ssh/authorized_keys"
    echo "  chmod 600 $STACK_DIR/ssh/authorized_keys"
    echo ""
    read -p "Press Enter to continue..."
fi

# Change to stack directory
cd "$STACK_DIR"

echo ""
echo "=== Setup Complete ==="
echo "Stack directory: $STACK_DIR"
echo ""
echo "Next steps:"
echo "  1. Add your SSH public key to: $STACK_DIR/ssh/authorized_keys"
echo "  2. Run: cd $STACK_DIR"
echo "  3. Pull image: /usr/local/bin/docker compose pull"
echo "  4. Start container: /usr/local/bin/docker compose up -d"
echo "  5. Check logs: /usr/local/bin/docker compose logs -f"
echo ""
echo "Access via:"
echo "  External: ssh msn0624c@devshell.nsystems.live"
echo "  LAN: ssh -p 2222 msn0624c@192.168.0.164"
echo ""
