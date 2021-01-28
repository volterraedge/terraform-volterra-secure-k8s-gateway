terraform {
  required_version = ">= 0.12.9, != 0.13.0"

  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.0.5"
    }
    aws        = "~> 3.3.0"
    null       = ">= 3.0"
    kubernetes = "~> 1.9"
    local      = ">= 2.0"
  }
}
