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
  AWS_REGION          = "<change_me>"
  environment         = "staging"
  my_public_ip_cidr   = "<change_me>"
  vpc_id              = "<change_me>"
  vpc_subnets         = ["<change_me>", "<change_me>", "<change_me>"]
  vpc_subnet_cidr     = "<change_me>"
  cluster_name        = "k3s-cluster"
  k3s_token           = "<change_me>"
  source              = "./k3s_cluster/"
}