output "kubeconfig_filename" {
  description = "EKS kubeconfig file name"
  value       = module.eks.kubeconfig_filename
}

output "app_url" {
  description = "Domain VIP to access the app deployed on EKS"
  value       = format("https://%s", var.app_domain)
}
