# WireGuard + L2TP/IPsec VPN Chain

A Docker-based VPN chain that combines WireGuard as an entry node with L2TP/IPsec as an exit node, allowing you to tunnel WireGuard traffic through an L2TP/IPsec VPN connection.

## Architecture

```
[Client] <--WireGuard--> [WireGuard Server] <--Internal Network--> [L2TP/IPsec Client] <--Internet--> [L2TP/IPsec Server]
```

- **Entry Node**: WireGuard server (Alpine Linux) - accepts connections from WireGuard clients
- **Exit Node**: StrongSwan L2TP/IPsec client (Alpine Linux) - connects to an external L2TP/IPsec VPN server
- **Traffic Flow**: All traffic from WireGuard clients is routed through the L2TP/IPsec VPN connection

## Features

- ✅ Fresh Alpine Linux-based Docker images (no reuse of old images)
- ✅ StrongSwan for IPsec + xl2tpd for L2TP
- ✅ WireGuard server with modern kernel support
- ✅ Docker secrets for secure credential management
- ✅ Automatic VPN chaining with proper routing
- ✅ Easy setup with helper scripts
- ✅ Comprehensive logging and monitoring

## Prerequisites

Before you begin, ensure you have the following installed:

- Docker (version 20.10 or later)
- Docker Compose (version 1.29 or later)
- WireGuard tools (for key generation): `apt install wireguard-tools` or `brew install wireguard-tools`
- Root/sudo access on the host machine

### System Requirements

- Linux kernel with WireGuard support (kernel 5.6+ or module loaded)
- `/dev/ppp` device available
- Kernel modules: `ppp_generic`, `ppp_async`, `ppp_deflate`

Load required kernel modules:
```bash
sudo modprobe ppp_generic
sudo modprobe ppp_async
sudo modprobe ppp_deflate
```

## Quick Start Guide

### Step 1: Clone the Repository

```bash
git clone https://github.com/SodaWithoutSparkles/l2tp-ipsec-wg.git
cd l2tp-ipsec-wg
```

### Step 2: Set Up L2TP/IPsec Credentials (Docker Secrets)

Create the actual secret files from the examples:

```bash
cp secrets/vpn_server_ip.txt.example secrets/vpn_server_ip.txt
cp secrets/vpn_ipsec_psk.txt.example secrets/vpn_ipsec_psk.txt
cp secrets/vpn_username.txt.example secrets/vpn_username.txt
cp secrets/vpn_password.txt.example secrets/vpn_password.txt
```

Edit each file with your actual L2TP/IPsec VPN credentials:

```bash
# Edit with your VPN server IP or hostname
nano secrets/vpn_server_ip.txt

# Edit with your IPsec pre-shared key
nano secrets/vpn_ipsec_psk.txt

# Edit with your VPN username
nano secrets/vpn_username.txt

# Edit with your VPN password
nano secrets/vpn_password.txt
```

Secure the secret files:
```bash
chmod 600 secrets/*.txt
```

### Step 3: Generate WireGuard Keys

Use the provided helper script to generate server and client keys:

```bash
./scripts/generate-keys.sh
```

This will:
1. Generate server private and public keys
2. Optionally generate client keys
3. Provide example configurations

**Important**: Keep your private keys secure and never commit them to version control!

### Step 4: Configure WireGuard Server

Copy the example configuration:

```bash
cp config/wg0.conf.example config/wg0.conf
```

Edit `config/wg0.conf` and replace `YOUR_SERVER_PRIVATE_KEY` with the content from `config/server_private.key`:

```bash
nano config/wg0.conf
```

Add peer configurations for each client. Example:

```ini
[Interface]
PrivateKey = <content-from-server_private.key>
Address = 10.13.13.1/24
ListenPort = 51820

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Client 1
PublicKey = <client-public-key>
AllowedIPs = 10.13.13.2/32

[Peer]
# Client 2
PublicKey = <another-client-public-key>
AllowedIPs = 10.13.13.3/32
```

### Step 5: Start the VPN Chain

You can use the automated setup script:

```bash
./scripts/setup.sh
```

Or manually:

```bash
docker compose build
docker compose up -d
```

### Step 6: Verify the Setup

