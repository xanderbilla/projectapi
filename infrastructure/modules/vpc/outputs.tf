output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the created VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs"
}

output "route_table_id" {
  value       = aws_route_table.public.id
  description = "ID of the public route table"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.igw.id
  description = "ID of the internet gateway"
}
