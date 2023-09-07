#!/usr/bin/env bash

set -eu

for IP in $CONTROLLER_IPS $WORKER_IPS; do
    echo "Setting up network and dhcp configs: $IP"

    # Install resolvconf
    ssh "root@$IP" 'apt install -y resolvconf'

    # Export for envsubst
    export NODE_IFACE="enp0s3"
    export NODE_IP="$IP"
    export NODE_CIDR=24
    export GATEWAY_IP="192.168.0.1"
    export DNS_SEARCH="example.com"
    export DNS_NAMESERVERS="8.8.8.8"

    # Copy network config
    envsubst < ./etc_network_interfaces | ssh "root@$IP" 'cat > /etc/network/interfaces'

    # Copy dhcp config
    scp ./etc_dhcp_dhclient.conf "root@$IP:/etc/dhcp/dhclient.conf"

    # Regenerate /etc/resolv.conf and reboot
    ssh "root@$IP" 'resolvconf -u'
    ssh "root@$IP" "ifdown $NODE_IFACE && ifup $NODE_IFACE"

    set +e
    while true; do
        echo "Waiting for $IP to come back online..."
        sleep 1
        if ssh "root@$IP" "echo Ready: $IP"; then
            break
        fi
    done

    ssh "root@$IP" reboot

    while true; do
        echo "Waiting for $IP to reboot..."
        sleep 1
        if ssh "root@$IP" "echo Ready: $IP"; then
            break
        fi
    done
    set -e
done
