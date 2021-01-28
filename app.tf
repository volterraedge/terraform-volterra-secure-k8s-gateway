resource "volterra_discovery" "eks" {
  name        = var.skg_name
  description = "Discovery object to discover all services in eks cluster"
  namespace   = "system"
  depends_on  = [module.eks]

  where {
    site {
      ref {
        name      = volterra_aws_vpc_site.this.name
        namespace = "system"
      }
      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
    }
  }
  discovery_k8s {
    access_info {
      kubeconfig_url {
        secret_encoding_type = "EncodingNone"
        clear_secret_info {
          url = format("string:///%s", local.kubeconfig_b64)
        }
      }
      reachable = true
    }
    publish_info {
      disable = true
    }
  }
}

resource "local_file" "this_kubeconfig" {
  depends_on = [volterra_discovery.eks]
  content    = base64decode(local.kubeconfig_b64)
  filename   = format("%s/_output/kubeconfig", path.root)
}

resource "local_file" "hipster_manifest" {
  content  = local.hipster_manifest_content
  filename = format("%s/_output/hipster-adn.yaml", path.root)
}

resource "null_resource" "apply_manifest" {
  depends_on = [local_file.this_kubeconfig, local_file.hipster_manifest]
  triggers = {
    manifest_sha1 = sha1(local.hipster_manifest_content)
  }
  provisioner "local-exec" {
    command = "kubectl apply -f _output/hipster-adn.yaml"
    environment = {
      KUBECONFIG = format("%s/_output/kubeconfig", path.root)
    }
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f _output/hipster-adn.yaml --ignore-not-found=true"
    environment = {
      KUBECONFIG = format("%s/_output/kubeconfig", path.root)
    }
    on_failure = continue
  }
}
