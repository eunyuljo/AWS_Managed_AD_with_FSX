#!/bin/bash

# Update system
yum update -y

# Install BIND9 DNS server
yum install -y bind bind-utils

# Backup original configuration
cp /etc/named.conf /etc/named.conf.backup

# Configure BIND9
cat > /etc/named.conf << 'EOF'
options {
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    
    listen-on port 53 { any; };
    listen-on-v6 port 53 { ::1; };
    
    allow-query { any; };
    allow-recursion { any; };
    
    // Forwarders for recursive resolution
    forwarders {
        ${forwarder_dns};
    };
    
    // Enable recursive resolution
    forward first;  // Try forwarders first, then recursive
    
    recursion yes;
    dnssec-enable yes;
    dnssec-validation yes;
    
    bindkeys-file "/etc/named.root.key";
    managed-keys-directory "/var/named/dynamic";
    
    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";
};

logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

// Local zone
zone "${dns_zone_name}" IN {
    type master;
    file "${dns_zone_name}.zone";
    allow-update { none; };
};
EOF

# Wait for network interface to be ready
sleep 10

# Get server IP address with retry logic
for i in {1..10}; do
    SERVER_IP=$(hostname -I | awk '{print $1}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
    if [ ! -z "$SERVER_IP" ]; then
        echo "Detected server IP: $SERVER_IP"
        break
    fi
    echo "Waiting for IP address... attempt $i"
    sleep 5
done

if [ -z "$SERVER_IP" ]; then
    echo "Failed to get server IP, using fallback"
    SERVER_IP="127.0.0.1"
fi

# Create zone file with proper formatting
cat > /var/named/${dns_zone_name}.zone << EOF
\$TTL 86400
@       IN      SOA     ns1.${dns_zone_name}. admin.${dns_zone_name}. (
                        2023072301      ; serial number
                        3600            ; refresh period
                        1800            ; retry period
                        604800          ; expire time
                        86400           ; minimum TTL
)

; Name servers
@       IN      NS      ns1.${dns_zone_name}.

; A records
ns1     IN      A       $SERVER_IP

; Custom DNS records
%{ for record in dns_records ~}
${record.name}    IN    ${record.type}    ${record.value}
%{ endfor ~}
EOF

# Set proper permissions
chown named:named /var/named/${dns_zone_name}.zone
chmod 644 /var/named/${dns_zone_name}.zone

# Check BIND configuration
named-checkconf
if [ $? -eq 0 ]; then
    echo "BIND configuration is valid"
else
    echo "BIND configuration has errors"
    exit 1
fi

# Debug: Show the created zone file
echo "=== Created zone file content ==="
cat /var/named/${dns_zone_name}.zone
echo "================================="

# Check zone file with detailed error output
echo "Checking zone file..."
named-checkzone ${dns_zone_name} /var/named/${dns_zone_name}.zone
ZONE_CHECK_RESULT=$?

if [ $ZONE_CHECK_RESULT -eq 0 ]; then
    echo "Zone file is valid"
else
    echo "Zone file has errors, exit code: $ZONE_CHECK_RESULT"
    echo "Zone file content:"
    cat -n /var/named/${dns_zone_name}.zone
    
    # Try to fix common issues and recreate
    echo "Attempting to recreate zone file..."
    cat > /var/named/${dns_zone_name}.zone << EOF
\$TTL 86400
@       IN      SOA     ns1.${dns_zone_name}. admin.${dns_zone_name}. (
                        2023072301      ; serial
                        3600            ; refresh
                        1800            ; retry
                        604800          ; expire
                        86400 )         ; minimum

@       IN      NS      ns1.${dns_zone_name}.
ns1     IN      A       $SERVER_IP
%{ for record in dns_records ~}
${record.name}    IN    ${record.type}    ${record.value}
%{ endfor ~}
EOF
    
    chown named:named /var/named/${dns_zone_name}.zone
    chmod 644 /var/named/${dns_zone_name}.zone
    
    # Check again
    named-checkzone ${dns_zone_name} /var/named/${dns_zone_name}.zone
fi

# Check overall BIND configuration
echo "Checking BIND configuration..."
named-checkconf
CONF_CHECK_RESULT=$?

if [ $CONF_CHECK_RESULT -ne 0 ]; then
    echo "BIND configuration has errors, exit code: $CONF_CHECK_RESULT"
    echo "Configuration file:"
    cat /etc/named.conf
fi

# Start and enable BIND9
echo "Starting BIND9..."
systemctl start named
NAMED_START_RESULT=$?

if [ $NAMED_START_RESULT -eq 0 ]; then
    echo "BIND9 started successfully"
    systemctl enable named
else
    echo "Failed to start BIND9, exit code: $NAMED_START_RESULT"
    echo "Checking logs..."
    journalctl -u named -n 20 --no-pager
fi

# Configure firewall (if enabled)
firewall-cmd --permanent --add-service=dns 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

# Create startup script for DNS server info
cat > /root/dns-server-info.sh << 'EOF'
#!/bin/bash
echo "=== DNS Server Information ==="
echo "Server IP: $(hostname -I | awk '{print $1}')"
echo "Zone: ${dns_zone_name}"
echo "Status: $(systemctl is-active named)"
echo "==============================="
EOF

chmod +x /root/dns-server-info.sh
/root/dns-server-info.sh

# Create comprehensive setup log
SETUP_LOG="/var/log/dns-server-setup.log"
{
    echo "=== DNS Server Setup Log ==="
    echo "Date: $(date)"
    echo "Zone: ${dns_zone_name}"
    echo "Server IP: $SERVER_IP"
    echo "BIND Status: $(systemctl is-active named)"
    echo "Zone Check Result: $ZONE_CHECK_RESULT"
    echo "Config Check Result: $CONF_CHECK_RESULT"
    echo "Service Start Result: $NAMED_START_RESULT"
    echo "=========================="
} > $SETUP_LOG

# Log installation completion
logger "DNS Server setup completed for zone ${dns_zone_name}"
echo "DNS Server setup completed for zone ${dns_zone_name}" >> $SETUP_LOG

# Test DNS resolution with more comprehensive testing
echo "Testing DNS resolution..." >> $SETUP_LOG
{
    echo "=== DNS Resolution Tests ==="
    echo "Testing zone apex:"
    dig @127.0.0.1 ${dns_zone_name} +short
    echo "Testing NS record:"
    dig @127.0.0.1 ${dns_zone_name} NS +short
    echo "Testing ns1 record:"
    dig @127.0.0.1 ns1.${dns_zone_name} +short
    %{ for record in dns_records ~}
    echo "Testing ${record.name}.${dns_zone_name}:"
    dig @127.0.0.1 ${record.name}.${dns_zone_name} +short
    %{ endfor ~}
    echo "==========================="
} >> $SETUP_LOG 2>&1

# Final status check
systemctl status named >> $SETUP_LOG 2>&1

echo "Setup completed. Check $SETUP_LOG for details."