# aws_eks

Wrapper around terraform-aws-modules/eks/aws ~> 21.0 with EKS Auto Mode enabled. Accepts subnet keys from the VPC module and resolves them to IDs in the golden module. No node groups are managed — Auto Mode handles node provisioning automatically.
