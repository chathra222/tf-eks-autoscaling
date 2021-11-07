
locals {
  name            = "eks-scalable-cluster"
  cluster_version = "1.20"
  region          = "ap-southeast-1"
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  enable_irsa = true

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = "t3.medium"
      asg_desired_capacity = 1
      asg_max_size         = 4
      #Cluster autoscaler Auto-Discovery Setup
      #https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.name}"
          "propagate_at_launch" = "false"
          "value"               = "owned"
        }
      ]
    }
  ]
  tags = {
    clustername = local.name
  }
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}


################################################################################
# Supporting Resources
################################################################################

data "aws_availability_zones" "available" {
}


