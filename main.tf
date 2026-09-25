locals {
  content_path = "${path.root}/.terraform/tmp/wwwroot"
  index_hash   = data.local_file.index.content_md5
  policy_content = templatefile("${path.module}/mta-sts.tftpl", {
    mode       = var.mta_sts_mode,
    mx_records = var.mx_hosts,
    max_age    = var.policy_lifetime
  })
  policy_id       = md5(local.policy_content)
  policy_path     = "${local.content_path}/.well-known/mta-sts.txt"
  swa_cli_package = "@azure/static-web-apps-cli@2.0.10"
}

data "local_file" "index" {
  filename = "${path.module}/index.html"
}

resource "local_file" "index" {
  content  = file("${path.module}/index.html")
  filename = "${local.content_path}/index.html"
}

resource "local_file" "rendered_template" {
  content  = local.policy_content
  filename = local.policy_path
}

data "cloudflare_zone" "this" {
  filter = {
    name = var.domain
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.azure_resource_group_name
  location = var.azure_location
  tags     = var.azure_tags
}

resource "azurerm_static_web_app" "main" {
  name                = var.azure_static_web_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_tier            = var.azure_static_web_app_sku
  sku_size            = var.azure_static_web_app_sku
  tags                = var.azure_tags
  lifecycle {
    ignore_changes = [
      repository_branch,
      repository_token,
      repository_url
    ]
  }
}

resource "azurerm_static_web_app_custom_domain" "primary" {
  static_web_app_id = azurerm_static_web_app.main.id
  domain_name       = time_sleep.record_creation.triggers["domain_name"]
  validation_type   = "cname-delegation"
}

resource "cloudflare_dns_record" "mta_sts" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "mta-sts.${data.cloudflare_zone.this.name}"
  type    = "CNAME"
  content = azurerm_static_web_app.main.default_host_name
  ttl     = 1
  comment = "MTA-STS policy hosting site"
}

resource "time_sleep" "record_creation" {
  create_duration = var.wait_for_dns_propagation
  triggers = {
    domain_name = cloudflare_dns_record.mta_sts.name
  }
}

resource "cloudflare_dns_record" "mta_sts_policy" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "_mta-sts.${data.cloudflare_zone.this.name}"
  type    = "TXT"
  content = "v=STSv1; id=${local.policy_id};"
  ttl     = 1
  comment = "Indicates a MTA-STS policy being present for this domain"
}

resource "cloudflare_dns_record" "smtp_tls" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "_smtp._tls.${data.cloudflare_zone.this.name}"
  type    = "TXT"
  content = "v=TLSRPTv1; rua=${join(",", var.rua)}"
  ttl     = 1
  comment = "TLS reporting addresses"
}

resource "terraform_data" "deploy_content" {
  triggers_replace = {
    index_hash = local.index_hash
    policy_id  = local.policy_id
  }

  depends_on = [
    azurerm_static_web_app_custom_domain.primary,
    local_file.index,
    local_file.rendered_template
  ]

  provisioner "local-exec" {
    command = join(" ", [
      "npx --yes ${local.swa_cli_package}",
      "deploy \"${abspath(local.content_path)}\"",
      "--env production",
    ])
    environment = {
      SWA_CLI_DEPLOYMENT_TOKEN = azurerm_static_web_app.main.api_key
    }
  }
}
