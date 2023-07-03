resource "random_string" "acr" {
  length           = 6
  special          = false
  upper            = false
}

resource "azurerm_container_registry" "acr" {
  name                          = "moodlehighscale${random_string.acr.result}"
  location                      = data.azurerm_resource_group.moodle-high-scale.location
  resource_group_name           = data.azurerm_resource_group.moodle-high-scale.name
  sku                           = "Premium"
  public_network_access_enabled = false
  admin_enabled                 = false
}

resource "azurerm_role_assignment" "aks-acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.moodle-high-scale.kubelet_identity.0.object_id
}

resource "azurerm_private_endpoint" "acr" {
  name                = "moodle-acr-endpoint"
  location            = data.azurerm_resource_group.moodle-high-scale.location
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  subnet_id           = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "arc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "container-registry"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "container-registry"
  resource_group_name   = data.azurerm_resource_group.moodle-high-scale.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.moodle-high-scale.id
}