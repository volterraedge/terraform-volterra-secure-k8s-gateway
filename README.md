# terraform-volterra-secure-k8s-gateway

[![Lint Status](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/workflows/Lint/badge.svg)](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/actions)
[![LICENSE](https://img.shields.io/github/license/volterraedge/terraform-volterra-secure-k8s-gateway)](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/blob/main/LICENSE)

This is a terraform module to create Volterra's Secure Kubernetes Gateway usecase. Read the [Secure Kubernetes Gateway usecase guide](https://volterra.io/docs/quick-start/secure-kubernetes-gateway) to learn more.

---

## Overview

![Image of ADN Usecase](https://volterra.io/static/57304b920c496ad0c44fe148fde4d3ba/3353d/top-new.webp)

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

* Export the API certificate password as environment variable, this is needed for volterra provider to work
  ```bash
  export VES_P12_PASSWORD=<your credential password>
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
      version = "0.2.1"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = var.api_url
}

module "skg" {
  source              = "volterraedge/secure-k8s-gateway/volterra"
  version             = "0.1.3"
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
      version = "0.2.1"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = var.api_url
}

module "skg" {
  source              = "volterraedge/secure-k8s-gateway/volterra"
  version             = "0.1.4"
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
| terraform | >= 0.13.1 |
| aws | >= 3.22.0 |
| local | >= 2.0 |
| null | >= 3.0 |
| volterra | 0.2.1 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.22.0 |
| local | >= 2.0 |
| null | >= 3.0 |
| volterra | 0.2.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allow\_dns\_list | List of IP prefixes to be allowed | `list(string)` | <pre>[<br>  "8.8.8.8/32"<br>]</pre> | no |
| allow\_tls\_prefix\_list | Allow TLS prefix list | `list(string)` | <pre>[<br>  "gcr.io",<br>  "storage.googleapis.com",<br>  "docker.io",<br>  "docker.com",<br>  "amazonaws.com"<br>]</pre> | no |
| app\_domain | FQDN for the app. If you have delegated domain `prod.example.com`, then your app\_domain can be `<app_name>.prod.example.com` | `string` | n/a | yes |
| aws\_access\_key | AWS Access Key. Programmable API access key needed for creating the site | `string` | n/a | yes |
| aws\_az | AWS Availability Zone in which the site will be created | `string` | n/a | yes |
| aws\_instance\_type | AWS instance type used for the Volterra site | `string` | `"t3.2xlarge"` | no |
| aws\_region | AWS Region where Site will be created | `string` | n/a | yes |
| aws\_secret\_key | AWS Secret Access Key. Programmable API secret access key needed for creating the site | `string` | n/a | yes |
| aws\_subnet\_ce\_cidr | Map to hold different CE cidr with key as name of subnet | `map(string)` | n/a | yes |
| aws\_subnet\_eks\_cidr | Map to hold different EKS cidr with key as desired AZ on which the subnet should exist | `map(string)` | n/a | yes |
| aws\_vpc\_cidr | AWS VPC CIDR, that will be used to create the vpc while creating the site | `string` | n/a | yes |
| certified\_hardware | Volterra certified hardware used to create Volterra site on AWS | `string` | `"aws-byol-multi-nic-voltmesh"` | no |
| deny\_dns\_list | List of IP prefixes to be denied | `list(string)` | <pre>[<br>  "8.8.4.4/32"<br>]</pre> | no |
| eks\_only | Flag to enable creation of eks cluster only, other volterra objects will be created through Volterra console | `bool` | `false` | no |
| eks\_port\_range | EKS port range to be allowed | `list(string)` | <pre>[<br>  "30000-32767"<br>]</pre> | no |
| enable\_hsts | Flag to enable hsts for HTTPS loadbalancer | `bool` | `false` | no |
| enable\_redirect | Flag to enable http redirect to HTTPS loadbalancer | `bool` | `true` | no |
| js\_cookie\_expiry | Javascript cookie expiry time in seconds | `number` | `3600` | no |
| js\_script\_delay | Javascript challenge delay in miliseconds | `number` | `5000` | no |
| kubeconfig\_output\_path | Ouput file path, where the kubeconfig will be stored | `string` | `"./"` | no |
| site\_disk\_size | Disk size in GiB | `number` | `80` | no |
| skg\_name | SKG Name. Also used as a prefix in names of related resources. | `string` | n/a | yes |
| ssh\_public\_key | SSH Public Key | `string` | `""` | no |
| volterra\_namespace | Volterra app namespace where the object will be created. This cannot be system or shared ns. | `string` | n/a | yes |
| volterra\_namespace\_exists | Flag to create or use existing volterra namespace | `string` | `false` | no |
| volterra\_site\_name | Name of the existing aws vpc site, this is used only when var eks\_only set to true | `string` | `""` | no |
| vpc\_id | Name of the existing vpc id, this is used only when var eks\_only set to true | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| app\_url | Domain VIP to access the app deployed on EKS |
| kubeconfig\_filename | EKS kubeconfig file name |

