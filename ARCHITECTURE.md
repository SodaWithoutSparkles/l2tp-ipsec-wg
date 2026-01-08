# Architecture Documentation

## Overview

This document describes the architecture of the WireGuard + L2TP/IPsec VPN chain.

## High-Level Architecture

```
┌─────────┐         ┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│         │ WG      │                  │ Bridge  │                  │ Internet│                  │
│ Client  ├────────►│ WireGuard Entry  ├────────►│ L2TP/IPsec Exit  ├────────►│ External VPN     │
│         │ Tunnel  │ Node             │ Network │ Node             │ Tunnel  │ Server           │
└─────────┘         └──────────────────┘         └──────────────────┘         └──────────────────┘
                    Port: 51820/udp               ppp0 interface               Provider's server
                    Network: 10.13.13.0/24        Container network            
                    Container: wireguard-entry     Container: l2tp-ipsec-exit
```

## Component Details

### 1. WireGuard Entry Node

**Purpose**: Acts as the entry point for client connections

**Technology Stack**:
- Base Image: Alpine Linux 3.19
- VPN Software: WireGuard
- Network Tools: iptables, iproute2

**Configuration**:
- Listens on UDP port 51820
- Manages WireGuard tunnel interface (wg0)
- Assigns IP addresses from 10.13.13.0/24 subnet
- Handles encryption/decryption of client traffic

**Key Features**:
- Modern, fast VPN protocol
- Minimal attack surface
- Easy client configuration
- NAT traversal support

**Network Interfaces**:
- `wg0`: WireGuard tunnel interface (10.13.13.1/24)
- `eth0`: Bridge network connection to L2TP/IPsec node

### 2. L2TP/IPsec Exit Node

**Purpose**: Connects to external L2TP/IPsec VPN and routes all traffic through it

**Technology Stack**:
- Base Image: Alpine Linux 3.19
- IPsec Implementation: StrongSwan
- L2TP Daemon: xl2tpd
- PPP: Standard Linux PPP

**Configuration**:
- Establishes IPsec tunnel using IKEv1
- Creates L2TP connection over IPsec
- Manages PPP interface (ppp0)
- Uses Docker secrets for credentials

**Key Features**:
- Fresh Alpine build (no old images)
- Secure credential management
- Automatic reconnection
- Comprehensive logging

**Network Interfaces**:
- `eth0`: Bridge network connection to WireGuard node
- `ppp0`: L2TP/IPsec tunnel interface (assigned by VPN server)

## Traffic Flow

### Detailed Traffic Path

1. **Client → WireGuard Entry Node**
   - Client initiates WireGuard connection to public IP:51820
   - WireGuard handshake establishes encrypted tunnel
   - Client assigned IP from 10.13.13.0/24 range
   - Traffic encrypted with WireGuard protocol

2. **WireGuard Entry Node → L2TP/IPsec Exit Node**
   - WireGuard decrypts incoming traffic
   - iptables FORWARD rules pass traffic to L2TP/IPsec container
   - Traffic routed via Docker bridge network (172.20.0.0/16)
   - No encryption at this stage (trusted internal network)

3. **L2TP/IPsec Exit Node → External VPN Server**
   - Traffic received on eth0 interface
   - IPsec encrypts packets using ESP protocol
   - L2TP encapsulates traffic within IPsec tunnel
   - PPP manages link layer protocol
   - Traffic exits via ppp0 interface
   - NAT performed at external VPN server

4. **Return Traffic**
   - Follows reverse path
   - External VPN → L2TP/IPsec → WireGuard → Client
   - Each layer handles decryption/encryption

### Packet Structure

**Outbound from Client**:
```
[IP Header | WireGuard Header | Encrypted Payload]
                ↓
[IP Header | L2TP | PPP | Original Packet] (over IPsec)
                ↓
[IP Header | IPsec ESP | Encrypted [L2TP | PPP | Original Packet]]
```

**Inbound to Client**:
```
[IP Header | IPsec ESP | Encrypted [L2TP | PPP | Response]]
                ↓
[IP Header | L2TP | PPP | Response] (decrypted)
                ↓
[IP Header | WireGuard Header | Encrypted Response]
```

## Network Configuration

### Subnets and Addressing

| Network           | Subnet          | Purpose                    |
|-------------------|-----------------|----------------------------|
| WireGuard VPN     | 10.13.13.0/24   | Client tunnel addresses    |
| Docker Bridge     | 172.20.0.0/16   | Inter-container network    |
| PPP Link          | DHCP assigned   | L2TP/IPsec tunnel          |

### Port Mappings

| Port      | Protocol | Service        | Exposure     |
|-----------|----------|----------------|--------------|
| 51820     | UDP      | WireGuard      | Host → Internet |
| 1701      | UDP      | L2TP           | Container → VPN Server |
| 500       | UDP      | IPsec IKE      | Container → VPN Server |
| 4500      | UDP      | IPsec NAT-T    | Container → VPN Server |

### Routing Tables

**WireGuard Container**:
```
10.13.13.0/24 dev wg0
172.20.0.0/16 dev eth0
default via 172.20.0.1 dev eth0
```

