locals {
  eks_config   = jsondecode(file("${path.module}/configs/config_eks.json"))
  cluster_name = local.eks_config.cluster.name
}

provider "aws" {
  region  = local.config.region
  profile = local.config.profile
}

data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.config.region, "--profile", local.config.profile]
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", local.config.region, "--profile", local.config.profile]
  }
}
