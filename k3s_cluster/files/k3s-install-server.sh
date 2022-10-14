#!/bin/bash

check_os() {
  name=$(cat /etc/os-release | grep ^NAME= | sed 's/"//g')
  clean_name=$${name#*=}

  version=$(cat /etc/os-release | grep ^VERSION_ID= | sed 's/"//g')
  clean_version=$${version#*=}
  major=$${clean_version%.*}
  minor=$${clean_version#*.}
  
  if [[ "$clean_name" == "Ubuntu" ]]; then
    operating_system="ubuntu"
  elif [[ "$clean_name" == "Amazon Linux" ]]; then
    operating_system="amazonlinux"
  else
    operating_system="undef"
  fi

  echo "K3S install process running on: "
  echo "OS: $operating_system"
  echo "OS Major Release: $major"
  echo "OS Minor Release: $minor"
}

wait_lb() {
while [ true ]
do
  curl --output /dev/null --silent -k https://${k3s_url}:6443
  if [[ "$?" -eq 0 ]]; then
    break
  fi
  sleep 5
  echo "wait for LB"
done
}

render_nginx_config(){
cat << 'EOF' > "$NGINX_RESOURCES_FILE"
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
    app.kubernetes.io/version: ${nginx_ingress_release}
    helm.sh/chart: ingress-nginx-4.0.16
  name: ingress-nginx-controller
  namespace: ingress-nginx
EOF
}

render_staging_issuer(){
STAGING_ISSUER_RESOURCE=$1
cat << 'EOF' > "$STAGING_ISSUER_RESOURCE"
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
}

render_prod_issuer(){
PROD_ISSUER_RESOURCE=$1
cat << 'EOF' > "$PROD_ISSUER_RESOURCE"
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
}

check_os

if [[ "$operating_system" == "ubuntu" ]]; then
  apt-get update
  apt-get install -y software-properties-common unzip git nfs-common jq
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip
fi

if [[ "$operating_system" == "amazonlinux" ]]; then
  yum install -y unzip curl jq git
  aws_region="$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)"
  export AWS_DEFAULT_REGION=$aws_region
fi

k3s_install_params=("--tls-san ${k3s_tls_san}")
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

%{ if install_nginx_ingress } 
k3s_install_params+=("--disable traefik")
%{ endif }

%{ if expose_kubeapi }
k3s_install_params+=("--tls-san ${k3s_tls_san_public}")
%{ endif }

INSTALL_PARAMS="$${k3s_install_params[*]}"

%{ if k3s_version == "latest" }
K3S_VERSION=$(curl --silent https://api.github.com/repos/k3s-io/k3s/releases/latest | jq -r '.name')
%{ else }
K3S_VERSION="${k3s_version}"
%{ endif }

first_instance=$(aws ec2 describe-instances --filters Name=tag-value,Values=k3s-server Name=instance-state-name,Values=running --query 'sort_by(Reservations[].Instances[], &LaunchTime)[:-1].[InstanceId]' --output text | head -n1)
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

if [[ "$first_instance" == "$instance_id" ]]; then
  echo "I'm the first yeeee: Cluster init!"
  until (curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION K3S_TOKEN=${k3s_token} sh -s - --cluster-init $INSTALL_PARAMS); do
    echo 'k3s did not install correctly'
    sleep 2
  done
else
  echo ":( Cluster join"
  wait_lb
  until (curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION K3S_TOKEN=${k3s_token} sh -s - --server https://${k3s_url}:6443 $INSTALL_PARAMS); do
    echo 'k3s did not install correctly'
    sleep 2
  done
fi

%{ if is_k3s_server }
until kubectl get pods -A | grep 'Running'; do
  echo 'Waiting for k3s startup'
  sleep 5
done

%{ if install_node_termination_handler }
#Install node termination handler
if [[ "$first_instance" == "$instance_id" ]]; then
  echo 'Install node termination handler'
  kubectl apply -f https://github.com/aws/aws-node-termination-handler/releases/download/${node_termination_handler_release}/all-resources.yaml
fi
%{ endif }

%{ if install_nginx_ingress }
if [[ "$first_instance" == "$instance_id" ]]; then
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${nginx_ingress_release}/deploy/static/provider/baremetal/deploy.yaml
  NGINX_RESOURCES_FILE=/root/nginx-ingress-resources.yaml
  render_nginx_config
  kubectl apply -f $NGINX_RESOURCES_FILE
fi
%{ endif }

%{ if install_certmanager }
if [[ "$first_instance" == "$instance_id" ]]; then
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${certmanager_release}/cert-manager.yaml
  
  # Wait cert-manager to be ready
  until kubectl get pods -n cert-manager | grep 'Running'; do
    echo 'Waiting for cert-manager to be ready'
    sleep 15
  done

  render_staging_issuer /root/staging_issuer.yaml
  render_prod_issuer /root/prod_issuer.yaml

  kubectl create -f /root/prod_issuer.yaml
  kubectl create -f /root/staging_issuer.yaml
fi
%{ endif }

%{ if efs_persistent_storage }
if [[ "$first_instance" == "$instance_id" ]]; then
  git clone https://github.com/kubernetes-sigs/aws-efs-csi-driver.git
  cd aws-efs-csi-driver/
  git checkout tags/${efs_csi_driver_release} -b kube_deploy_${efs_csi_driver_release}
  kubectl apply -k deploy/kubernetes/overlays/stable/

  # Uncomment this to mount the EFS share on the first k3s-server node
  # mkdir /efs
  # aws_region="$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)"
  # mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_filesystem_id}.efs.$aws_region.amazonaws.com:/ /efs
fi
%{ endif }

# Upload kubeconfig on AWS secret manager
if [[ "$first_instance" == "$instance_id" ]]; then
  cat /etc/rancher/k3s/k3s.yaml | sed 's/server: https:\/\/127.0.0.1:6443/server: https:\/\/${k3s_url}:6443/' > /root/k3s_lb.yaml
  aws secretsmanager update-secret --secret-id ${kubeconfig_secret_name} --secret-string file:///root/k3s_lb.yaml
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