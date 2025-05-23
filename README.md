﻿# MTA-STS with Cloudflare DNS and Azure Static Web App hosting

## Goal

This module aims to provision the necessary DNS records required for `MTA-STS` as described
in [RFC 8461](https://datatracker.ietf.org/doc/html/rfc8461).
It hosts the `MTA-STS` policy file on
an [Azure Static Web App](https://learn.microsoft.com/en-us/azure/static-web-apps/).

> [!IMPORTANT]  
> The module uses the `mcr.microsoft.com/appsvc/staticappsclient:stable` Docker image to deploy the static web app
> whenever changes to the policy site occur.

## Requirements

This module has a few requirements:

- The Azure provider requires the permissions to create a resource group and a static web app instance
- The Cloudflare zone for the given domain has to already exist
- The Cloudflare provider requires the following permissions
  - `zone.Read` for the specified zone
  - `zone.DNS.Edit` for the specified zone
- Docker needs to be installed on the machine running the module in order to deploy the Azure Static Web App content

## Provisioned resources

### Azure

- `azurerm_resource_group` - The resource group to host the static web app
- `azurerm_static_web_app` - The static web app instance hosting the `MTA-STS` policy file
- `azurerm_static_web_app_custom_domain` - The custom domain pointing to the `mta-sts` subdomain for the static web app

### Cloudflare

- `cloudflare_record` - The record for the `MTA-STS` policy, `TLS-RPT`, and the `mta-sts` subdomain

### Local files

- `${outputs.site_content_path}/.well-known/mta-sts.txt` - The `MTA-STS` policy file
- `${outputs.site_content_path}/index.html` - A generic index file for the static web app

## Example

An example of how to use this module is available in the [example](./example) directory.

## Module documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.13.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.5 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | ~> 0.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_static_web_app.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/static_web_app) | resource |
| [azurerm_static_web_app_custom_domain.primary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/static_web_app_custom_domain) | resource |
| [cloudflare_dns_record.mta_sts](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_dns_record.mta_sts_policy](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_dns_record.smtp_tls](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [local_file.index](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.rendered_template](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [terraform_data.deploy_content](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.record_creation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [cloudflare_zone.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |
| [local_file.index](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [local_file.policy_template](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | The Azure region where the resources will be deployed. | `string` | n/a | yes |
| <a name="input_azure_resource_group_name"></a> [azure\_resource\_group\_name](#input\_azure\_resource\_group\_name) | The name of the resource group the Azure Static Web App gets deployed to. | `string` | n/a | yes |
| <a name="input_azure_static_web_app_name"></a> [azure\_static\_web\_app\_name](#input\_azure\_static\_web\_app\_name) | The name of the Azure Static Web App. | `string` | n/a | yes |
| <a name="input_azure_static_web_app_sku"></a> [azure\_static\_web\_app\_sku](#input\_azure\_static\_web\_app\_sku) | The SKU Name for the static web app. | `string` | `"Free"` | no |
| <a name="input_azure_tags"></a> [azure\_tags](#input\_azure\_tags) | The default tags for Azure resources. | `map(string)` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | The domain name to configure the MTA-STS policy for. | `string` | n/a | yes |
| <a name="input_mta_sts_mode"></a> [mta\_sts\_mode](#input\_mta\_sts\_mode) | Sending MTA policy application, see https://tools.ietf.org/html/rfc8461#section-5 | `string` | `"testing"` | no |
| <a name="input_mx_hosts"></a> [mx\_hosts](#input\_mx\_hosts) | List of permitted MX hosts | `list(string)` | n/a | yes |
| <a name="input_policy_lifetime"></a> [policy\_lifetime](#input\_policy\_lifetime) | Maximum lifetime of the policy in seconds, up to `31557600` (1 year). Defaults to `604800` (1 week). | `number` | `604800` | no |
| <a name="input_rua"></a> [rua](#input\_rua) | Locations to which aggregate reports about policy violations should be sent. Each entry has to follow either the `mailto:` or `https:` schema. | `list(string)` | n/a | yes |
| <a name="input_wait_for_dns_propagation"></a> [wait\_for\_dns\_propagation](#input\_wait\_for\_dns\_propagation) | How long to wait for the DNS record to propagate before provisioning the custom domain. Takes a time duration as an input. For example, `30s` for 30 seconds or `5m` for 5 minutes. Defaults to 1 minute. | `string` | `"1m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployment_directory"></a> [deployment\_directory](#output\_deployment\_directory) | The directory where the site for the MTA-STS website is synthesized. |
| <a name="output_deployment_token"></a> [deployment\_token](#output\_deployment\_token) | The deployment token used to deploy code from CI pipelines. |
<!-- END_TF_DOCS -->
