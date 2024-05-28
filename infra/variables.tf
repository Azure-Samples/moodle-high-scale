variable "moodle-high-scale-rg" {
  type    = string
  default = "moodle-high-scale"
}

variable "moodle-environment" {
  type    = string
  default = "development"
}

variable "environment_configuration" {
  type = map

  default = {
    development = {
        azure_database_sku              = "Standard_D2ads_v5"
        azure_database_read_replica_sku = "Standard_D2ads_v5"
        azure_database_storage          = "32768"
        azure_database_version          = "15"
        aks_system_nodepool_vmsize      = "GP_Standard_B2s"
        aks_app_nodepool_vmsize         = "Standard_D4s_v5"
        aks_jobs_nodepool_vmsize        = "Standard_D4s_v5"
        aks_redis_nodepool_vmsize       = "Standard_D4s_v5"
        aks_pgbouncer_nodepool_vmsize   = "Standard_E4s_v5"
        aks_nodepool_priority           = "Spot"
        aks_sku_tier                    = "Free"
        aks_os_disk_type                = "Managed"
        redis_family                    = "C"
        redis_sku                       = "Basic"
        redis_capacity                  = "0"
        files_quota                     = "100"

    }
    production = {
        azure_database_sku              = "GP_Standard_D32ads_v5"
        azure_database_read_replica_sku = "GP_Standard_D32ads_v5"
        azure_database_storage          = "524288"
        azure_database_version          = "15"
        aks_system_nodepool_vmsize      = "Standard_D4ds_v5"
        aks_app_nodepool_vmsize         = "Standard_D16ds_v5"
        aks_jobs_nodepool_vmsize        = "Standard_D4ds_v5"
        aks_redis_nodepool_vmsize       = "Standard_D8ds_v5"
        aks_pgbouncer_nodepool_vmsize   = "Standard_D4ds_v5"
        aks_nodepool_priority           = "Regular"
        aks_sku_tier                    = "Standard"
        aks_os_disk_type                = "Ephemeral"
        redis_family                    = "P"
        redis_sku                       = "Premium"
        redis_capacity                  = "2"
        files_quota                     = "1024"
    } 
  }
}

locals {

  settings = "${lookup(var.environment_configuration, var.moodle-environment)}"

}