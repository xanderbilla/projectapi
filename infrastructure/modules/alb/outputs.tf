output "alb_dns_name" {
  value       = aws_lb.lab_alb.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.lab_alb_tg.arn
  description = "ARN of the ALB target group"
}
