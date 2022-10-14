output "elb_dns_name" {
  value       = var.create_extlb ? aws_lb.external_lb.*.dns_name : []
  description = "ELB public DNS name"
}

output "k3s_server_public_ips" {
  value = data.aws_instances.k3s_servers.*.public_ips
}

output "k3s_workers_public_ips" {
  value = data.aws_instances.k3s_workers.*.public_ips
}