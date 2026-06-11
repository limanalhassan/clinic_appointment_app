# aws_eks_pod_identity

Creates IAM roles with EKS Pod Identity associations. Each entry in the `associations` map produces one IAM role (with optional inline and managed policies) and one `aws_eks_pod_identity_association` that binds the role to a Kubernetes service account in a given namespace.

The IAM trust policy is automatically set to trust `pods.eks.amazonaws.com` — no OIDC provider required. Requires the EKS Pod Identity Agent to be running on the cluster (included in EKS Auto Mode by default).
