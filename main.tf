variable "AWS_ACCESS_KEY" {

}

variable "AWS_SECRET_KEY" {

}

variable "AWS_REGION" {
  type        = string
  default     = "<change_me>"
  description = "AWS Zone"
}

module "k3s_cluster" {
  AWS_REGION                = "<change_me>"
  environment               = "staging"
  my_public_ip_cidr         = "<change_me>"
  vpc_id                    = "<change_me>"
  vpc_subnets               = ["<change_me>", "<change_me>", "<change_me>"]
  vpc_subnet_cidr           = "<change_me>"
  cluster_name              = "k3s-cluster"
  create_extlb              = "<true|false>"
  expose_kubeapi            = "<true|false>"
  efs_persistent_storage    = "<true|false>"
  certmanager_email_address = "<change_me>"
  source                    = "github.com/garutilorenzo/k3s-aws-terraform-cluster"
}

output "elb_dns_name" {
  value = module.k3s_cluster.elb_dns_name
}

output "k3s_server_public_ips" {
  value = module.k3s_cluster.k3s_server_public_ips
}

output "k3s_workers_public_ips" {
  value = module.k3s_cluster.k3s_workers_public_ips
}