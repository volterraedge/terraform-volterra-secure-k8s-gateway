output "kubeconfig_filename" {
  description = "EKS kubeconfig file name"
  value       = module.eks.kubeconfig_filename
}

output "app_url" {
  description = "Domain VIP to access the app deployed on EKS"
  value       = var.app_domain != "" ? format("https://%s", var.app_domain) : ""
}
