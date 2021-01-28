# terraform-volterra-secure-k8s-gateway

[![Lint Status](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/workflows/Lint/badge.svg)](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/actions)
[![LICENSE](https://img.shields.io/github/license/volterraedge/terraform-volterra-secure-k8s-gateway)](https://github.com/volterraedge/terraform-volterra-secure-k8s-gateway/blob/main/LICENSE)

This is a terraform module to create Volterra's Secure Kubernetes Gateway usecase. Read the [Secure Kubernetes Gateway usecase guide](https://volterra.io/docs/quick-start/secure-kubernetes-gateway) to learn more.

---

## Assumptions:

* You already have signed up for Volterra account. If not, use this link to [signup](https://console.ves.volterra.io/signup/)

* You already have an AWS account and have downloaded [Programmatic Access Credentials](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)

---

* Install terraform

  For homebrew installed on macos, run below command to install terraform. For rest of the os follow the instructions from [this link](https://learn.hashicorp.com/tutorials/terraform/install-cli) to install terraform

  ```bash
  $ brew tap hashicorp/tap
  $ brew install hashicorp/tap/terraform

  # to update
  $ brew upgrade hashicorp/tap/terraform
  ```

* Download Volterra API credentials file

  Follow the steps under section `Generate API Certificate` from [how to manage credentials doc](https://volterra.io/docs/how-to/user-mgmt/credentials)


* Export the API certificate password as environment variable

  ```bash
  export VES_P12_PASSWORD=<your credential password>
  ```

* Setup domain delegation

  Follow steps from this [link](https://volterra.io/docs/how-to/app-networking/domain-delegation) to create domain delegation.

* Follow this [link](https://volterra.io/docs/reference/cloud-cred-ref/aws-vpc-cred-ref) to add permission for AWS IAM user. You may need to contact your IAM admin to do this.

---

## Usage Example

```hcl
terraform {
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.0.5"
    }
  }
}

variable "api_url" {
  default = "https://acmecorp.console.ves.volterra.io/api"
}

variable "api_p12_file" {
  default = "acmecorp.console.api-creds.p12"
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = var.api_url
}

variable "aws_access_key" {}

variable "aws_secret_key" {}

terraform {
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.0.5"
    }
  }
}

provider "volterra" {
  api_p12_file = var.api_p12_file
  url          = var.api_url
}

module "skg" {
  source             = "volterraedge/secure-k8s-gateway/volterra"
  version            = "0.0.1"
  skg_name           = "module-skg-test"
  volterra_namespace = "module-skg-test"
  app_domain         = "module-skg-test.adn.helloclouds.app"
  aws_secret_key     = var.aws_secret_key
  aws_access_key     = var.aws_access_key
  aws_region         = "us-east-2"
  aws_az             = "us-east-2a"
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
| terraform | >= 0.12.9, != 0.13.0 |
| aws | ~> 3.3.0 |
| kubernetes | ~> 1.9 |
| local | >= 2.0 |
| null | >= 3.0 |
| volterra | 0.0.5 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.3.0 |
| local | >= 2.0 |
| null | >= 3.0 |
| volterra | 0.0.5 |

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
| aws\_subnet\_ce\_cidr | Map to hold different CE cidr with key as name of subnet | `map(string)` | <pre>{<br>  "inside": "192.168.0.192/26",<br>  "outside": "192.168.0.0/25",<br>  "workload": "192.168.0.128/26"<br>}</pre> | no |
| aws\_subnet\_eks\_cidr | Map to hold different EKS cidr with key as desired AZ on which the subnet should exist | `map(string)` | <pre>{<br>  "us-east-2a": "192.168.1.0/25",<br>  "us-east-2b": "192.168.1.128/25"<br>}</pre> | no |
| aws\_vpc\_cidr | AWS VPC CIDR, that will be used to create the vpc while creating the site | `string` | `"192.168.0.0/22"` | no |
| certified\_hardware | Volterra certified hardware used to create Volterra site on AWS | `string` | `"aws-byol-multi-nic-voltmesh"` | no |
| deny\_dns\_list | List of IP prefixes to be denied | `list(string)` | <pre>[<br>  "8.8.4.4/32"<br>]</pre> | no |
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

## Outputs

| Name | Description |
|------|-------------|
| app\_url | Domain VIP to access the app deployed on EKS |
| kubeconfig\_filename | EKS kubeconfig file name |