Check that both containers are running:

```bash
docker compose ps
```

View logs:

```bash
# View all logs
docker compose logs -f

# View only L2TP/IPsec logs
docker compose logs -f l2tp-ipsec

# View only WireGuard logs
docker compose logs -f wireguard
```

Check L2TP/IPsec connection:

```bash
docker exec l2tp-ipsec-exit ip addr show ppp0
docker exec l2tp-ipsec-exit ipsec status
```

Check WireGuard status:

```bash
docker exec wireguard-entry wg show
```

### Step 7: Configure WireGuard Clients

Create a client configuration file (e.g., `client.conf`):

```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.13.13.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = <server-public-key>
Endpoint = YOUR_SERVER_PUBLIC_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

Replace:
- `<client-private-key>`: Content from the client's private key file
- `<server-public-key>`: Content from `config/server_public.key`
- `YOUR_SERVER_PUBLIC_IP`: Your server's public IP address

Import this configuration into your WireGuard client application.

## Management Commands

### Start the VPN chain
```bash
docker compose up -d
```

### Stop the VPN chain
```bash
docker compose down
```

### Restart the VPN chain
```bash
docker compose restart
```

### View logs in real-time
```bash
docker compose logs -f
```

### Rebuild images after configuration changes
```bash
docker compose build --no-cache
docker compose up -d
```

### Check connection status
```bash
# L2TP/IPsec status
docker exec l2tp-ipsec-exit ipsec status
docker exec l2tp-ipsec-exit ip addr show ppp0

# WireGuard status
docker exec wireguard-entry wg show
```

## Architecture Details

### Directory Structure

```
l2tp-ipsec-wg/
├── docker compose.yml          # Main orchestration file
├── .gitignore                  # Prevents committing secrets
├── README.md                   # This file
│
├── wireguard/                  # WireGuard entry node
│   ├── Dockerfile              # Alpine-based WireGuard image
│   └── entrypoint.sh           # Startup script
│
├── strongswan/                 # L2TP/IPsec exit node
│   ├── Dockerfile              # Alpine-based StrongSwan image
│   ├── entrypoint.sh           # Startup script
│   ├── ipsec.conf              # IPsec configuration
│   ├── ipsec.secrets.template  # IPsec secrets template
│   ├── xl2tpd.conf             # L2TP daemon configuration
│   └── options.l2tpd.client    # PPP options
│
├── config/                     # WireGuard configurations
│   └── wg0.conf.example        # Example WireGuard config
│
├── secrets/                    # Docker secrets (gitignored)
│   ├── README.md               # Secrets documentation
│   ├── *.txt.example           # Example secret files
│   └── *.txt                   # Actual secrets (not in git)
│
└── scripts/                    # Helper scripts
    ├── setup.sh                # Automated setup
    └── generate-keys.sh        # Key generation utility
