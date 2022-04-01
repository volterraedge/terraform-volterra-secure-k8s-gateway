provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_vpc" "this" {
  id = local.vpc_id
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_vpc" "this" {
  for_each                         = toset(var.eks_only ? [] : [var.skg_name])
  cidr_block                       = var.aws_vpc_cidr
  assign_generated_ipv6_cidr_block = false
  enable_dns_support               = true
  enable_dns_hostnames             = true
  tags = {
    "Name"                                           = var.skg_name
    "usecase"                                        = "secure-k8s-gateway"
    format("kubernetes.io/cluster/%s", var.skg_name) = "shared"
  }
}

resource "aws_internet_gateway" "this" {
  for_each = toset(var.eks_only ? [] : [var.skg_name])
  vpc_id   = local.vpc_id
  tags = {
    "Name"    = var.skg_name
    "usecase" = "secure-k8s-gateway"
  }
}

resource "aws_route" "ipv6_default" {
  for_each                    = toset(var.eks_only ? [] : [var.skg_name])
  route_table_id              = data.aws_vpc.this.main_route_table_id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this[var.skg_name].id
  lifecycle {
    ignore_changes = [
      route_table_id
    ]
  }
}

resource "aws_route" "ipv4_default" {
  for_each               = toset(var.eks_only ? [] : [var.skg_name])
  route_table_id         = data.aws_vpc.this.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[var.skg_name].id
  lifecycle {
    ignore_changes = [
      route_table_id
    ]
  }
}


resource "aws_subnet" "volterra_ce" {
  for_each                = var.eks_only ? {} : var.aws_subnet_ce_cidr
  vpc_id                  = local.vpc_id
  cidr_block              = each.value
  availability_zone       = var.aws_az
  map_public_ip_on_launch = true
  tags = {
    "Name"        = format("%s-%s", var.skg_name, each.key)
    "usecase"     = "secure-k8s-gateway"
    "subnet-type" = each.key
  }
}


resource "aws_subnet" "eks" {
  depends_on              = [volterra_tf_params_action.apply_aws_vpc]
  for_each                = var.aws_subnet_eks_cidr
  vpc_id                  = local.vpc_id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = {
    "Name"                                           = format("%s-%s", var.skg_name, each.key)
    "usecase"                                        = "secure-k8s-gateway"
    format("kubernetes.io/cluster/%s", var.skg_name) = "shared"
  }
}

data "aws_security_group" "this" {
  for_each = toset(var.eks_only ? [var.skg_name] : [])
  filter {
    name   = "tag:ves.io/site_name"
    values = [var.volterra_site_name]
  }
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "volterra-node-eks-cluster-ingress" {
  for_each                 = toset(var.eks_only ? [var.skg_name] : [])
  description              = "Allow volterra node to communicate with eks cluster"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = data.aws_security_group.this[each.key].id
  to_port                  = 0
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-ingress-volterra-node" {
  description       = "Allow eks cluster to communicate with volterra node"
  from_port         = 0
  protocol          = "-1"
  security_group_id = module.eks.cluster_primary_security_group_id
  cidr_blocks       = local.inside_subnet_cidr
  to_port           = 0
  type              = "ingress"
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  # see for more info https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/17.24.0
  version         = "17.24.0"
  cluster_name    = var.skg_name
  cluster_version = "1.18"
  subnets         = local.eks_subnets

  tags = {
    Environment = "prod"
    usecase     = "secure-k8s-gateway"
  }

  vpc_id = local.vpc_id

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  kubeconfig_output_path = var.kubeconfig_output_path
  write_kubeconfig       = true
  create_eks             = true

  manage_aws_auth = false
  kubeconfig_aws_authenticator_env_variables = {
    "AWS_ACCESS_KEY_ID"     = var.aws_access_key
    "AWS_SECRET_ACCESS_KEY" = var.aws_secret_key
  }

  node_groups = {
    example = {
      desired_capacity = 1
      max_capacity     = 10
      min_capacity     = 1

      instance_type = "m5.xlarge"
      k8s_labels = {
        Environment = "prod"
        usecase     = "secure-k8s-gateway"
      }
    }
  }
}
