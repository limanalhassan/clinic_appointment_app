module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access                   = var.endpoint_public_access
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  compute_config = {
    enabled    = var.compute_config.enabled
    node_pools = var.compute_config.node_pools
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_loadbalancing" {
  role       = module.eks.cluster_iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}
