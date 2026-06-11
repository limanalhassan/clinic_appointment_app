locals {
  config = jsondecode(file("${path.module}/configs/config.json"))

  _helm_base = merge(
    { releases = {} },
    try(jsondecode(file("${path.module}/configs/config_helm.json")), {})
  )

  helm_releases = {
    for k, v in local._helm_base.releases : k => merge(v, {
      values_yaml = file("${path.module}/../templates/helm_values/${v.values_file}")
    })
  }

}

module "dev" {
  source      = "../modules/golden_module"
  env         = local.config.env
  config_root = path.module
}

module "addons" {
  source   = "../modules/aws_helm_release"
  releases = local.helm_releases

  depends_on = [module.dev]
}

