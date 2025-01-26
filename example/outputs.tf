output "deployment_token" {
  value       = module.mta_sts.deployment_token
  description = "The deployment token used to deploy code from CI pipelines."
  sensitive   = true
}
