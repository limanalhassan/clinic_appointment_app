variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.33"
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server endpoint is publicly accessible."
  type        = bool
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Grant the caller identity admin permissions on the cluster via access entry."
  type        = bool
  default     = true
}

variable "compute_config" {
  description = "EKS Auto Mode compute configuration."
  type = object({
    enabled    = optional(bool, true)
    node_pools = optional(list(string), ["general-purpose"])
  })
  default = {}
}

variable "vpc_id" {
  description = "VPC ID to deploy the cluster into."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster (use private subnets)."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all EKS resources."
  type        = map(string)
  default     = {}
}
