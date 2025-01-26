# Create the Application Load Balancer (ALB)
resource "aws_lb" "lab_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = var.security_group_ids
  subnets            = var.subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Create a target group for the ALB (on port 8080)
resource "aws_lb_target_group" "lab_alb_tg" {
  name     = "${var.project_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
        path                = "/health"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
    }

  tags = {
    Name = "${var.project_name}-target-group"
  }
}

# Create listener for ALB on port 80
resource "aws_lb_listener" "lab_listener" {
  load_balancer_arn = aws_lb.lab_alb.arn
  port              = "80"
  protocol          = "HTTP"

     default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.lab_alb_tg.arn
    }
}

# Attach EC2 Instances to the Target Group
resource "aws_lb_target_group_attachment" "ec2_attachment" {
  count               = length(var.ec2_instance_ids)
  target_group_arn    = aws_lb_target_group.lab_alb_tg.arn
  target_id           = element(var.ec2_instance_ids, count.index)
  port                = 8080
}
