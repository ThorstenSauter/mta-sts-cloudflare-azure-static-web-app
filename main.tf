locals {
  content_path     = "${path.root}/.terraform/tmp/wwwroot"
  deployment_image = "mcr.microsoft.com/appsvc/staticappsclient:stable"
  index_hash       = data.local_file.index.content_md5
  policy_id        = md5("${var.domain}-${var.mta_sts_mode}-${join(",", var.mx_hosts)}-${var.policy_lifetime}")
  policy_path      = "${local.content_path}/.well-known/mta-sts.txt"
  secret_path      = "${path.root}/.terraform/tmp/secret"
}

data "local_file" "index" {
  filename = "${path.module}/index.html"
}

data "local_file" "policy_template" {
  filename = "${path.module}/mta-sts.tftpl"
}

resource "local_file" "index" {
  content  = file("${path.module}/index.html")
  filename = "${local.content_path}/index.html"
}

resource "local_file" "rendered_template" {
  content = templatefile(data.local_file.policy_template.filename, {
    mode       = var.mta_sts_mode,
    mx_records = var.mx_hosts,
    max_age    = var.policy_lifetime
  })
  filename = local.policy_path
}

data "cloudflare_zone" "this" {
  name = var.domain
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

resource "cloudflare_record" "mta_sts" {
  zone_id = data.cloudflare_zone.this.id
  name    = "mta-sts"
  type    = "CNAME"
  content = azurerm_static_web_app.main.default_host_name
  comment = "MTA-STS policy hosting site"
}

resource "time_sleep" "record_creation" {
  create_duration = var.wait_for_dns_propagation
  triggers = {
    domain_name = cloudflare_record.mta_sts.hostname
  }
}

resource "cloudflare_record" "mta_sts_policy" {
  zone_id = data.cloudflare_zone.this.id
  name    = "_mta-sts"
  type    = "TXT"
  content = "v=STSv1; id=${local.policy_id};"
  comment = "Indicates a MTA-STS policy being present for this domain"
}

resource "cloudflare_record" "smtp_tls" {
  zone_id = data.cloudflare_zone.this.id
  name    = "_smtp._tls"
  type    = "TXT"
  content = "v=TLSRPTv1; rua=${join(",", var.rua)}"
  comment = "TLS reporting addresses"
}

resource "null_resource" "deploy_content" {
  triggers = {
    index_hash = local.index_hash
    policy_id  = local.policy_id
  }

  depends_on = [
    azurerm_static_web_app_custom_domain.primary,
    local_file.index,
    local_file.rendered_template
  ]

  provisioner "local-exec" {
    command = "echo $DEPLOYMENT_TOKEN >> ${local.secret_path}"
    environment = {
      DEPLOYMENT_TOKEN = azurerm_static_web_app.main.api_key
    }
  }

  provisioner "local-exec" {
    command = join(" ", [
      "docker run",
      "-v ${abspath(local.content_path)}:/app",
      local.deployment_image,
      "/bin/staticsites/StaticSitesClient upload",
      "--app /app",
      "--skipAppBuild",
      "--skipApiBuild",
      "--apiToken $(cat ${local.secret_path})",
    ])
  }

  provisioner "local-exec" {
    command = "rm -f ${local.secret_path}"
  }
}
