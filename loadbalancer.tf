data "volterra_namespace" "this" {
  count = var.volterra_namespace_exists && !var.eks_only ? 1 : 0
  name  = var.volterra_namespace
}

resource "volterra_namespace" "this" {
  count = var.volterra_namespace_exists || var.eks_only ? 0 : 1
  name  = var.volterra_namespace
}

resource "volterra_origin_pool" "this" {
  for_each               = toset(var.eks_only ? [] : [var.skg_name])
  name                   = format("%s-server", var.skg_name)
  namespace              = local.namespace
  description            = format("Origin pool pointing to frontend k8s service running on RE's")
  loadbalancer_algorithm = "ROUND ROBIN"
  origin_servers {
    k8s_service {
      inside_network  = true
      outside_network = false
      vk8s_networks   = false
      service_name    = "frontend.default"
      site_locator {
        site {
          name      = volterra_aws_vpc_site.this[each.key].name
          namespace = "system"
        }
      }
    }
  }
  port               = 80
  no_tls             = true
  endpoint_selection = "LOCAL_PREFERRED"
}

resource "volterra_waf" "this" {
  for_each    = toset(var.eks_only ? [] : [var.skg_name])
  name        = format("%s-waf", var.skg_name)
  description = format("WAF in block mode for %s", var.skg_name)
  namespace   = local.namespace
  app_profile {
    cms       = []
    language  = []
    webserver = []
  }
  mode = "BLOCK"
  lifecycle {
    ignore_changes = [
      app_profile
    ]
  }
}

resource "volterra_http_loadbalancer" "this" {
  for_each                        = toset(var.eks_only ? [] : [var.skg_name])
  name                            = format("%s-lb", var.skg_name)
  namespace                       = local.namespace
  description                     = format("HTTPS loadbalancer object for %s origin server", var.skg_name)
  domains                         = [var.app_domain]
  advertise_on_public_default_vip = true
  default_route_pools {
    pool {
      name      = volterra_origin_pool.this[each.key].name
      namespace = local.namespace
    }
  }
  https_auto_cert {
    add_hsts      = var.enable_hsts
    http_redirect = var.enable_redirect
    no_mtls       = true
  }
  waf {
    name      = volterra_waf.this[each.key].name
    namespace = local.namespace
  }
  disable_waf                     = false
  disable_rate_limit              = true
  round_robin                     = true
  service_policies_from_namespace = true
  no_challenge                    = true
}
