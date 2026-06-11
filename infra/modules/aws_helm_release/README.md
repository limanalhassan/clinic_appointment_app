# aws_helm_release

Deploys Helm releases into an EKS cluster, driven entirely by the `releases` map. Called directly from the environment root module (not inside golden_module) because the Helm provider must be configured at the root level with the cluster endpoint and CA certificate.
