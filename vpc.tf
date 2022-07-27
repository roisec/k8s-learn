module "roi-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name                 = "Roi-Test-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
resource "aws_security_group" "VPN" {
  description = "Allow connection from my computer"
  vpc_id = module.roi-vpc.vpc_id
  tags = {
    "Name" = "Allow My computer IP"
  }
  ingress {
    description = "My IP"
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = var.allowing_ips
    
  }
  egress {
    description = "any outbound"
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}
data "aws_security_group" "VPN" {
  id = aws_security_group.VPN.id
}
output "sg" {
  description = "sg"
  value       = data.aws_security_group.VPN.id
  }
