module "mta_sts" {
  source                    = "../"
  azure_location            = "westeurope"
  azure_resource_group_name = "rg-test"
  azure_static_web_app_name = "stapp-mta-sts-example-com"
  azure_tags = {
    Environment = "test"
    Service     = "MTA-STS"
  }
  domain       = "example.com"
  mta_sts_mode = "enforce"
  mx_hosts = [
    "mx1.example.com", "mx2.example.com"
  ]
  rua = [
    "mailto:tls-report@example.com", "https://example.com/tls-report"
  ]
}
