# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-08

### Added
- Initial release of WireGuard + L2TP/IPsec VPN chain
- WireGuard entry node with Alpine Linux base
- StrongSwan L2TP/IPsec exit node with Alpine Linux base
- Docker Compose orchestration with networking configuration
- Docker secrets support for secure credential management
- Automated setup script (`scripts/setup.sh`)
- WireGuard key generation script (`scripts/generate-keys.sh`)
- Configuration validation script (`scripts/validate.sh`)
- Comprehensive README with quick start guide
- Detailed architecture documentation (ARCHITECTURE.md)
- Example configurations for WireGuard and secrets
- Contributing guidelines (CONTRIBUTING.md)
- MIT License
- .gitignore for protecting secrets and keys
- Automatic routing and NAT configuration
- IPsec IKEv1 support with PSK authentication
- xl2tpd for L2TP tunnel management
- PPP support for link layer protocol

### Features
- Chains WireGuard traffic through L2TP/IPsec tunnel
- Fresh Alpine Linux images (no reuse of old images)
- Secure credential management via Docker secrets
- Automatic VPN connection establishment
- IP forwarding and routing between containers
- Port 51820/udp exposed for WireGuard clients
- Comprehensive logging and debugging support
- Helper scripts for easy deployment
- Example client configurations

### Documentation
- Quick start guide with step-by-step instructions
- Architecture diagrams and explanations
- Troubleshooting section
- Security considerations
- Performance tuning tips
- Management commands reference

[1.0.0]: https://github.com/SodaWithoutSparkles/l2tp-ipsec-wg/releases/tag/v1.0.0
