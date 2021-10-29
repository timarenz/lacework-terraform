#!/bin/bash

set -e

GPG_KEY=C874011F0AB405110D02105534365D9472D7468F
KEY_SERVER=hkp://keyserver.ubuntu.com:80
CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"

if [ -z "${CONSUL_VERSION}" ]; then
    CONSUL_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')
fi

echo "Consul version: ${CONSUL_VERSION}"

gpg --keyserver "${KEY_SERVER}" --recv-keys "${GPG_KEY}"

echo "Downloading Consul binaries from releases.hashicorp.com..."
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig

gpg --batch --verify consul_${CONSUL_VERSION}_SHA256SUMS.sig consul_${CONSUL_VERSION}_SHA256SUMS
grep consul_${CONSUL_VERSION}_linux_amd64.zip consul_${CONSUL_VERSION}_SHA256SUMS | sha256sum -c 

unzip -o consul_${CONSUL_VERSION}_linux_amd64.zip

sudo chown root:root consul
sudo mv consul /usr/bin/
sudo setcap "cap_net_bind_service=+ep" /usr/bin/consul
consul --version

consul -autocomplete-install
complete -C /usr/bin/consul consul

sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

sudo touch /usr/lib/systemd/system/consul.service

sudo tee /usr/lib/systemd/system/consul.service <<EOF 
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/consul.hcl

sudo mv /tmp/consul.hcl /etc/consul.d/consul.hcl

sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

sudo systemctl enable consul
sudo systemctl start consul
sudo systemctl status consul --no-pager