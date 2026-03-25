#!/bin/bash

# Configuration
USER_NAME="devops"
GROUP_NAME="devops"
USER_PASS="today@1234"
BACKUP_DIR="/home/backup"
TIMESTAMP=$(date +%d%b%Y-%H%M)

# 1. OS Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID # e.g., ubuntu, centos, amzn, sles
else
    echo "Error: Cannot detect OS. /etc/os-release missing."
    exit 1
fi

echo "Running setup for OS: $OS_NAME"

# 2. User & Group Setup
setup_user() {
    # Create group if it doesn't exist
    if ! getent group "$GROUP_NAME" >/dev/null; then
        groupadd "$GROUP_NAME"
    fi

    # Create user if it doesn't exist
    if ! id -u "$USER_NAME" >/dev/null 2>&1; then
        echo "Creating user: $USER_NAME"
        useradd -m -d "/home/$USER_NAME" -s /bin/bash -g "$GROUP_NAME" "$USER_NAME"
    else
        echo "User $USER_NAME already exists. Updating password only."
    fi

    # Set password securely without 'expect'
    echo "$USER_NAME:$USER_PASS" | chpasswd
    echo "Password updated for $USER_NAME."
}

# 3. Permissions (Sudoers)
update_sudoers() {
    mkdir -p "$BACKUP_DIR"
    [ -f /etc/sudoers ] && cp -p /etc/sudoers "$BACKUP_DIR/sudoers-$TIMESTAMP"

    # Best practice: use a drop-in file in sudoers.d
    echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER_NAME"
    chmod 440 "/etc/sudoers.d/$USER_NAME"
    echo "Sudoers permissions granted."
}

# 4. SSH Configuration
update_ssh() {
    SSHD_CONFIG="/etc/ssh/sshd_config"
    mkdir -p "$BACKUP_DIR"
    cp -p "$SSHD_CONFIG" "$BACKUP_DIR/sshd_config-$TIMESTAMP"

    # Update SSH settings
    sed -i '/^PasswordAuthentication/d' "$SSHD_CONFIG"
    sed -i '/^ClientAliveInterval/d' "$SSHD_CONFIG"
    echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
    echo "ClientAliveInterval 240" >> "$SSHD_CONFIG"

    # Fix for Cloud-Init overrides
    CLOUD_SSH="/etc/ssh/sshd_config.d/60-cloudimg-settings.conf"
    if [ -f "$CLOUD_SSH" ]; then
        sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' "$CLOUD_SSH"
    fi

    # Smarter Restart: Tries 'ssh' (Ubuntu/Debian) then 'sshd' (RHEL/CentOS/SLES)
    echo "Restarting SSH service..."
    if systemctl list-unit-files | grep -q "^ssh.service"; then
        systemctl restart ssh
    elif systemctl list-unit-files | grep -q "^sshd.service"; then
        systemctl restart sshd
    else
        service ssh restart || service sshd restart
    fi
    
    echo "SSH configuration updated and service restarted successfully."
}


# --- Execution ---
case "$OS_NAME" in
    ubuntu|debian|centos|rhel|amzn|sles)
        setup_user
        update_sudoers
        update_ssh
        echo "Setup complete!"
        ;;
    *)
        echo "Unsupported OS: $OS_NAME"
        exit 1
        ;;
esac