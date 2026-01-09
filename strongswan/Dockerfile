FROM alpine:3.19

# Install StrongSwan, xl2tpd and required tools
RUN apk add --no-cache \
    strongswan \
    xl2tpd \
    ppp \
    iptables \
    iproute2 \
    bash \
    openrc

# Create necessary directories
RUN mkdir -p /etc/ipsec.d/cacerts \
    /etc/ipsec.d/certs \
    /etc/ipsec.d/private \
    /etc/xl2tpd \
    /var/run/xl2tpd \
    /var/log

# Copy configuration files
COPY ipsec.conf /etc/ipsec.conf
COPY ipsec.secrets.template /etc/ipsec.secrets.template
COPY xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
COPY options.l2tpd.client /etc/ppp/options.l2tpd.client
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
