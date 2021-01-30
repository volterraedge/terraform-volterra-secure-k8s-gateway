data "local_file" "kubeconfig" {
  depends_on = [module.eks]
  filename   = module.eks.kubeconfig_filename
}
