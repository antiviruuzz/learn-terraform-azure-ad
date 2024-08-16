
# Retrieve domain information
data "azuread_domains" "default" {
  only_initial = true
}

data "azurerm_client_config" "current" {
}

data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.current.object_id  
}
data "azurerm_subscription" "primary" {
}

locals {
  domain_name = data.azuread_domains.default.domains.0.domain_name
  users       = csvdecode(file("${path.module}/users.csv"))
  cur_user_id = data.azuread_user.current_user.object_id
  tags = {
        purpose = "Skillup"
        format(
            "%s%s",
            "startdate-",
            local.cur_user_id
          ) = "16.08.24"
  }
  tags_cli_format = join(" ", [for k, v in local.tags : "${k}=${v}"])

 
}

# Create tags for manually created subscription
#Add the tags for Skillup Subscription:
#tag "purpose" with value "Skillup".
#tag "startdate-<your user object ID>" in format dd.mm.yy (eg. 17.03.23).

resource "null_resource" "tag_subscription" {
  provisioner "local-exec" {
    command = <<EOT
      az account set --subscription ${data.azurerm_subscription.primary.subscription_id}
      az tag update --resource-id /subscriptions/${data.azurerm_subscription.primary.subscription_id}  --operation merge --tags ${local.tags_cli_format}
    EOT
  }
}
#Create Entra ID users:
#Display name: admin, User principal name: admin-<your user object ID>
#Display name: dev, User principal name: dev-<your user object ID>
#Display name: guest, User principal name: guest-<your user object ID>
# Can't create users in formaat guest-<your user object ID> due to Azure policies, instead domain name should be used

resource "azuread_user" "users" {
  for_each = { for user in local.users : user.first_name => user }

  user_principal_name = format(
    "%s@%s",
    each.value.first_name,
    local.domain_name
  )

  password = format(
    "%s%s%s!",
    local.cur_user_id,
    substr(lower(each.value.first_name), 0, 2),
    length(each.value.first_name)
  )
  force_password_change = true

  display_name = each.value.first_name
  department   = each.value.department
}

#Create new app registration with name "skillup-<your user object ID>-cicd-app" with single tenant API Access.
resource "azuread_application_registration" "app" {
  display_name = format(
    "%s%s%s",
    "skillup-",
    local.cur_user_id,
    "-cicd-app"
  )
  sign_in_audience = "AzureADMyOrg"
}

#Generate new secret with Description "SkillupSubscriptionSecret" and Expiration "60 days".
resource "azuread_application_password" "pass" {
  application_id = azuread_application_registration.app.id
  display_name   = "SkillupSubscriptionSecret"
  rotate_when_changed = {
    rotation = 60
  }
}

resource "azuread_service_principal" "app_reg_sp" {
  client_id                    = azuread_application_registration.app.client_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]
}

#Create new resource group with name "skillup-<your user object ID>-rg" in location chosen before.
resource "azurerm_resource_group" "skillup_rg" {
  name     = format(
    "%s%s%s",
    "skillup-",
    local.cur_user_id,
    "-rg"
  )
  location = var.location
  tags = local.tags
}

#Assign IAM Contributor role to Entra ID App "skillup-<your user object ID>-cicd-app" on "skillup-rg".
resource "azurerm_role_assignment" "contributor_app_rg" {
  scope                = azurerm_resource_group.skillup_rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.app_reg_sp.object_id
} 
