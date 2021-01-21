variable "skg_name" {
  type        = string
  description = "SKG Name. Also used as a prefix in names of related resources."
}

variable "aws_access_key" {
  type        = string
  description = "AWS Access Key. Programmable API access key needed for creating the site"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Access Key. Programmable API secret access key needed for creating the site"
}

variable "aws_region" {
  type        = string
  description = "AWS Region where Site will be created"
}

variable "aws_az" {
  type        = string
  description = "AWS Availability Zone in which the site will be created"
}

variable "aws_eks_cidr" {
  type        = string
  description = "EKS CIDR"
  default     = "192.168.1.0/24"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC CIDR, that will be used to create the vpc while creating the site"
  default     = "192.168.0.0/22"
}

variable "site_disk_size" {
  type        = number
  description = "Disk size in GiB"
  default     = 80
}

variable "aws_instance_type" {
  type        = string
  description = "AWS instance type used for the Volterra site"
  default     = "t3.2xlarge"
}

variable "aws_subnet_cidr" {
  type        = map(string)
  description = "Map to hold different cidr with key as name of subnet"
  default = {
    "outside"  = "192.168.0.0/25"
    "inside"   = "192.168.0.192/26"
    "workload" = "192.168.0.128/26"
  }
}

variable "ssh_public_key" {
  type        = string
  description = "SSH Public Key"
  default     = ""
}

variable "certified_hardware" {
  type        = string
  description = "Volterra certified hardware used to create Volterra site on AWS"
  default     = "aws-byol-multi-nic-voltmesh"
}

variable "eks_port_range" {
  type        = list(string)
  description = "EKS port range to be allowed"
  default     = ["30000-32767"]
}

variable "deny_dns_list" {
  type        = list(string)
  description = "List of IP prefixes to be denied"
  default     = ["8.8.4.4/32"]
}

variable "allow_dns_list" {
  type        = list(string)
  description = "List of IP prefixes to be allowed"
  default     = ["8.8.8.8/32"]
}

variable "allow_tls_prefix_list" {
  type        = list(string)
  description = "Allow TLS prefix list"
  default     = ["gcr.io", "storage.googleapis.com", "docker.io", "docker.com", "amazonaws.com"]
}

variable "volterra_namespace_exists" {
  type        = string
  description = "Flag to create or use existing volterra namespace"
  default     = false
}

variable "volterra_namespace" {
  type        = string
  description = "Volterra app namespace where the object will be created. This cannot be system or shared ns."
}

variable "app_domain" {
  type        = string
  description = "App domain name, whose sub domain is delegated and managed by Volterra"
}

variable "enable_hsts" {
  type        = bool
  description = "Flag to enable hsts for HTTPS loadbalancer"
  default     = false
}

variable "enable_redirect" {
  type        = bool
  description = "Flag to enable http redirect to HTTPS loadbalancer"
  default     = true
}

variable "js_script_delay" {
  type        = number
  description = "Javascript challenge delay in miliseconds"
  default     = 5000
}

variable "js_cookie_expiry" {
  type        = number
  description = "Javascript cookie expiry time in seconds"
  default     = 3600
}
