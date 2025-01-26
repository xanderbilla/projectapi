module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr_block      = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones  = ["ap-south-1a", "ap-south-1b"]
  project_name        = "lab"
}

module "security_groups" {
  source           = "./modules/security_group"
  project_name     = "lab"
  vpc_id           = module.vpc.vpc_id 
  ssh_allowed_cidr = "0.0.0.0/0"
}

module "ec2_iam_role" {
  source       = "./modules/iam_role"
  project_name = "lab"
}

module "ec2_instances" {
  source             = "./modules/ec2"
  project_name       = "lab"
  ami_id             = "ami-0d2614eafc1b0e4d2"
  public_subnet_ids  = module.vpc.public_subnet_ids 
  ec2_role_name      = module.ec2_iam_role.ec2_role_name
  security_group_ids = [module.security_groups.ec2_security_group_id]
}

module "alb" {
  source             = "./modules/alb"
  project_name       = "lab"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids                   
  security_group_ids = [module.security_groups.alb_security_group_id] 
  ec2_instance_ids   = module.ec2_instances.ec2_instance_ids          
}

module "cloudfront" {
  source           = "./modules/cloudfront"
  project_name     = "lab"
  target_origin_id = "lab-alb"
  target_alb       = module.alb.alb_dns_name
}

module "cloudwatch_event" {
  source          = "./modules/cloudwatch_event"
  repository_name = "myprojectapi"
  image_tag       = "latest"
}

module "ssm_document" {
  source        = "./modules/ssm_document"
  document_name = "WebServerDocument"
}

module "event_ssm_role" {
  source    = "./modules/event_ssm_role"
  role_name = "eventbridge-ssm-role"
}

  module "event_ssm_target" {
  source = "./modules/event_ssm_target"
  ec2_instance_ids           = module.ec2_instances.ec2_instance_ids
  cloudwatch_event_rule_name = module.cloudwatch_event.ecr_image_push_rule_name 
  ssm_document_arn         = module.ssm_document.run_command_arn
  eventbridge_ssm_role_arn  = module.event_ssm_role.eventbridge_ssm_role_arn
}

module "cloudwatch_logging" {
  source = "./modules/cloudwatch_logging"
  log_group_name       = "/aws/logs/EC2-ALB-CloudFront"
  log_stream_name      = "ec2-alb-cloudfront-stream"
  log_retention_in_days = 30
}
