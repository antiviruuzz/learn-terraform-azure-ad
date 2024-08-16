# Create Virtual Network with name "skillup-vnet" and IP address range "172.22.0.0 - 172.22.3.255".
# Create Network Security Group with name "skillup-nsg".
# Create subnets and associate with Network Security Group "skillup-nsg":
# subnet with name "primary-snet" and IP address range "172.22.0.0 - 172.22.1.255".
# subnet with name "webapps-snet" and IP address range "172.22.2.0 - 172.22.2.255"
resource "azurerm_network_security_group" "skillup_nsg" {
  name                = "skillup-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.skillup_rg.name
}
resource "azurerm_virtual_network" "skillup_vnet" {
  name                = "skillup-vnet"
  address_space       = ["172.22.0.0/22"]
  location            = var.location
  resource_group_name = azurerm_resource_group.skillup_rg.name


  subnet {
    name           = "primary-snet1"
    address_prefix = "172.22.0.0/23"
    security_group = azurerm_network_security_group.skillup_nsg.id
  }

  subnet {
    name           = "webapps-snet"
    address_prefix = "172.22.2.0/24"
    security_group = azurerm_network_security_group.skillup_nsg.id
  }
}

# Create Application Security Group:
# ASG for domain controllers with name "dc-asg"
# ASG for webservers with name "ws-asg"
# ASG for sqlservers with name "sql-asg"
resource "azurerm_application_security_group" "dc_asg" {
  name                = "dc-asg"
  location            = var.location
  resource_group_name = azurerm_resource_group.skillup_rg.name
}
resource "azurerm_application_security_group" "ws_asg" {
  name                = "ws-asg"
  location            = var.location
  resource_group_name = azurerm_resource_group.skillup_rg.name
}
resource "azurerm_application_security_group" "sql_asg" {
  name                = "sql-asg"
  location            = var.location
  resource_group_name = azurerm_resource_group.skillup_rg.name
}