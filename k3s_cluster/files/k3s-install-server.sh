#!/bin/bash

apt-get update
apt-get install -y software-properties-common unzip
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

local_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
flannel_iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)')
provider_id="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

first_instance=$(aws ec2 describe-instances --filters Name=tag-value,Values=k3s-server Name=instance-state-name,Values=running --query 'sort_by(Reservations[].Instances[], &LaunchTime)[:-1].[InstanceId]' --output text | head -n1)
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
first_last="last"

if [[ "$first_instance" == "$instance_id" ]]; then
    echo "I'm the first yeeee: Cluster init!"
    first_last="first"
    until (curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --cluster-init --node-ip $local_ip --advertise-address $local_ip --flannel-iface $flannel_iface --tls-san ${k3s_tls_san} --kubelet-arg="provider-id=aws:///$provider_id"); do
      echo 'k3s did not install correctly'
      sleep 2
    done
else
    echo "I'm like England :( Cluster join"
    until (curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --server https://${k3s_url}:6443 --node-ip $local_ip --advertise-address $local_ip --flannel-iface $flannel_iface --tls-san ${k3s_tls_san} --kubelet-arg="provider-id=aws:///$provider_id"  ); do
      echo 'k3s did not install correctly'
      sleep 2
    done
fi

%{ if is_k3s_server }
until kubectl get pods -A | grep 'Running'; do
  echo 'Waiting for k3s startup'
  sleep 5
done

#Install node termination handler
if [[ "$first_last" == "first" ]]; then
  echo 'Install node termination handler'
  kubectl apply -f https://github.com/aws/aws-node-termination-handler/releases/download/v1.13.3/all-resources.yaml
fi
%{ endif }

#kubectl get pods -n kube-system | grep aws-node | wc -l
#kubectl get pods -n kube-system | grep cluster-autoscaler | wc -l
#wget https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
#command:
#            - ./cluster-autoscaler
#            - --v=4
#            - --stderrthreshold=info
#            - --cloud-provider=aws
#            - --skip-nodes-with-local-storage=false
#            - --skip-nodes-with-system-pods=false
#            - --balance-similar-node-groups
#            - --expander=random
#            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/k3s-cluster
#       volumes:
#        - name: ssl-certs
#          hostPath:
#            path: "/etc/ssl/certs/ca-certificates.crt"