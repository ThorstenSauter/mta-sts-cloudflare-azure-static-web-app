terraform {
  required_version = ">= 1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.1"
    }
  }
}
