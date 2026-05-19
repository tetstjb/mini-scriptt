#!/bin/bash

RESOLV="/etc/resolv.conf"

echo "Current nameservers:"
grep "^nameserver" "$RESOLV"

echo

if grep -q "^nameserver" "$RESOLV"; then
    read -p "Nameservers already exist. Replace them? (y/n): " choice

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        # Remove existing nameservers
        sed -i '/^nameserver/d' "$RESOLV"
    else
        echo "Cancelled."
        exit 0
    fi
fi

echo "Enter nameserver(s). Example:"
echo "1.1.1.1"
echo "8.8.8.8"
echo

while true; do
    read -p "Nameserver (leave empty to finish): " ns

    [[ -z "$ns" ]] && break

    echo "nameserver $ns" >> "$RESOLV"
done

echo
echo "Updated /etc/resolv.conf:"
cat "$RESOLV"
