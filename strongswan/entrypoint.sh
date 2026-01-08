#!/bin/bash
set -e

echo "Starting L2TP/IPsec client exit node..."

# Load configuration from Docker secrets
if [ -f /run/secrets/vpn_server_ip ]; then
    VPN_SERVER_IP=$(cat /run/secrets/vpn_server_ip)
    export VPN_SERVER_IP
else
    echo "Error: VPN server IP secret not found"
    exit 1
fi

if [ -f /run/secrets/vpn_ipsec_psk ]; then
    VPN_IPSEC_PSK=$(cat /run/secrets/vpn_ipsec_psk)
    export VPN_IPSEC_PSK
else
    echo "Error: IPsec PSK secret not found"
    exit 1
fi

if [ -f /run/secrets/vpn_username ]; then
    VPN_USERNAME=$(cat /run/secrets/vpn_username)
    export VPN_USERNAME
else
    echo "Error: VPN username secret not found"
    exit 1
fi

if [ -f /run/secrets/vpn_password ]; then
    VPN_PASSWORD=$(cat /run/secrets/vpn_password)
    export VPN_PASSWORD
else
    echo "Error: VPN password secret not found"
    exit 1
fi

# Configure ipsec.conf with actual server IP
sed -i "s/VPN_SERVER_IP/$VPN_SERVER_IP/g" /etc/ipsec.conf

# Generate ipsec.secrets from template
sed -e "s/VPN_SERVER_IP/$VPN_SERVER_IP/g" \
    -e "s/VPN_IPSEC_PSK/$VPN_IPSEC_PSK/g" \
    /etc/ipsec.secrets.template > /etc/ipsec.secrets
chmod 600 /etc/ipsec.secrets

# Configure xl2tpd.conf with actual server IP
sed -i "s/VPN_SERVER_IP/$VPN_SERVER_IP/g" /etc/xl2tpd/xl2tpd.conf

# Configure PPP options with credentials
sed -i "s/VPN_USERNAME/$VPN_USERNAME/g" /etc/ppp/options.l2tpd.client
sed -i "s/VPN_PASSWORD/$VPN_PASSWORD/g" /etc/ppp/options.l2tpd.client

# Enable IP forwarding
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1

# Create control file directory
mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control

# Start IPsec
echo "Starting IPsec..."
ipsec start --nofork &
IPSEC_PID=$!

# Wait for IPsec to be ready
sleep 5

# Check IPsec status
echo "IPsec status:"
ipsec status

# Start xl2tpd
echo "Starting xl2tpd..."
xl2tpd -c /etc/xl2tpd/xl2tpd.conf -D &
XL2TPD_PID=$!

# Wait for xl2tpd to start
sleep 3

# Connect to VPN
echo "Connecting to L2TP/IPsec VPN..."
echo "c vpn-connection" > /var/run/xl2tpd/l2tp-control

# Wait for connection
sleep 5

# Check if ppp0 interface is up
if ip link show ppp0 &> /dev/null; then
    echo "L2TP/IPsec connection established!"
    echo "Interface ppp0 is up:"
    ip addr show ppp0
else
    echo "Warning: ppp0 interface not yet up, connection may still be establishing..."
fi

# Keep container running
wait
