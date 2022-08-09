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

%{ if install_nginx_ingress } 
disable_traefik="--disable traefik"
%{ endif }

if [[ "$first_instance" == "$instance_id" ]]; then
    echo "I'm the first yeeee: Cluster init!"
    first_last="first"
    until (curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --cluster-init $disable_traefik --node-ip $local_ip --advertise-address $local_ip --flannel-iface $flannel_iface --tls-san ${k3s_tls_san} --kubelet-arg="provider-id=aws:///$provider_id"); do
      echo 'k3s did not install correctly'
      sleep 2
    done
else
    echo "I'm like England :( Cluster join"
    until (curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --server https://${k3s_url}:6443 $disable_traefik --node-ip $local_ip --advertise-address $local_ip --flannel-iface $flannel_iface --tls-san ${k3s_tls_san} --kubelet-arg="provider-id=aws:///$provider_id"  ); do
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

%{ if install_longhorn }
if [[ "$first_last" == "first" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  open-iscsi curl util-linux
    systemctl enable iscsid.service
    systemctl start iscsid.service
    for instance in $(aws ec2 describe-instances --filters Name=tag-value,Values=k3s-server Name=instance-state-name,Values=running --query 'Reservations[*].Instances[?InstanceLifecycle!=`spot`][InstanceId]' --output text)
    do
      echo $instance
      kubectl label nodes $instance node.longhorn.io/create-default-disk=true
    done
    curl -o /root/longhorn.yaml https://raw.githubusercontent.com/longhorn/longhorn/${longhorn_release}/deploy/longhorn.yaml
    sed -i 's/create-default-disk-labeled-nodes:/create-default-disk-labeled-nodes: true/' /root/longhorn.yaml
    kubectl apply -f /root/longhorn.yaml
    kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/${longhorn_release}/examples/storageclass.yaml
fi
%{ endif }

%{ if install_nginx_ingress }
if [[ "$first_last" == "first" ]]; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/baremetal/deploy.yaml
cat << 'EOF' > /root/nginx-ingress-resources.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller-loadbalancer
  namespace: ingress-nginx
spec:
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: 80
    - name: https
      port: 443
      protocol: TCP
      targetPort: 443
  type: LoadBalancer
---
apiVersion: v1
data:
  allow-snippet-annotations: "true"
  enable-real-ip: "true"
  proxy-real-ip-cidr: "0.0.0.0/0"
  proxy-body-size: "20m"
  use-proxy-protocol: "true"
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.1.1
    helm.sh/chart: ingress-nginx-4.0.16
  name: ingress-nginx-controller
  namespace: ingress-nginx
EOF
    kubectl apply -f /root/nginx-ingress-resources.yaml
fi
%{ endif }

%{ if install_certmanager }
if [[ "$first_last" == "first" ]]; then
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${certmanager_release}/cert-manager.yaml

cat << 'EOF' > /root/staging_issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
 name: letsencrypt-staging
 namespace: cert-manager
spec:
 acme:
   # The ACME server URL
   server: https://acme-staging-v02.api.letsencrypt.org/directory
   # Email address used for ACME registration
   email: ${certmanager_email_address}
   # Name of a secret used to store the ACME account private key
   privateKeySecretRef:
     name: letsencrypt-staging
   # Enable the HTTP-01 challenge provider
   solvers:
   - http01:
       ingress:
         class:  nginx
EOF

cat << 'EOF' > /root/prod_issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: ${certmanager_email_address}
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
    kubectl create -f prod_issuer.yaml
    kubectl create -f staging_issuer.yaml
fi
%{ endif }

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