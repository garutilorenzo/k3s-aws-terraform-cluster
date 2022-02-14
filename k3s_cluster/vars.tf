variable "AWS_REGION" {
  type = string
}

variable "environment" {
  type = string
}

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-0ae74ae9c43584639"
    us-west-2 = "ami-09f5b7791a4e85729"
    eu-west-1 = "ami-081ff4b9aa4e81a08" # ami-0da36f7f059b7086e
  }
}

variable "PATH_TO_PUBLIC_KEY" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Path to your public key"
}

variable "PATH_TO_PRIVATE_KEY" {
  type        = string
  default     = "~/.ssh/id_rsa"
  description = "Path to your private key"
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "my_public_ip_cidr" {
  type        = string
  description = "My public ip CIDR"
}

variable "vpc_subnet_cidr" {
  type        = string
  description = "VPC subnet CIDR"
}

variable "vpc_subnets" {
  type        = list(any)
  description = "The vpc subnets ids"
}

variable "default_instance_type" {
  type        = string
  default     = "t3.large"
  description = "Instance type to be used"
}

variable "instance_types" {
  description = "List of instance types to use"
  type        = map(string)
  default = {
    asg_instance_type_1 = "t3.large"
    asg_instance_type_2 = "t2.large"
    asg_instance_type_3 = "m4.large"
    asg_instance_type_4 = "t3a.large"
  }
}

variable "default_instance_profile_name" {
  type        = string
  default     = "AWSEC2K3SInstanceProfile"
  description = "Default instance profile name"
}

variable "default_iam_role" {
  type        = string
  default     = "AWSEC2K3SRole"
  description = "Default IAM role name"
}

variable "kube_api_port" {
  type        = number
  default     = 6443
  description = "Kubeapi Port"
}

variable "create_extlb" {
  type        = bool
  default     = false
  description = "Create external LB true/false"
}

variable "extlb_http_port" {
  type        = number
  default     = 80
  description = "External LB HTTP port"
}

variable "extlb_https_port" {
  type        = number
  default     = 443
  description = "External LB HTTPS port"
}

variable "k3s_server_desired_capacity" {
  type        = number
  default     = 3
  description = "K3s server ASG desired capacity"
}

variable "k3s_server_min_capacity" {
  type        = number
  default     = 3
  description = "K3s server ASG min capacity"
}

variable "k3s_server_max_capacity" {
  type        = number
  default     = 4
  description = "K3s server ASG max capacity"
}

variable "k3s_worker_desired_capacity" {
  type        = number
  default     = 3
  description = "K3s server ASG desired capacity"
}

variable "k3s_worker_min_capacity" {
  type        = number
  default     = 3
  description = "K3s server ASG min capacity"
}

variable "k3s_worker_max_capacity" {
  type        = number
  default     = 4
  description = "K3s server ASG max capacity"
}

variable "cluster_name" {
  type        = string
  default     = "k3s-cluster"
  description = "Cluster name"
}

variable "k3s_token" {
  type        = string
  description = "Override to set k3s cluster registration token"
}