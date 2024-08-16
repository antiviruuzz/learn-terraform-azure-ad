output "application_id" {
  value       = azuread_application_registration.app.id
  description = "Azure AD application id"
}

output "rg_name" {
  value       = azurerm_resource_group.skillup_rg.name
  description = "Resource group name"
}

output "user_principal_name" {
  value = data.azuread_user.current_user.user_principal_name
}