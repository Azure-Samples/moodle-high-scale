resource "random_string" "moodle-db" {
  length           = 6
  special          = false
  upper            = false
}

resource "random_string" "moodle-db-password" {
  length           = 16
  special          = true
  upper            = true
  override_special = "!#$%*()-_=+[]{}:?"
}

resource "azurerm_postgresql_flexible_server" "moodle-db" {
  name                   = "moodle-db-pgsql-${random_string.moodle-db.result}"
  resource_group_name    = data.azurerm_resource_group.moodle-high-scale.name
  location               = data.azurerm_resource_group.moodle-high-scale.location
  version                = local.settings["azure_database_version"]
  delegated_subnet_id    = azurerm_subnet.azure-database-pg.id
  private_dns_zone_id    = azurerm_private_dns_zone.moodle-cosmos-pgsql.id
  administrator_login    = "psqladmin"
  administrator_password = "${random_string.moodle-db-password.result}"
  zone                   = "1"

  storage_mb = local.settings["azure_database_storage"]
  sku_name   = local.settings["azure_database_sku"]

}
resource "azurerm_postgresql_flexible_server_database" "moodle" {
  name      = "moodle"
  server_id = azurerm_postgresql_flexible_server.moodle-db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server" "moodle-db-read-replica" {
  name                   = "moodle-db-pgsql-read-${random_string.moodle-db.result}"
  resource_group_name    = data.azurerm_resource_group.moodle-high-scale.name
  location               = data.azurerm_resource_group.moodle-high-scale.location
  version                = local.settings["azure_database_version"]
  delegated_subnet_id    = azurerm_subnet.azure-database-pg.id
  private_dns_zone_id    = azurerm_private_dns_zone.moodle-cosmos-pgsql.id
  sku_name               = local.settings["azure_database_read_replica_sku"]
  create_mode            = "Replica"  # Set as a read replica
  source_server_id       = azurerm_postgresql_flexible_server.moodle-db.id
  administrator_login    = "psqladmin"
  administrator_password = "${random_string.moodle-db-password.result}"
  zone                   = "1"
}

resource "azurerm_private_dns_zone" "moodle-cosmos-pgsql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "moodle-pgsql" {
  name = "moodle-pgsql"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  private_dns_zone_name = azurerm_private_dns_zone.moodle-cosmos-pgsql.name
  virtual_network_id = azurerm_virtual_network.moodle-high-scale.id
}