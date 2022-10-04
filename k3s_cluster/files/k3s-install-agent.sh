#!/bin/bash

apt-get update
apt-get install -y software-properties-common unzip
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

k3s_install_params=()

%{ if k3s_subnet != "default_route_table" } 
local_ip=$(ip -4 route ls ${k3s_subnet} | grep -Po '(?<=src )(\S+)')
flannel_iface=$(ip -4 route ls ${k3s_subnet} | grep -Po '(?<=dev )(\S+)')

k3s_install_params+=("--node-ip $local_ip")
k3s_install_params+=("--advertise-address $local_ip")
k3s_install_params+=("--flannel-iface $flannel_iface")
%{ endif }

provider_id="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
k3s_install_params+=("--kubelet-arg cloud-provider=external")
k3s_install_params+=("--kubelet-arg provider-id=aws:///$provider_id")

INSTALL_PARAMS="$${k3s_install_params[*]}"

%{ if k3s_version == "latest" }
K3S_VERSION=$(curl --silent https://api.github.com/repos/k3s-io/k3s/releases/latest | jq -r '.name')
%{ else }
K3S_VERSION="${k3s_version}"
%{ endif }

until (curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION K3S_TOKEN=${k3s_token} K3S_URL=https://${k3s_url}:6443 sh -s - $INSTALL_PARAMS); do
    echo 'k3s did not install correctly'
    sleep 2
done