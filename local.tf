locals {
  eks_subnets    = [for key, val in var.aws_subnet_eks_cidr : aws_subnet.eks[key].id]
  kubeconfig_b64 = data.local_file.kubeconfig.content_base64
  namespace      = var.volterra_namespace_exists ? join("", data.volterra_namespace.this.*.name) : join("", volterra_namespace.this.*.name)
  hipster_manifest_content = templatefile(format("%s/manifest/hipster.tpl", path.module), {
    frontend_domain_url = format("https://%s", var.app_domain)
  })
}
