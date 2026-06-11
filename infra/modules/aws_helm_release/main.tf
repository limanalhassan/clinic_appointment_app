resource "helm_release" "this" {
  for_each = var.releases

  name             = each.value.name
  repository       = each.value.repository
  chart            = each.value.chart
  version          = each.value.chart_version
  namespace        = each.value.namespace
  create_namespace = each.value.create_namespace
  wait             = each.value.wait
  timeout          = each.value.timeout

  values = each.value.values_yaml != null ? [each.value.values_yaml] : []
}
