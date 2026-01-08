#!/bin/bash

echo "==================================="
echo "Generating WireGuard Keys"
echo "==================================="
echo ""

# Create config directory if it doesn't exist
mkdir -p config

# Generate server keys
echo "Generating server keys..."
wg genkey | tee config/server_private.key | wg pubkey > config/server_public.key
chmod 600 config/server_private.key

echo "✓ Server keys generated:"
echo "  Private key: config/server_private.key"
echo "  Public key: config/server_public.key"
echo ""

# Generate client keys
read -p "Do you want to generate client keys? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter client name: " CLIENT_NAME
    
    echo "Generating keys for client: $CLIENT_NAME"
    wg genkey | tee "config/${CLIENT_NAME}_private.key" | wg pubkey > "config/${CLIENT_NAME}_public.key"
    chmod 600 "config/${CLIENT_NAME}_private.key"
    
    echo ""
    echo "✓ Client keys generated:"
    echo "  Private key: config/${CLIENT_NAME}_private.key"
    echo "  Public key: config/${CLIENT_NAME}_public.key"
    echo ""
    echo "==================================="
    echo "Client Configuration"
    echo "==================================="
    echo ""
    echo "Add this [Peer] section to your config/wg0.conf:"
    echo ""
    echo "[Peer]"
    echo "PublicKey = $(cat config/${CLIENT_NAME}_public.key)"
    echo "AllowedIPs = 10.13.13.2/32"
    echo ""
    echo "Client config file (save as ${CLIENT_NAME}.conf on client device):"
    echo ""
    echo "[Interface]"
    echo "PrivateKey = $(cat config/${CLIENT_NAME}_private.key)"
    echo "Address = 10.13.13.2/24"
    echo "DNS = 8.8.8.8"
    echo ""
    echo "[Peer]"
    echo "PublicKey = $(cat config/server_public.key)"
    echo "Endpoint = YOUR_SERVER_IP:51820"
    echo "AllowedIPs = 0.0.0.0/0"
    echo "PersistentKeepalive = 25"
    echo ""
fi

echo ""
echo "Done! Remember to:"
echo "1. Update YOUR_SERVER_PRIVATE_KEY in config/wg0.conf with the server private key"
echo "2. Add peer sections to config/wg0.conf for each client"
echo "3. Replace YOUR_SERVER_IP with your actual server IP in client configs"