```

### Networking

- **Bridge Network**: `vpn-network` (172.20.0.0/16)
- **WireGuard Network**: 10.13.13.0/24
  - Server: 10.13.13.1
  - Clients: 10.13.13.2+
- **Port**: 51820/udp (WireGuard, exposed to host)

### Traffic Flow

1. Client connects to WireGuard server on port 51820
2. WireGuard server receives encrypted traffic
3. Traffic is decrypted and forwarded to the internal network
4. L2TP/IPsec container establishes connection to external VPN server
5. Traffic from WireGuard is routed through L2TP/IPsec tunnel (ppp0)
6. Response traffic follows the same path in reverse

## Security Considerations

### Docker Secrets

This setup uses Docker secrets to securely manage sensitive credentials:

- Secrets are mounted as read-only files in `/run/secrets/`
- Secret files are excluded from Git via `.gitignore`
- Never commit actual credentials to version control

### Key Management

- Keep private keys secure and backed up
- Use strong, randomly generated keys
- Rotate keys periodically
- Use unique keys for each client

### Firewall Configuration

Ensure your firewall allows:
- Incoming UDP on port 51820 (WireGuard)
- Outgoing UDP on port 1701 (L2TP)
- Outgoing UDP on port 500/4500 (IPsec)

Example `ufw` rules:
```bash
sudo ufw allow 51820/udp
sudo ufw enable
```

## Troubleshooting

### Container Won't Start

**Issue**: L2TP/IPsec container fails to start

**Solution**: Check that required kernel modules are loaded:
```bash
sudo modprobe ppp_generic
sudo modprobe ppp_async
sudo modprobe ppp_deflate
lsmod | grep ppp
```

**Issue**: `/dev/ppp` not found

**Solution**: Create the device if missing:
```bash
sudo mknod /dev/ppp c 108 0
sudo chmod 600 /dev/ppp
```

### Connection Issues

**Issue**: L2TP/IPsec won't connect

**Solutions**:
1. Verify secrets are correct:
   ```bash
   docker exec l2tp-ipsec-exit cat /run/secrets/vpn_server_ip
   ```
2. Check IPsec logs:
   ```bash
   docker compose logs l2tp-ipsec
   ```
3. Test connectivity to VPN server:
   ```bash
   docker exec l2tp-ipsec-exit ping -c 3 $(cat secrets/vpn_server_ip.txt)
   ```

**Issue**: WireGuard clients can't connect

**Solutions**:
1. Check WireGuard configuration:
   ```bash
   docker exec wireguard-entry wg show
   ```
2. Verify firewall allows port 51820/udp
3. Confirm server public IP is correct in client config
4. Check peer public keys match

**Issue**: No internet through VPN

**Solutions**:
1. Verify ppp0 interface is up:
   ```bash
   docker exec l2tp-ipsec-exit ip addr show ppp0
   ```
2. Check routing from WireGuard:
   ```bash
   docker exec wireguard-entry ip route
   ```
3. Test from WireGuard container:
   ```bash
   docker exec wireguard-entry ping -c 3 8.8.8.8
   ```

### Permission Issues

**Issue**: Permission denied when starting

**Solution**: Ensure scripts are executable:
```bash
chmod +x scripts/*.sh
chmod +x wireguard/entrypoint.sh
chmod +x strongswan/entrypoint.sh
```

### Logs and Debugging

Enable verbose logging:

For L2TP/IPsec:
```bash
# Edit strongswan/ipsec.conf and increase charondebug levels
# Rebuild: docker compose build l2tp-ipsec
```

For WireGuard:
```bash
# WireGuard is already verbose in the entrypoint script
docker compose logs -f wireguard
```

### IPsec Compatibility Issues

**Issue**: IPsec connection fails with "no proposal chosen"

**Solution**: The default configuration uses modern, secure algorithms (AES-256-SHA256, modp2048). If your VPN provider requires legacy algorithms, edit `strongswan/ipsec.conf`:

```bash
# Uncomment the legacy algorithm lines in the conn %default section:
# ike=aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!
# esp=aes256-sha1,aes128-sha1,3des-sha1!

# Then rebuild:
docker compose build l2tp-ipsec
docker compose up -d
```

**Note**: Legacy algorithms (3DES, SHA1, modp1024) are less secure. Only use them if required by your VPN provider.

## Performance Tuning

### MTU Configuration

Adjust MTU to prevent fragmentation:

In `config/wg0.conf`:
```ini
[Interface]
MTU = 1280
```

In `strongswan/options.l2tpd.client`:
```
mtu 1280
mru 1280
```

### Resource Limits

Add resource limits in `docker compose.yml`:
```yaml
services:
  wireguard:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
```

## Advanced Configuration

### Multiple L2TP/IPsec Servers

To support multiple exit servers, create separate secret sets and modify `docker compose.yml` to run multiple L2TP/IPsec containers.

### Custom Routing

Modify `wireguard/entrypoint.sh` to add custom routing rules for specific traffic patterns.

### Monitoring

Add monitoring tools like Prometheus exporters:
```yaml
services:
  wireguard-exporter:
    image: mindflavor/prometheus-wireguard-exporter
    # ... configuration
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is provided as-is for educational and practical use.

## Acknowledgments

- WireGuard: https://www.wireguard.com/
- StrongSwan: https://www.strongswan.org/
- xl2tpd: https://github.com/xelerance/xl2tpd

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review troubleshooting section above

---

**Note**: This setup requires a working L2TP/IPsec VPN server. Ensure you have valid credentials before starting.
