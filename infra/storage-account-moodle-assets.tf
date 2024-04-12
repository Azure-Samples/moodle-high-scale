resource "random_string" "storage-account-moodle-assets" {
  length           = 6
  special          = false
  upper            = false
}

resource "azurerm_storage_account" "moodle-assets" {
  name                     = "moodleassets${random_string.storage-account.result}"
  resource_group_name      = data.azurerm_resource_group.moodle-high-scale.name
  location                 = data.azurerm_resource_group.moodle-high-scale.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

resource "azurerm_storage_container" "moodle-assets" {
  name                  = "moodle-assets"
  storage_account_name  = azurerm_storage_account.moodle-assets.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "config" {
  name                  = "config"
  storage_account_name  = azurerm_storage_account.moodle-assets.name
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "moodle-assets" {
  name                = "moodle-assets"
  location            = data.azurerm_resource_group.moodle-high-scale.location
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  subnet_id           = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "data.azurerm_resource_group.moodle-high-scale.location"
    private_connection_resource_id = azurerm_storage_account.moodle-assets.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage-blob.id]
  }
}

resource "azurerm_private_dns_zone" "storage-blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage-blob" {
  name                  = "storage-blob"
  resource_group_name   = data.azurerm_resource_group.moodle-high-scale.name
  private_dns_zone_name = azurerm_private_dns_zone.storage-blob.name
  virtual_network_id    = azurerm_virtual_network.moodle-high-scale.id
}

data "azurerm_storage_account_blob_container_sas" "sastoken" {
  connection_string = azurerm_storage_account.moodle-assets.primary_connection_string
  container_name    = azurerm_storage_container.moodle-assets.name
  https_only        = true

  start  = formatdate("YYYY-MM-DD", timestamp())
  expiry = formatdate("YYYY-MM-DD", timeadd(timestamp(), "8760h")) 

  permissions {
    read   = true
    add    = false
    create = false
    write  = true
    delete = false
    list   = false
  }

}