variable "AWS_ACCESS_KEY" {

}

variable "AWS_SECRET_KEY" {

}

variable "AWS_REGION" {
  default = "<change_me>"
  description = "AWS Zone"
}

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-0ae74ae9c43584639"
    us-west-2 = "ami-09f5b7791a4e85729"
    eu-west-1 = "ami-0da36f7f059b7086e"
  }
  description = "Ami image to use"
}

variable "PATH_TO_PUBLIC_KEY" {
  default     = "~/.ssh/id_rsa.pub"
  description = "Path to your public key"
}

variable "PATH_TO_PRIVATE_KEY" {
  default     = "~/.ssh/id_rsa"
  description = "Path to your private key"
}

variable "cluster_name" {
  type        = string
  default     = "k3s-cluster"
  description = "Cluster name"
}

variable "vpc_id" {
  type        = string
  default     = "<change_me>"
  description = "The vpc id"
}

variable "instance_profile_name" {
  type        = string
  default     = "AWSEC2ReadOnlyAccess"
  description = "The name of the instance profile to use"
}

variable "my_public_ip_cidr" {
  type        = string
  default     = "<change_me>/32"
  description = "My public ip CIDR"
}

variable "vpc_subnet_cidr" {
  type        = string
  default     = "<change_me>"
  description = "VPC subnet CIDR"
}

variable "vpc_subnets" {
  type        = list(any)
  default     = ["<change_me>", "<change_me>", "<change_me>"]
  description = "The vpc subnets ids"
}

variable "k3s_token" {
  default     = "08c7d6aq22bzn61b1q04dbc81g8hedbazyte9d9c7dsfa0d0v883"
  type        = string
  description = "Override to set k3s cluster registration token"
}