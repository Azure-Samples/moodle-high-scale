resource "azurerm_kubernetes_cluster" "moodle-high-scale" {
  name                = "moodle-high-scale"
  dns_prefix          = "moodle-high-scale"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  location            = data.azurerm_resource_group.moodle-high-scale.location
  sku_tier            = local.settings["aks_sku_tier"]

  role_based_access_control_enabled = true

  auto_scaler_profile {
    max_unready_nodes      = 200
    max_unready_percentage = 95
    expander               = "most-pods"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.moodle-high-scale.id
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = local.settings["aks_system_nodepool_vmsize"]
    only_critical_addons_enabled = true
    enable_auto_scaling          = true
    min_count                    = 2
    max_count                    = 4
    os_disk_type                 = local.settings["aks_os_disk_type"]
    vnet_subnet_id               = azurerm_subnet.app.id
    zones                        = [1]
  }

  network_profile {
    network_plugin      = "azure"
    service_cidr        = "172.29.100.0/24"
    dns_service_ip      = "172.29.100.10"
    network_plugin_mode = "Overlay"
  }

  storage_profile {
    blob_driver_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      network_profile,
    ]
  }

}

resource "azurerm_kubernetes_cluster_node_pool" "moodle-high-scale-app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.moodle-high-scale.id
  vm_size               = local.settings["aks_app_nodepool_vmsize"]
  priority              = local.settings["aks_nodepool_priority"]
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 100
  max_pods              = 250
  mode                  = "User"
  os_disk_type          = local.settings["aks_os_disk_type"]
  vnet_subnet_id        = azurerm_subnet.app.id
  zones                 = [1]
  eviction_policy       = local.settings["aks_nodepool_priority"] == "Spot" ? "Delete" : null
  node_taints           = local.settings["aks_nodepool_priority"] == "Spot" ? [ "kubernetes.azure.com/scalesetpriority=spot:NoSchedule", "workload-type=app:NoSchedule" ] : [ "workload-type=app:NoSchedule" ]
  node_labels           = local.settings["aks_nodepool_priority"] == "Spot" ? { "kubernetes.azure.com/scalesetpriority" = "spot" } : null       
}

resource "azurerm_kubernetes_cluster_node_pool" "moodle-high-scale-jobs" {
  name                  = "jobs"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.moodle-high-scale.id
  vm_size               = local.settings["aks_jobs_nodepool_vmsize"]
  priority              = local.settings["aks_nodepool_priority"]
  node_count            = 1
  max_pods              = 30
  mode                  = "User"
  os_disk_type          = local.settings["aks_os_disk_type"]
  vnet_subnet_id        = azurerm_subnet.app.id
  zones                 = [1]
  eviction_policy       = local.settings["aks_nodepool_priority"] == "Spot" ? "Delete" : null
  node_taints           = local.settings["aks_nodepool_priority"] == "Spot" ? [ "kubernetes.azure.com/scalesetpriority=spot:NoSchedule", "workload-type=jobs:NoSchedule" ] : [ "workload-type=jobs:NoSchedule" ]
  node_labels           = local.settings["aks_nodepool_priority"] == "Spot" ? { "kubernetes.azure.com/scalesetpriority" = "spot" } : null
}

resource "azurerm_kubernetes_cluster_node_pool" "moodle-high-scale-redis" {
  name                  = "redis"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.moodle-high-scale.id
  vm_size               = local.settings["aks_redis_nodepool_vmsize"]
  priority              = local.settings["aks_nodepool_priority"]
  enable_auto_scaling   = true
  min_count             = 5
  max_count             = 30
  mode                  = "User"
  os_disk_type          = local.settings["aks_os_disk_type"]
  vnet_subnet_id        = azurerm_subnet.app.id
  zones                 = [1]
  eviction_policy       = local.settings["aks_nodepool_priority"] == "Spot" ? "Delete" : null
  node_taints           = local.settings["aks_nodepool_priority"] == "Spot" ? [ "kubernetes.azure.com/scalesetpriority=spot:NoSchedule", "workload-type=redis:NoSchedule" ] : [ "workload-type=redis:NoSchedule" ]
  node_labels           = local.settings["aks_nodepool_priority"] == "Spot" ? { "kubernetes.azure.com/scalesetpriority" = "spot" } : null 
}

resource "azurerm_kubernetes_cluster_node_pool" "moodle-high-scale-pgbouncer" {
  name                  = "pgbouncer"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.moodle-high-scale.id
  vm_size               = local.settings["aks_pgbouncer_nodepool_vmsize"]
  priority              = local.settings["aks_nodepool_priority"]
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 10
  mode                  = "User"
  os_disk_type          = local.settings["aks_os_disk_type"]
  vnet_subnet_id        = azurerm_subnet.app.id
  zones                 = [1]
  eviction_policy       = local.settings["aks_nodepool_priority"] == "Spot" ? "Delete" : null
  node_taints           = local.settings["aks_nodepool_priority"] == "Spot" ? [ "kubernetes.azure.com/scalesetpriority=spot:NoSchedule", "workload-type=pgbouncer:NoSchedule" ] : [ "workload-type=pgbouncer:NoSchedule" ]
  node_labels           = local.settings["aks_nodepool_priority"] == "Spot" ? { "kubernetes.azure.com/scalesetpriority" = "spot" } : null
}

resource "azurerm_role_assignment" "aks-subnet" {
  scope                = azurerm_virtual_network.moodle-high-scale.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.moodle-high-scale.identity.0.principal_id
}

resource "azurerm_role_assignment" "aks-resource-group" {
  scope                = data.azurerm_resource_group.moodle-high-scale.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.moodle-high-scale.identity.0.principal_id
}

resource "azurerm_role_assignment" "aks-resource-group-kubelet" {
  scope                = data.azurerm_resource_group.moodle-high-scale.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.moodle-high-scale.kubelet_identity.0.object_id
}