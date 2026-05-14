output "vpc_id" {
  description = "VPC ID from registry module"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2_instance.id
}

output "instance_public_ip" {
  description = "Public IP of EC2 instance"
  value       = module.ec2_instance.public_ip
}

output "web_url" {
  description = "URL to access web server"
  value       = "http://${module.ec2_instance.public_ip}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.security_group_web.security_group_id
}
