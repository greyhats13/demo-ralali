provider "aws" {
  region                  = var.region
  profile                 = var.profile
  shared_credentials_file = var.aws_credentials
  # access_key = var.access_key
  # secret_key = var.secret_key
}

module "vpc" {
  source = "./vpc"
}

module "ec2" {
  source        = "./ec2"
  vpc_id        = module.vpc.vpc_id
  public_subnet = flatten([module.vpc.public_subnet])
}

# module "ecr" {
#   source = "./ecr"
# }

module "ecs" {
  source              = "./ecs"
  vpc_id              = module.vpc.vpc_id
  public_subnet       = flatten([module.vpc.public_subnet])
  vpc_zone_identifier = flatten([module.vpc.nodes_subnet])
}

# module "codebuild" {
#   source              = "./codebuild"
# }

