data "local_file" "kubeconfig" {
  filename = module.eks.kubeconfig_filename
}
