#!/bin/bash

# Variables
SQUID_CONF="/etc/squid/squid.conf"
SQUID_PASSWD="/etc/squid/passwd"
BACKUP_CONF="/etc/squid/squid.conf.bak"
USERNAME="kcartik"
PASSWORD="kcartik"
PROXY_PORT="6969"

# Step 1: Update and Upgrade the System
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

# Step 2: Install Squid and Required Utilities
echo "Installing Squid and Apache utilities..."
apt install -y squid apache2-utils

# Step 3: Backup Original Squid Configuration
if [ -f "$SQUID_CONF" ]; then
    echo "Backing up the original Squid configuration..."
    cp $SQUID_CONF $BACKUP_CONF
    echo "Backup created at $BACKUP_CONF."
else
    echo "Squid configuration file not found. Exiting."
    exit 1
fi

# Step 4: Set Up User Authentication
echo "Setting up user authentication..."
if [ ! -f "$SQUID_PASSWD" ]; then
    touch $SQUID_PASSWD
fi

# Add user with the predefined password
htpasswd -b $SQUID_PASSWD $USERNAME $PASSWORD
echo "User '$USERNAME' with password '$PASSWORD' added successfully."

# Step 5: Create Hardened Squid Configuration
echo "Creating a new Squid configuration..."
cat <<EOF > $SQUID_CONF
# Listen on custom port
http_port $PROXY_PORT

# User Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Proxy
auth_param basic credentialsttl 2 hours
auth_param basic casesensitive on

acl authenticated proxy_auth REQUIRED
http_access allow authenticated

# Hide Client IP and Anonymize Headers
forwarded_for delete
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all
request_header_access Forwarded deny all
request_header_access Proxy-Connection deny all
request_header_access X-Cache deny all
request_header_access X-Cache-Lookup deny all
reply_header_access X-Cache deny all
reply_header_access X-Cache-Lookup deny all
reply_header_access Via deny all

# Add a Fake Header
request_header_add X-Forwarded-For "127.0.0.1" all

# Disable Logging (Optional for Privacy)
access_log none
cache_store_log none

# Block Proxy Probes
acl Safe_ports port 80 443
http_access deny !Safe_ports

# Deny All Other Access
http_access deny all
EOF

echo "New Squid configuration applied."

# Step 6: Restart Squid Service
echo "Restarting Squid service..."
systemctl restart squid

if systemctl is-active --quiet squid; then
    echo "Squid proxy setup complete and running."
    echo "Use the proxy at http://<your_server_ip>:$PROXY_PORT with username and password both as '$USERNAME'."
else
    echo "Failed to restart Squid. Check the configuration."
    exit 1
fi
