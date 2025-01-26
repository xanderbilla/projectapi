resource "aws_cloudfront_origin_access_identity" "cdn_oai" {
    comment = "OAI for ${var.project_name}"
}

resource "aws_cloudfront_distribution" "cdn_distribution" {
    origin {
        domain_name = var.target_alb
        origin_id   = var.target_origin_id

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "http-only"
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }

    enabled             = true
    is_ipv6_enabled     = true
    comment             = "CloudFront distribution for projectapi"
    default_root_object = ""

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD", "OPTIONS"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = var.target_origin_id

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        viewer_protocol_policy = "redirect-to-https"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }

    price_class = "PriceClass_100"

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

    tags = {
        Name = "${var.project_name}-distribution"
    }
}
