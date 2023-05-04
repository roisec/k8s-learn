provider "aws" {
  region = var.region
}
data "aws_eks_cluster" "eks" {
  name = module.roi-eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.roi-eks.cluster_id
}
module "roi-eks" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "17.24.0"
  cluster_version                      = var.cluster_version
  write_kubeconfig                     = true
  cluster_name                         = var.cluster_name
  vpc_id                               = module.roi-vpc.vpc_id
  subnets                              = module.roi-vpc.private_subnets
  cluster_endpoint_public_access_cidrs = var.allowing_ips
  cluster_iam_role_name                = aws_iam_role.eks-cluster-role.name
  cluster_endpoint_public_access       = true  // Allow networking from outside
  cluster_endpoint_private_access      = true  //allow networking from nodes within the VPC
  manage_worker_iam_resources          = false // using my node-role 
  manage_cluster_iam_resources         = false // using my Cluster Role
  manage_aws_auth                      = var.manage_aws_auth
  cluster_tags                         = var.cluster_tags
  # AWS Auth (kubernetes_config_map)
  map_roles = [
    {
      rolearn  = module.k8s-service-a.iam_role_arn
      username = "dev-user"
      groups   = [""]
    },
  ]
  enable_irsa = var.enable_irsa
  depends_on = [
    aws_iam_role.eks-cluster-role, aws_iam_role.eks-node-group-role, data.aws_iam_role.node_role
  ]
  node_groups_defaults = {
    additional_tags  = var.cluster_tags
    max_capacity     = 5
    min_capacity     = 3
    desired_capacity = 3
    instance_types   = ["t3.large"]
    iam_role_arn     = data.aws_iam_role.node_role.arn

  }

  #   node_groups = {//create  node groups 
  #     example = {
  #       key_name=""
  #       # public_ip ="true"
  #       worker_security_group_id=[data.aws_security_group.VPN.id]
  #     }
  # }
}
resource "aws_eks_node_group" "test" {
  cluster_name = data.aws_eks_cluster.eks.name
  remote_access {
    ec2_ssh_key               = "roi-test"
    source_security_group_ids = [data.aws_security_group.VPN.id]
  }
  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }
  subnet_ids    = module.roi-vpc.private_subnets
  node_role_arn = data.aws_iam_role.node_role.arn

}


