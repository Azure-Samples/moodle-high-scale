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
    "DB_HOST"                   = azurerm_postgresql_flexible_server.moodle-db.fqdn
    "DB_PORT"                   = "5432"
    "DB_NAME"                   = azurerm_postgresql_flexible_server_database.moodle.name
    "DB_USER"                   = azurerm_postgresql_flexible_server.moodle-db.administrator_login
    "DB_PASSWORD"               = azurerm_postgresql_flexible_server.moodle-db.administrator_password
    "MAX_CLIENT_CONN"           = "20000"
    "DEFAULT_POOL_SIZE"         = "235"
    "POOL_MODE"                 = "session"
    "IGNORE_STARTUP_PARAMETERS" = "options"
    "SERVER_TLS_SSLMODE"        = "require"
    "MIN_POOL_SIZE"             = "235"
  }

}

resource "kubernetes_secret" "pgbouncer-config-read-replica" {
  metadata {
    name = "pgbouncer-config-read-replica"
    namespace = "moodle"
  }

  data = {
    "DB_HOST"                   = azurerm_postgresql_flexible_server.moodle-db-read-replica.fqdn
    "DB_PORT"                   = "5432"
    "DB_NAME"                   = azurerm_postgresql_flexible_server_database.moodle.name
    "DB_USER"                   = azurerm_postgresql_flexible_server.moodle-db-read-replica.administrator_login
    "DB_PASSWORD"               = azurerm_postgresql_flexible_server.moodle-db-read-replica.administrator_password
    "MAX_CLIENT_CONN"           = "20000"
    "DEFAULT_POOL_SIZE"         = "235"
    "POOL_MODE"                 = "transaction"
    "IGNORE_STARTUP_PARAMETERS" = "options"
    "SERVER_TLS_SSLMODE"        = "require"
    "MIN_POOL_SIZE"             = "235"
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
    "DATABASE_HOST_READ"      = "pgbouncer-read-svc"
    "DATABASE_PORT"           = "5432"
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