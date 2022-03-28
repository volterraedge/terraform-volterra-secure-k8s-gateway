# terraform-volterra-secure-k8s-gateway

[![Lint Status](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/workflows/Lint/badge.svg)](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/actions)
[![LICENSE](https://img.shields.io/github/license/volterraedge/terraform-volterra-secure-k8s-gateway)](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/blob/main/LICENSE)

This is a terraform module to create Volterra's Secure Kubernetes Gateway usecase. Read the [Secure Kubernetes Gateway usecase guide](https://volterra.io/docs/quick-start/secure-kubernetes-gateway) to learn more.

---

## Overview

![Image of Secure Kubernetes Gateway Usecase](https://docs.cloud.f5.com/docs/static/79e24ec420bc9193d158d20fcb23ac27/1631d/seq.webp)

---

## Prerequisites:

### AWS Account

* AWS Programmatic access credentials

  You should already have a user create in AWS account and have already have [aws programmatic access credentials](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) for the user.

* AWS IAM Policy for the user

  Follow this [link](https://volterra.io/docs/reference/cloud-cred-ref/aws-vpc-cred-ref) to add permission for AWS IAM user. You may need to contact your IAM admin to do this.

### Volterra Account

* Signup For Volterra Account

  If you don't have a Volterra account. Please follow this link to [signup](https://console.ves.volterra.io/signup/)

* Download Volterra API credentials file

  Follow [how to generate API Certificate](https://volterra.io/docs/how-to/user-mgmt/credentials) to create API credentials

* Setup domain delegation

  Follow steps from this [link](https://volterra.io/docs/how-to/app-networking/domain-delegation) to create domain delegation.

### Command Line Tools

* Install terraform

  For homebrew installed on macos, run below command to install terraform. For rest of the os follow the instructions from [this link](https://learn.hashicorp.com/tutorials/terraform/install-cli) to install terraform

  ```bash
  $ brew tap hashicorp/tap
  $ brew install hashicorp/tap/terraform

  # to update
  $ brew upgrade hashicorp/tap/terraform
  ```

* Install Kubectl

  Please follow this [doc](https://kubernetes.io/docs/tasks/tools/install-kubectl/) to install kubectl

* Install aws-iam-authenticator

  Please follow this [doc](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) to install aws-iam-authenticator

* Export the API certificate password, path to your local p12 file and your api url as environment variables, this is needed for volterra provider to work
  ```bash
  export VES_P12_PASSWORD=<your credential password>
  export VOLT_API_P12_FILE=<path to your local p12 file>
  export VOLT_API_URL=<team or org tenant api url>
  ```

---

## Usage Example

### Completely automated scenario, where all volterra object and eks objects are created by the module

```hcl
variable "api_url" {
  #--- UNCOMMENT FOR TEAM OR ORG TENANTS
  # default = "https://<TENANT-NAME>.console.ves.volterra.io/api"
  #--- UNCOMMENT FOR INDIVIDUAL/FREEMIUM
  # default = "https://console.ves.volterra.io/api"
}

# This points the absolute path of the api credentials file you downloaded from Volterra
variable "api_p12_file" {
  default = "path/to/your/api-creds.p12"
}

# Below is an option to pass access key and secret key as you probably don't want to save it in a file
# Use env variable before you run `terraform apply` command
# export TF_VAR_aws_access_key=<your aws access key>
# export TF_VAR_aws_secret_key=<your aws secret key>
variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {
  default = "us-east-2"
}

variable "aws_az" {
  default = "us-east-2a"
}

variable "namespace" {
  default = ""
}

variable "name" {}

variable "app_fqdn" {}

# This is the VPC CIDR for AWS
variable "aws_vpc_cidr" {
  default = "192.168.0.0/22"
}

# Map to hold different CE CIDR, if you are not using default aws_vpc_cidr then you need to change the below map as well
variable "aws_subnet_ce_cidr" {
  default = {
    "outside"  = "192.168.0.0/25"
    "inside"   = "192.168.0.192/26"
    "workload" = "192.168.0.128/26"
  }
}

# Map to hold different EKS cidr with key as desired AZ on which the subnet should exist
variable "aws_subnet_eks_cidr" {
  default = {
    "us-east-2a" = "192.168.1.0/25"
    "us-east-2b" = "192.168.1.128/25"
  }
}

locals{
  namespace = var.namespace != "" ? var.namespace : var.name
}

terraform {
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.11.5"
    }
  }
}

module "skg" {
  source              = "volterraedge/secure-k8s-gateway/volterra"
  skg_name            = var.name
  volterra_namespace  = local.namespace
  app_domain          = var.app_fqdn
  aws_secret_key      = var.aws_secret_key
  aws_access_key      = var.aws_access_key
  aws_region          = var.aws_region
  aws_az              = var.aws_az
  aws_vpc_cidr        = var.aws_vpc_cidr
  aws_subnet_ce_cidr  = var.aws_subnet_ce_cidr
  aws_subnet_eks_cidr = var.aws_subnet_eks_cidr
}

output "kubeconfig_filename" {
  value = module.skg.kubeconfig_filename
}

output "app_url" {
  value = module.skg.app_url
}
```

### EKS related objects are only created by this module

```hcl
variable "api_url" {
  #--- UNCOMMENT FOR TEAM OR ORG TENANTS
  # default = "https://<TENANT-NAME>.console.ves.volterra.io/api"
  #--- UNCOMMENT FOR INDIVIDUAL/FREEMIUM
  # default = "https://console.ves.volterra.io/api"
}

# This points the absolute path of the api credentials file you downloaded from Volterra
variable "api_p12_file" {
  default = "path/to/your/api-creds.p12"
}

# Below is an option to pass access key and secret key as you probably don't want to save it in a file
# Use env variable before you run `terraform apply` command
# export TF_VAR_aws_access_key=<your aws access key>
# export TF_VAR_aws_secret_key=<your aws secret key>
variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {
  default = "us-east-2"
}

variable "aws_az" {
  default = "us-east-2a"
}

variable "namespace" {
  default = ""
}

variable "name" {}

variable "aws_vpc_cidr" {
  default = ""
}

variable "aws_subnet_ce_cidr" {
  default = {}
}

# Map to hold different EKS cidr with key as desired AZ on which the subnet should exist
variable "aws_subnet_eks_cidr" {
  default = {
    "us-east-2a" = "192.168.1.0/25"
    "us-east-2b" = "192.168.1.128/25"
  }
}

# Existing volterra site name
variable "volterra_site_name" {}

# Existing AWS VPC Id
variable "vpc_id" {}

locals{
  namespace = var.namespace != "" ? var.namespace : var.name
}

terraform {
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.11.5"
    }
  }
}

module "skg" {
  source              = "volterraedge/secure-k8s-gateway/volterra"
  skg_name            = var.name
  volterra_namespace  = local.namespace
  app_domain          = ""
  aws_secret_key      = var.aws_secret_key
  aws_access_key      = var.aws_access_key
  aws_region          = var.aws_region
  aws_az              = var.aws_az
  aws_vpc_cidr        = var.aws_vpc_cidr
  aws_subnet_ce_cidr  = var.aws_subnet_ce_cidr
  aws_subnet_eks_cidr = var.aws_subnet_eks_cidr
  eks_only            = true
  volterra_site_name  = var.volterra_site_name
  vpc_id              = var.vpc_id

}

output "kubeconfig_filename" {
  value = module.skg.kubeconfig_filename
}

output "app_url" {
  value = module.skg.app_url
}
```
---

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.22.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |
| <a name="requirement_volterra"></a> [volterra](#requirement\_volterra) | >= 0.11.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.22.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0 |
| <a name="provider_volterra"></a> [volterra](#provider\_volterra) | >= 0.11.5 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 17.24.0 |

## Resources

| Name | Type |
|------|------|
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route.ipv4_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.ipv6_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_security_group_rule.eks-cluster-ingress-volterra-node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.volterra-node-eks-cluster-ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.volterra_ce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [local_file.hipster_manifest](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.this_kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.apply_manifest](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.create_namespace](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_aws_mns](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [volterra_app_firewall.this](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/app_firewall) | resource |
| [volterra_aws_vpc_site.this](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/aws_vpc_site) | resource |
| [volterra_cloud_credentials.this](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/cloud_credentials) | resource |
| [volterra_discovery.eks](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/discovery) | resource |
| [volterra_forward_proxy_policy.this](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/forward_proxy_policy) | resource |
| [volterra_http_loadbalancer.this](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/http_loadbalancer) | resource |
| [volterra_namespace.this](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/namespace) | resource |
| [volterra_network_policy_view.sli](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/network_policy_view) | resource |
| [volterra_network_policy_view.slo](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/network_policy_view) | resource |
| [volterra_origin_pool.this](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/origin_pool) | resource |
| [volterra_tf_params_action.apply_aws_vpc](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/resources/tf_params_action) | resource |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [local_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [volterra_namespace.this](https://registry.terraform.io/providers/volterraedge/volterra/latest/docs/data-sources/namespace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_dns_list"></a> [allow\_dns\_list](#input\_allow\_dns\_list) | List of IP prefixes to be allowed | `list(string)` | <pre>[<br>  "8.8.8.8/32"<br>]</pre> | no |
| <a name="input_allow_tls_prefix_list"></a> [allow\_tls\_prefix\_list](#input\_allow\_tls\_prefix\_list) | Allow TLS prefix list | `list(string)` | <pre>[<br>  "gcr.io",<br>  "storage.googleapis.com",<br>  "docker.io",<br>  "docker.com",<br>  "amazonaws.com"<br>]</pre> | no |
| <a name="input_app_domain"></a> [app\_domain](#input\_app\_domain) | FQDN for the app. If you have delegated domain `prod.example.com`, then your app\_domain can be `<app_name>.prod.example.com` | `string` | n/a | yes |
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | AWS Access Key. Programmable API access key needed for creating the site | `string` | n/a | yes |
| <a name="input_aws_az"></a> [aws\_az](#input\_aws\_az) | AWS Availability Zone in which the site will be created | `string` | n/a | yes |
| <a name="input_aws_instance_type"></a> [aws\_instance\_type](#input\_aws\_instance\_type) | AWS instance type used for the Volterra site | `string` | `"t3.2xlarge"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region where Site will be created | `string` | n/a | yes |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | AWS Secret Access Key. Programmable API secret access key needed for creating the site | `string` | n/a | yes |
| <a name="input_aws_subnet_ce_cidr"></a> [aws\_subnet\_ce\_cidr](#input\_aws\_subnet\_ce\_cidr) | Map to hold different CE cidr with key as name of subnet | `map(string)` | n/a | yes |
| <a name="input_aws_subnet_eks_cidr"></a> [aws\_subnet\_eks\_cidr](#input\_aws\_subnet\_eks\_cidr) | Map to hold different EKS cidr with key as desired AZ on which the subnet should exist | `map(string)` | n/a | yes |
| <a name="input_aws_vpc_cidr"></a> [aws\_vpc\_cidr](#input\_aws\_vpc\_cidr) | AWS VPC CIDR, that will be used to create the vpc while creating the site | `string` | n/a | yes |
| <a name="input_certified_hardware"></a> [certified\_hardware](#input\_certified\_hardware) | Volterra certified hardware used to create Volterra site on AWS | `string` | `"aws-byol-multi-nic-voltmesh"` | no |
| <a name="input_deny_dns_list"></a> [deny\_dns\_list](#input\_deny\_dns\_list) | List of IP prefixes to be denied | `list(string)` | <pre>[<br>  "8.8.4.4/32"<br>]</pre> | no |
| <a name="input_eks_only"></a> [eks\_only](#input\_eks\_only) | Flag to enable creation of eks cluster only, other volterra objects will be created through Volterra console | `bool` | `false` | no |
| <a name="input_eks_port_range"></a> [eks\_port\_range](#input\_eks\_port\_range) | EKS port range to be allowed | `list(string)` | <pre>[<br>  "30000-32767"<br>]</pre> | no |
| <a name="input_enable_hsts"></a> [enable\_hsts](#input\_enable\_hsts) | Flag to enable hsts for HTTPS loadbalancer | `bool` | `false` | no |
| <a name="input_enable_redirect"></a> [enable\_redirect](#input\_enable\_redirect) | Flag to enable http redirect to HTTPS loadbalancer | `bool` | `true` | no |
| <a name="input_js_cookie_expiry"></a> [js\_cookie\_expiry](#input\_js\_cookie\_expiry) | Javascript cookie expiry time in seconds | `number` | `3600` | no |
| <a name="input_js_script_delay"></a> [js\_script\_delay](#input\_js\_script\_delay) | Javascript challenge delay in miliseconds | `number` | `5000` | no |
| <a name="input_kubeconfig_output_path"></a> [kubeconfig\_output\_path](#input\_kubeconfig\_output\_path) | Ouput file path, where the kubeconfig will be stored | `string` | `"./"` | no |
| <a name="input_site_disk_size"></a> [site\_disk\_size](#input\_site\_disk\_size) | Disk size in GiB | `number` | `80` | no |
| <a name="input_skg_name"></a> [skg\_name](#input\_skg\_name) | SKG Name. Also used as a prefix in names of related resources. | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH Public Key | `string` | `""` | no |
| <a name="input_volterra_namespace"></a> [volterra\_namespace](#input\_volterra\_namespace) | Volterra app namespace where the object will be created. This cannot be system or shared ns. | `string` | n/a | yes |
| <a name="input_volterra_namespace_exists"></a> [volterra\_namespace\_exists](#input\_volterra\_namespace\_exists) | Flag to create or use existing volterra namespace | `string` | `false` | no |
| <a name="input_volterra_site_name"></a> [volterra\_site\_name](#input\_volterra\_site\_name) | Name of the existing aws vpc site, this is used only when var eks\_only set to true | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Name of the existing vpc id, this is used only when var eks\_only set to true | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_url"></a> [app\_url](#output\_app\_url) | Domain VIP to access the app deployed on EKS |
| <a name="output_kubeconfig_filename"></a> [kubeconfig\_filename](#output\_kubeconfig\_filename) | EKS kubeconfig file name |
