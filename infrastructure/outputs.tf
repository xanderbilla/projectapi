output "cloudfront_distribution_dns_name" {
  value       = "https://${module.cloudfront.cloudfront_domain_name}/health"
  description = "The DNS name of the CloudFront Distribution"
}