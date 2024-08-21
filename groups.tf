
#Create Entra ID users:
#Display name: admin, User principal name: admin-<your user object ID>
#Display name: dev, User principal name: dev-<your user object ID>
#Display name: guest, User principal name: guest-<your user object ID>
# Can't create users in formaat guest-<your user object ID> due to Azure policies, instead domain name should be used

resource "azuread_user" "users" {
  for_each = var.users
  
  user_principal_name = "${each.display}@${local.domain_name}"
  display_name = each.value.display
  password = format(
    "%s%s%s!",
    local.cur_user_id,
    substr(lower(each.value.display), 0, 2),
    length(each.value.display)
  )
  department   = each.value.department
}

#Create Entra ID groups: SG Admins (<your user object ID>), SG Developers (<your user object ID>), 
#SG Guests (<your user object ID>). ( for example: SG Admins (74d042d8-5c8a-4593-a2d1-0174f634015a) etc. )
#Add user admin in a group SG Admins.
#Add user dev in a group SG Developers.
#Add user guest in a group SG Guests.
#Make your Azure account as owner of the group SG Admins.
resource "azuread_group" "admins" {
  display_name = format(
    "%s%s",
    "SG Admins",
    local.cur_user_id,
  )
  #Make your Azure account as owner of the group SG Admins.
  owners           = [data.azurerm_client_config.current.object_id]
  security_enabled = true
 
    #assignable_to_role  = true
}

resource "azuread_group_member" "admins" {
  
  for_each = { for u in azuread_user.users : u.mail_nickname => u if u.department == "Admins" }
  group_object_id  = azuread_group.admins.id
  member_object_id = each.value.id
}

# Make admin user as owner of group SG Developers and SG Guests.
resource "azuread_group" "developers" {
  depends_on = [ azuread_group.admins ]
  display_name = format(
    "%s%s",
    "SG Developers",
    local.cur_user_id,
  )
  owners           = azuread_group.admins.members
  security_enabled = true  
  #assignable_to_role  = true
}

resource "azuread_group_member" "developers" {
   
  for_each = { for u in azuread_user.users : u.mail_nickname => u if u.department == "Developers" }

  group_object_id  = azuread_group.developers.id
  member_object_id = each.value.id
}

resource "azuread_group" "guests" {  
  depends_on = [ azuread_group.admins ]
  display_name = format(
    "%s%s",
    "SG Guests",
    local.cur_user_id,
  )
  owners           = azuread_group.admins.members
  security_enabled = true  
  #assignable_to_role  = true
}

resource "azuread_group_member" "guests" {
  
  for_each = { for u in azuread_user.users : u.mail_nickname => u if u.department == "Guests" }

  group_object_id  = azuread_group.guests.id
  member_object_id = each.value.id
}

#Assign Entra ID Global Reader role to the user dev.
#Assign Entra ID Global Reader role to the user guest.
#Assign Entra ID Global Administrator role to the user admin.

/* resource "azuread_directory_role" "global_reader" {
  display_name = "Global Reader"
}
resource "azuread_directory_role" "global_administrator" {
  display_name = "Global Administrator"
}
resource "azuread_directory_role_assignment" "guest_reader" {
  role_id             = azuread_directory_role.global_reader.template_id
  principal_object_id  = azuread_group.guests.object_id
}

resource "azuread_directory_role_assignment" "dev_reader" {  
  role_id             = azuread_directory_role.global_reader.template_id
  principal_object_id          = azuread_group.developers.object_id
}

resource "azuread_directory_role_assignment" "admin_admin" {
  role_id             = azuread_directory_role.global_administrator.template_id  
  principal_object_id          = azuread_group.admins.object_id
} */

# 
/* # GroupsClient.BaseClient.Post(): unexpected status 403 with OData error: Authorization_RequestDenied: Only
#│ companies who have purchased AAD Premium may perform this operation. paramName: , paramValue: ,
#│ objectType:
# So had to change to RBAC roles */
resource "azurerm_role_assignment" "guest_reader" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.guests.object_id
}

resource "azurerm_role_assignment" "dev_reader" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.developers.object_id
}

resource "azurerm_role_assignment" "admin_admin" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Owner"
  principal_id         = azuread_group.admins.object_id
}

/* Assign IAM Contributor role to Entra ID group SG Admins on "skillup-rg".
Assign IAM User Access Administrator role to Entra ID group SG Admins on "skillup-rg".
Assign IAM Reader role to Entra ID group SG Developers on "skillup-rg".
Assign IAM Reader role to Entra ID group SG Guests on the resource group "skillup-rg". */


resource "azurerm_role_assignment" "contributor_admin_rg" {
  scope                = azurerm_resource_group.skillup_rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.admins.object_id
}

resource "azurerm_role_assignment" "user_access_admin_rg" {
  scope                = azurerm_resource_group.skillup_rg.id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_group.admins.object_id
}

resource "azurerm_role_assignment" "reader_devs_rg" {
  scope                = azurerm_resource_group.skillup_rg.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.developers.object_id
}

resource "azurerm_role_assignment" "reader_guest_rg" {
  scope                = azurerm_resource_group.skillup_rg.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.guests.object_id
}