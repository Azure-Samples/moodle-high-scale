resource "random_string" "moodle-cosmos-pgsql-password" {
  length           = 16
  special          = true
  upper            = true
  override_special = "!#$%*()-_=+[]{}:?"
}

resource "random_string" "moodle-cosmos" {
  length           = 6
  special          = false
  upper            = false
}

resource "azurerm_cosmosdb_postgresql_cluster" "moodle-cosmos-pgsql" {
  name                            = "moodle-cosmos-pgsql-${random_string.moodle-cosmos.result}"
  resource_group_name             = data.azurerm_resource_group.moodle-high-scale.name
  location                        = data.azurerm_resource_group.moodle-high-scale.location
  
  administrator_login_password    = "${random_string.moodle-cosmos-pgsql-password.result}"
  coordinator_storage_quota_in_mb = local.settings["cosmos_storage"]
  coordinator_vcore_count         = local.settings["cosmos_coordinator_vcore_count"]
  coordinator_server_edition      = local.settings["cosmos_coordinator_edition"]
  node_server_edition             = local.settings["cosmos_coordinator_edition"]
  node_count                      = 0

  coordinator_public_ip_access_enabled = false
  node_public_ip_access_enabled        = false

  preferred_primary_zone = 1

}

resource "time_sleep" "wait-for-db-master" {
  depends_on = [azurerm_cosmosdb_postgresql_cluster.moodle-cosmos-pgsql]

  create_duration = "300s"
}


resource "azurerm_resource_group_template_deployment" "moodle-cosmos-pgsql-replica" {
  count               = local.settings["cosmos_replica_count"]
  name                = "moodle-cosmos-pgsql-replica-${count.index}-${random_string.moodle-cosmos.result}"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "location" = {
      value = data.azurerm_resource_group.moodle-high-scale.location
    },
    "sourceLocation" = {
      value = data.azurerm_resource_group.moodle-high-scale.location
    },
    "apiVersion" = {
      value = "2023-03-02-preview"
    },
    "resourceId" = {
      value = azurerm_cosmosdb_postgresql_cluster.moodle-cosmos-pgsql.id
    },
    "serverGroupName" = {
      value = "moodle-cosmos-pgsql-replica-${count.index}-${random_string.moodle-cosmos.result}"
    },
    "sourceServerGroupName" = {
      value = azurerm_cosmosdb_postgresql_cluster.moodle-cosmos-pgsql.name
    }
  })
  template_content = <<TEMPLATE
{
    "$schema": "http://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "String"
        },
        "sourceLocation": {
            "type": "String"
        },
        "apiVersion": {
            "type": "String"
        },
        "resourceId": {
            "type": "String"
        },
        "serverGroupName": {
            "type": "String"
        },
        "sourceServerGroupName": {
            "type": "String"
        }
    },
    "resources": [
        {
            "type": "Microsoft.DBforPostgreSQL/serverGroupsv2",
            "apiVersion": "[parameters('apiVersion')]",
            "name": "[parameters('serverGroupName')]",
            "location": "[parameters('location')]",
            "properties": {
                "sourceServerGroupName": "[parameters('sourceServerGroupName')]",
                "sourceLocation": "[parameters('sourceLocation')]",
                "sourceResourceId": "[parameters('resourceId')]"
            }
        }
    ]
}
TEMPLATE

    depends_on = [time_sleep.wait-for-db-master]

}

resource "azurerm_private_endpoint" "moodle-cosmos-pgsql" {
  name                = "moodle-cosmos-pgsql-endpoint"
  location            = data.azurerm_resource_group.moodle-high-scale.location
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  subnet_id           = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "moodle-cosmos-pgsql"
    private_connection_resource_id = azurerm_cosmosdb_postgresql_cluster.moodle-cosmos-pgsql.id
    subresource_names              = ["coordinator"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "moodle-cosmos-pgsql"
    private_dns_zone_ids = [azurerm_private_dns_zone.moodle-cosmos-pgsql.id]
  }
}

resource "azurerm_private_endpoint" "moodle-cosmos-pgsql-replica" {
  count               = local.settings["cosmos_replica_count"]
  name                = "moodle-cosmos-pgsql-replica-endpoint-${count.index}"
  location            = data.azurerm_resource_group.moodle-high-scale.location
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  subnet_id           = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "moodle-cosmos-pgsql"
    private_connection_resource_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.moodle-high-scale.name}/providers/Microsoft.DBforPostgreSQL/serverGroupsv2/moodle-cosmos-pgsql-replica-${count.index}-${random_string.moodle-cosmos.result}"
    subresource_names              = ["coordinator"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "moodle-cosmos-pgsql"
    private_dns_zone_ids = [azurerm_private_dns_zone.moodle-cosmos-pgsql.id]
  }

  depends_on = [
    azurerm_resource_group_template_deployment.moodle-cosmos-pgsql-replica
  ]
}

resource "azurerm_private_dns_zone" "moodle-cosmos-pgsql" {
  name                = "privatelink.postgres.cosmos.azure.com"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "moodle-cosmos-pgsql" {
  name                  = "moodle-cosmos-pgsql"
  resource_group_name   = data.azurerm_resource_group.moodle-high-scale.name
  private_dns_zone_name = azurerm_private_dns_zone.moodle-cosmos-pgsql.name
  virtual_network_id    = azurerm_virtual_network.moodle-high-scale.id
}