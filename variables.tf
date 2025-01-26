variable "azure_location" {
  type        = string
  description = "The Azure region where the resources will be deployed."
}

variable "azure_resource_group_name" {
  type        = string
  description = "The name of the resource group the Azure Static Web App gets deployed to."
}

variable "azure_static_web_app_name" {
  type        = string
  description = "The name of the Azure Static Web App."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,40}$", var.azure_static_web_app_name))
    error_message = "The name must be only contain letters, numbers, and hyphens and not exceed 40 characters."
  }
}

variable "azure_static_web_app_sku" {
  type        = string
  description = "The SKU Name for the static web app."
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.azure_static_web_app_sku)
    error_message = "The SKU has to be one of 'Free' or 'Standard'."
  }
}

variable "azure_tags" {
  type        = map(string)
  description = "The default tags for Azure resources."
}

variable "domain" {
  type        = string
  description = "The domain name to configure the MTA-STS policy for."
  validation {
    condition     = can(regex("^[a-z0-9-]+(\\.[a-z0-9-]+)*\\.[a-z]+$", var.domain))
    error_message = "Domain name must be in the format `example.com` or a subdomain hierarchy."
  }
}

variable "mta_sts_mode" {
  type        = string
  default     = "testing"
  description = "Sending MTA policy application, see https://tools.ietf.org/html/rfc8461#section-5"

  validation {
    condition     = contains(["enforce", "testing", "none"], var.mta_sts_mode)
    error_message = "Only values of `enforce` `testing` or `none` are valid."
  }
}

variable "mx_hosts" {
  type        = list(string)
  description = "List of permitted MX hosts"

  validation {
    condition     = length(var.mx_hosts) > 0
    error_message = "At least 1 MX host has to be specified."
  }

  validation {
    condition = alltrue([
      for host in var.mx_hosts : can(regex("^^(\\*\\.)?([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}$", host))
    ])
    error_message = "Each MX host must match the pattern '*.example.com' or 'example.com'. See https://datatracker.ietf.org/doc/html/rfc8461#section-4.1"
  }
}

variable "policy_lifetime" {
  type        = number
  default     = 604800
  description = "Maximum lifetime of the policy in seconds, up to `31557600` (1 year). Defaults to `604800` (1 week)."

  validation {
    condition     = var.policy_lifetime >= 0
    error_message = "Policy lifetime must be positive."
  }

  validation {
    condition     = var.policy_lifetime <= 31557600
    error_message = "Policy lifetime must be less than `31557600` (1 year)."
  }
}

variable "rua" {
  type        = list(string)
  description = "Locations to which aggregate reports about policy violations should be sent. Each entry has to follow either the `mailto:` or `https:` schema."

  validation {
    condition     = length(var.rua) > 0
    error_message = "At least one rua endpoint has to be provided."
  }

  validation {
    condition     = can([for loc in var.rua : regex("^(mailto|https):", loc)])
    error_message = "All locations must start with either the `mailto:` or `https` schema."
  }
}

variable "wait_for_dns_propagation" {
  type        = string
  default     = "1m"
  description = "How long to wait for the DNS record to propagate before provisioning the custom domain. Takes a time duration as an input. For example, `30s` for 30 seconds or `5m` for 5 minutes. Defaults to 1 minute."

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?(ms|s|m|h)$", var.wait_for_dns_propagation))
    error_message = "The duration must be must be a number immediately followed by ms (milliseconds), s (seconds), m (minutes), or h (hours). For example, `30s` for 30 seconds."
  }
}
