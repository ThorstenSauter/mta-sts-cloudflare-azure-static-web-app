terraform {
  required_version = ">= 1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.0"
    }
  }
}
