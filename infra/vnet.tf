resource "azurerm_virtual_network" "moodle-high-scale" {
  name                = "moodle-high-scale"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  location            = data.azurerm_resource_group.moodle-high-scale.location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "app" {
  name                 = "app"
  resource_group_name  = data.azurerm_resource_group.moodle-high-scale.name 
  virtual_network_name = azurerm_virtual_network.moodle-high-scale.name
  address_prefixes     = ["10.254.0.0/22"]
}

resource "azurerm_subnet" "private-endpoints" {
  name                 = "private-endpoints"
  resource_group_name  = data.azurerm_resource_group.moodle-high-scale.name 
  virtual_network_name = azurerm_virtual_network.moodle-high-scale.name
  address_prefixes     = ["10.254.4.0/24"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.moodle-high-scale.name 
  virtual_network_name = azurerm_virtual_network.moodle-high-scale.name
  address_prefixes     = ["10.254.5.0/24"]
}

resource "azurerm_subnet" "azure-database-pg" {
  name                 = "azure-database-pg"
  resource_group_name  = data.azurerm_resource_group.moodle-high-scale.name 
  virtual_network_name = azurerm_virtual_network.moodle-high-scale.name
  address_prefixes     = ["10.254.6.0/24"]
  delegation {
    name = "azdbpg"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}