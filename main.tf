terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1" # Always specify version!

  name = "registry-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true # Cost savings
  enable_dns_hostnames = true

  # Tags
  tags = {
    Environment = "dev"
    Project     = "registry-demo"
    ManagedBy   = "Terraform"
  }

  vpc_tags = {
    Name = "registry-vpc"
  }
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance Module
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"

  name = "registry-web-server"

  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_linux_2.id
  vpc_security_group_ids = [module.security_group_web.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  associate_public_ip_address = true

  # User data
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Registry Module!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

module "security_group_web" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "web-server-sg"
  description = "Security group for web server"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  # Custom SSH rule
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from anywhere"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # Egress
  egress_rules = ["all-all"]

  tags = {
    Environment = "dev"
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  bucket = "my-registry-test-bucket-ericborba"
  # acl = "private"  ← remove this

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced" # disables ACLs entirely

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}


module "security_group_db" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "db-server-sg"
  description = "Security group for database server"
  vpc_id      = module.vpc.vpc_id

  # Allow DB access only from the web/app security group
  ingress_with_source_security_group_id = [
    {
      from_port                = 3306 # swap for 5432 if Postgres
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "MySQL from app/web tier"
      source_security_group_id = module.security_group_web.security_group_id
    }
  ]

  # Allow all outbound
  egress_rules = ["all-all"]
}


# RDS Module
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.2.0"

  identifier = "registry-db"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"

  allocated_storage = 20

  db_name  = "demodb"
  username = "admin"

  create_db_subnet_group = true          # ← ADD THIS
  db_subnet_group_name   = "registry-db" # ← ADD THIS

  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.security_group_db.security_group_id]

  tags = {
    Environment = "dev"
  }
}
