resource "random_string" "moodle-log-analytics" {
  length           = 6
  special          = false
  upper            = false
}

resource "azurerm_log_analytics_workspace" "moodle-high-scale" {
  name                = "moodle-high-scale-${random_string.moodle-log-analytics.result}"
  location            = data.azurerm_resource_group.moodle-high-scale.location
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}