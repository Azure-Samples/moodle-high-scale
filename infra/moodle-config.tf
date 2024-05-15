resource "kubernetes_namespace" "moodle" {
  metadata {
    annotations = {
      name = "moodle"
    }
    name = "moodle"
  }
}

resource "kubernetes_secret" "pgbouncer-config" {
  metadata {
    name = "pgbouncer-config"
    namespace = "moodle"
  }

  data = {
    "POSTGRESQL_HOST"                     = azurerm_postgresql_flexible_server.moodle-db.fqdn
    "POSTGRESQL_PORT"                     = "5432"
    "POSTGRESQL_DATABASE"                 = azurerm_postgresql_flexible_server_database.moodle.name
    "POSTGRESQL_USERNAME"                 = azurerm_postgresql_flexible_server.moodle-db.administrator_login
    "POSTGRESQL_PASSWORD"                 = azurerm_postgresql_flexible_server.moodle-db.administrator_password
    "PGBOUNCER_DATABASE"                  = azurerm_postgresql_flexible_server_database.moodle.name
    "PGBOUNCER_MAX_CLIENT_CONN"           = "20000"
    "PGBOUNCER_DEFAULT_POOL_SIZE"         = "235"
    "PGBOUNCER_POOL_MODE"                 = "transaction"
    "PGBOUNCER_IGNORE_STARTUP_PARAMETERS" = "options"
    "PGBOUNCER_SERVER_TLS_SSLMODE"        = "require"
    "PGBOUNCER_MIN_POOL_SIZE"             = "235"
  }

}

resource "kubernetes_secret" "moodle-config" {
  metadata {
    name = "moodle-config"
    namespace = "moodle"
  }
  
  data = {    
    "STG_NAME"                = azurerm_storage_account.moodle-assets.name
    "STG_CONTAINER_NAME"      = azurerm_storage_container.moodle-assets.name
    "STG_SAS_TOKEN"           = trimprefix(data.azurerm_storage_account_blob_container_sas.sastoken.sas, "?")
    "REDIS_SESSION_HOST"      = "redis-cluster-svc"
    "REDIS_SESSION_PORT"      = "6379"
    "REDIS_CACHE_HOST"        = "redis-cache-cluster-svc"
    "REDIS_CACHE_PORT"        = "6379"
    "DATABASE_HOST"           = "pgbouncer-svc"
    "DATABASE_PORT"           = "6432"
    "DATABASE_NAME"           = azurerm_postgresql_flexible_server_database.moodle.name
    "DATABASE_USER"           = azurerm_postgresql_flexible_server.moodle-db.administrator_login
    "DATABASE_PASSWORD"       = azurerm_postgresql_flexible_server.moodle-db.administrator_password
    "DATABASE_PREFIX"         = "md_"
    "WWW_ROOT"                = "https://${azurerm_cdn_frontdoor_endpoint.moodle-front-door.host_name}"
    "DATA_ROOT"               = "/var/www/moodledata"
    "ADMIN"                   = "admin"
    "SSL_PROXY"               = "true"
    "CFG"                     = "$CFG"
    "azurestorageaccountname" = azurerm_storage_account.moodle-data.name
    "azurestorageaccountkey"  = azurerm_storage_account.moodle-data.primary_access_key
  }

}