**L2TP/IPsec Container**:
```
172.20.0.0/16 dev eth0
default via ppp0
```

## Security Architecture

### Encryption Layers

1. **WireGuard Layer**:
   - Protocol: WireGuard
   - Cipher: ChaCha20-Poly1305 or AES-GCM
   - Key Exchange: Noise Protocol Framework
   - Authentication: Public key cryptography

2. **IPsec Layer**:
   - Protocol: ESP (Encapsulating Security Payload)
   - IKE: IKEv1 (configurable)
   - Cipher: AES-256-SHA1, AES-128-SHA1, 3DES-SHA1
   - Authentication: Pre-shared key (PSK)

### Credential Management

**Docker Secrets**:
- Stored in `/run/secrets/` within containers
- Read-only mount
- Not visible in Docker inspect
- Separate files for each credential:
  - `vpn_server_ip`: VPN server address
  - `vpn_ipsec_psk`: IPsec pre-shared key
  - `vpn_username`: L2TP username
  - `vpn_password`: L2TP password

**Key Management**:
- WireGuard keys: Stored in `config/wg0.conf` (gitignored)
- Secrets: Stored in `secrets/*.txt` (gitignored)
- Example files provided with `.example` extension

### Attack Surface Reduction

1. **Minimal base images**: Alpine Linux (small attack surface)
2. **No unnecessary services**: Only required daemons running
3. **Principle of least privilege**: Containers run with minimal capabilities
4. **Secret isolation**: Credentials not in environment variables or configs
5. **Network isolation**: Docker bridge network isolates container traffic

## Container Dependencies

### Startup Order

```
1. Docker Network Creation
   ↓
2. L2TP/IPsec Exit Node
   - Load secrets
   - Start IPsec
   - Start xl2tpd
   - Establish VPN connection
   - Wait for ppp0 interface
   ↓
3. WireGuard Entry Node
   - Load configuration
   - Start WireGuard
   - Configure routing
   - Set up iptables
```

### Inter-Container Communication

- **Network**: Docker bridge network (`vpn-network`)
- **DNS**: Docker's internal DNS resolver
- **Dependencies**: WireGuard depends on L2TP/IPsec being healthy

## Scalability Considerations

### Horizontal Scaling

**WireGuard Entry Nodes**:
- Multiple WireGuard containers can be deployed
- Use load balancer (HAProxy, NGINX) in front
- Share same L2TP/IPsec exit node or use multiple

**L2TP/IPsec Exit Nodes**:
- Deploy multiple for different VPN providers
- Configure separate Docker Compose services
- Use different secret sets for each

### Vertical Scaling

**Resource Requirements**:
- WireGuard: Minimal CPU, ~100MB RAM per instance
- L2TP/IPsec: Moderate CPU for encryption, ~200MB RAM
- Recommended: 1 CPU core + 512MB RAM total

## Monitoring and Logging

### Log Locations

**WireGuard**:
- Startup logs: Docker logs (`docker-compose logs wireguard`)
- Connection info: `wg show` command
- Kernel logs: `dmesg | grep wireguard`

**L2TP/IPsec**:
- IPsec logs: `/var/log/` in container
- xl2tpd logs: Docker logs (`docker-compose logs l2tp-ipsec`)
- PPP logs: `/var/log/` in container

### Health Checks

**Automated Checks**:
```bash
# WireGuard running
docker exec wireguard-entry wg show

# IPsec connection
docker exec l2tp-ipsec-exit ipsec status

# PPP interface
docker exec l2tp-ipsec-exit ip addr show ppp0
```

## Disaster Recovery

### Backup Requirements

**Critical Files**:
- `config/wg0.conf`: WireGuard configuration
- `config/*_private.key`: Private keys
- `secrets/*.txt`: VPN credentials

**Backup Strategy**:
```bash
# Create backup
tar -czf backup-$(date +%Y%m%d).tar.gz config/ secrets/

# Restore
tar -xzf backup-YYYYMMDD.tar.gz
```

### Recovery Procedures

1. **Container failure**:
   - `docker-compose restart [service]`
   - Check logs for errors
   - Verify credentials and configuration

2. **Network failure**:
   - Check host networking
   - Verify firewall rules
   - Test connectivity to VPN server

3. **Complete rebuild**:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

## Future Enhancements

### Potential Improvements

1. **IPv6 Support**: Add IPv6 addressing and routing
2. **Multi-Protocol**: Support multiple VPN protocols at exit
3. **Load Balancing**: Distribute across multiple exit nodes
4. **Monitoring Dashboard**: Web UI for status and metrics
5. **Automatic Failover**: Switch exit nodes on failure
6. **QoS**: Traffic shaping and prioritization
7. **Split Tunneling**: Route only specific traffic through VPN

## References

- [WireGuard Protocol](https://www.wireguard.com/)
- [StrongSwan Documentation](https://docs.strongswan.org/)
- [xl2tpd Project](https://github.com/xelerance/xl2tpd)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Alpine Linux](https://alpinelinux.org/)
