# Contributing to WireGuard + L2TP/IPsec VPN Chain

Thank you for your interest in contributing to this project! This document provides guidelines and information for contributors.

## Code of Conduct

Please be respectful and constructive in all interactions. We're building a tool to help people secure their network traffic, and we welcome contributions from everyone.

## How to Contribute

### Reporting Issues

If you encounter a bug or have a feature request:

1. Check if the issue already exists in the GitHub Issues
2. If not, create a new issue with:
   - A clear, descriptive title
   - Detailed description of the problem or feature
   - Steps to reproduce (for bugs)
   - Your environment details (OS, Docker version, etc.)
   - Relevant logs or screenshots

### Submitting Changes

1. **Fork the repository**
   ```bash
   git clone https://github.com/SodaWithoutSparkles/l2tp-ipsec-wg.git
   cd l2tp-ipsec-wg
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Keep changes focused and minimal
   - Update documentation if needed
   - Test your changes thoroughly

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: Brief description of your changes"
   ```

   Use these commit prefixes:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Update:` for updates to existing features
   - `Docs:` for documentation changes
   - `Refactor:` for code refactoring

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your branch
   - Provide a clear description of changes
   - Link any related issues

## Development Guidelines

### Docker Images

- Use Alpine Linux as the base image
- Keep images minimal and secure
- Document all installed packages
- Use multi-stage builds when appropriate

### Scripts

- Use bash for shell scripts
- Include error handling (`set -e`)
- Add comments for complex logic
- Make scripts executable
- Validate inputs

### Documentation

- Update README.md for user-facing changes
- Update ARCHITECTURE.md for architectural changes
- Include inline comments for complex code
- Provide examples for new features
- Keep documentation up-to-date

### Security

- Never commit secrets or credentials
- Use Docker secrets for sensitive data
- Follow security best practices
- Report security issues privately

## Testing

Before submitting changes:

1. **Validate configuration**
   ```bash
   ./scripts/validate.sh
   ```

2. **Test Docker builds**
   ```bash
   docker compose build
   ```

3. **Test deployment** (if you have VPN credentials)
   ```bash
   docker compose up -d
   docker compose logs
   docker compose down
   ```

4. **Test documentation**
   - Ensure README instructions work
   - Check for broken links
   - Verify examples are correct

## Areas for Contribution

We welcome contributions in these areas:

### Features
- IPv6 support
- Multiple exit node support
- Web-based monitoring dashboard
- Automatic failover
- Health checks and monitoring
- Split tunneling support

### Documentation
- Additional setup guides
- Troubleshooting tips
- Video tutorials
- Translations

### Testing
- Automated testing scripts
- CI/CD pipeline
- Integration tests
- Performance benchmarks

### Bug Fixes
- Connection stability issues
- Configuration problems
- Documentation errors
- Security vulnerabilities

## Style Guide

### Shell Scripts
```bash
#!/bin/bash
set -e

# Clear description of what the script does

function main() {
    # Function body
    local variable_name="value"
    echo "Message"
}

main "$@"
```

### Docker
```dockerfile
FROM alpine:3.19

# Install packages
RUN apk add --no-cache \
    package1 \
    package2

# Copy files
COPY file.conf /etc/file.conf

# Set permissions
RUN chmod +x /script.sh

ENTRYPOINT ["/script.sh"]
```

### Markdown
- Use clear headings
- Include code blocks with language tags
- Add examples for clarity
- Keep lines under 120 characters when possible

## Questions?

If you have questions about contributing:
- Open a GitHub Discussion
- Comment on a related issue
- Review existing documentation

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing!
