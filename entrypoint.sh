#!/bin/bash
set -e

# Configuration from environment variables
USERNAME="${USERNAME:-msn0624c}"
USER_UID="${USER_UID:-1026}"
USER_GID="${USER_GID:-100}"
ADMIN_GID="${ADMIN_GID:-101}"
DOCKER_GID="${DOCKER_GID:-999}"

echo "=== DevShell Entrypoint ==="
echo "Configuring user: $USERNAME (UID: $USER_UID, GID: $USER_GID)"
echo "Docker socket GID: $DOCKER_GID"

# Create required groups if they don't exist
groupadd -g "$USER_GID" users 2>/dev/null || echo "Group users ($USER_GID) already exists"
groupadd -g "$ADMIN_GID" administrators 2>/dev/null || echo "Group administrators ($ADMIN_GID) already exists"

# Create or update docker group to match host Docker socket GID
if getent group docker > /dev/null 2>&1; then
    CURRENT_DOCKER_GID=$(getent group docker | cut -d: -f3)
    if [ "$CURRENT_DOCKER_GID" != "$DOCKER_GID" ]; then
        echo "Updating docker group GID from $CURRENT_DOCKER_GID to $DOCKER_GID"
        groupmod -g "$DOCKER_GID" docker
    fi
else
    echo "Creating docker group with GID $DOCKER_GID"
    groupadd -g "$DOCKER_GID" docker
fi

# Create user if it doesn't exist
if ! id -u "$USERNAME" > /dev/null 2>&1; then
    echo "Creating user $USERNAME"
    useradd -m -u "$USER_UID" -g "$USER_GID" -s /bin/bash "$USERNAME"
else
    echo "User $USERNAME already exists"
    # Ensure correct UID/GID
    usermod -u "$USER_UID" -g "$USER_GID" "$USERNAME" 2>/dev/null || true
fi

# Add user to supplementary groups
usermod -aG administrators "$USERNAME" 2>/dev/null || true
usermod -aG docker "$USERNAME" 2>/dev/null || true
usermod -aG sudo "$USERNAME" 2>/dev/null || true

# Configure passwordless sudo
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$USERNAME"
chmod 0440 /etc/sudoers.d/"$USERNAME"

# Ensure .ssh directory exists with correct permissions
SSH_DIR="/home/$USERNAME/.ssh"
if [ -d "$SSH_DIR" ]; then
    echo "Fixing .ssh directory permissions"
    chown -R "$USERNAME:$USER_GID" "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # Fix authorized_keys permissions if it exists
    if [ -f "$SSH_DIR/authorized_keys" ]; then
        chmod 600 "$SSH_DIR/authorized_keys"
        chown "$USERNAME:$USER_GID" "$SSH_DIR/authorized_keys"
        echo "SSH authorized_keys configured"
    else
        echo "WARNING: No authorized_keys file found in $SSH_DIR"
    fi
else
    echo "WARNING: .ssh directory not mounted at $SSH_DIR"
fi

# Ensure home directory ownership
chown "$USERNAME:$USER_GID" "/home/$USERNAME"

# Display configuration summary
echo "=== Configuration Summary ==="
echo "User: $(id "$USERNAME")"
echo "Groups: $(groups "$USERNAME")"
echo "Docker socket: $(ls -la /var/run/docker.sock 2>/dev/null || echo 'Not mounted')"
if [ -f "$SSH_DIR/authorized_keys" ]; then
    echo "SSH keys: $(wc -l < "$SSH_DIR/authorized_keys") key(s) configured"
fi
echo "==========================="

# Execute CMD (sshd)
exec "$@"
