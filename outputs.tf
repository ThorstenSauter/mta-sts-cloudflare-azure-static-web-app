output "deployment_token" {
  description = "The deployment token used to deploy code from CI pipelines."
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}

output "deployment_directory" {
  value       = local.content_path
  description = "The directory where the site for the MTA-STS website is synthesized."
}
