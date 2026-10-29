output "s3_access_key" {
  description = "Access key for application Object Storage"
  value       = yandex_iam_service_account_static_access_key.app.access_key
  sensitive   = true
}

output "s3_secret_key" {
  description = "Secret key for application Object Storage"
  value       = yandex_iam_service_account_static_access_key.app.secret_key
  sensitive   = true
}

output "lockbox_secret_id" {
  description = "ID of application Lockbox secret"
  value       = yandex_lockbox_secret.app.id
  sensitive   = true
}