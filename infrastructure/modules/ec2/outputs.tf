output "ec2_instance_ids" {
  value       = aws_instance.ec2_instance[*].id
  description = "List of EC2 instance IDs"
}

output "ec2_public_ips" {
  value       = aws_instance.ec2_instance[*].public_ip
  description = "Public IPs of the EC2 instances"
}
