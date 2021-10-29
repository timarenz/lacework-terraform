#!/bin/bash

sudo mkdir -p /etc/systemd/resolved.conf.d/

sudo touch /etc/systemd/resolved.conf.d/consul.conf

sudo tee /etc/systemd/resolved.conf.d/consul.conf <<EOF 
[Resolve]
DNS=127.0.0.1
DNSSEC=false
Domains=~consul
EOF

sudo systemctl restart systemd-resolved.service 

# sudo iptables --table nat --append OUTPUT --destination localhost --protocol udp --match udp --dport 53 --jump REDIRECT --to-ports 8600
# sudo iptables --table nat --append OUTPUT --destination localhost --protocol tcp --match tcp --dport 53 --jump REDIRECT --to-ports 8600