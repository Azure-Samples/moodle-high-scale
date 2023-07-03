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
    "POSTGRESQL_HOST"                     = azurerm_private_endpoint.moodle-cosmos-pgsql.private_dns_zone_configs.0.record_sets.0.fqdn
    "POSTGRESQL_PORT"                     = "5432"
    "POSTGRESQL_DATABASE"                 = "citus"
    "POSTGRESQL_USERNAME"                 = "citus"
    "POSTGRESQL_PASSWORD"                 = azurerm_cosmosdb_postgresql_cluster.moodle-cosmos-pgsql.administrator_login_password
    "PGBOUNCER_DATABASE"                  = "citus"
    "PGBOUNCER_MAX_CLIENT_CONN"           = "20000"
    "PGBOUNCER_DEFAULT_POOL_SIZE"         = "235"
    "PGBOUNCER_POOL_MODE"                 = "transaction"
    "PGBOUNCER_IGNORE_STARTUP_PARAMETERS" = "options"
    "PGBOUNCER_SERVER_TLS_SSLMODE"        = "require"
    "PGBOUNCER_MIN_POOL_SIZE"             = "235"
  }

}

resource "kubernetes_secret" "pgbouncer-replica-config" {

  count = local.settings["cosmos_replica_count"]

  metadata {
    name = "pgbouncer-replica-${count.index}-config"
    namespace = "moodle"
  }

  data = {
    "POSTGRESQL_HOST"                     = element(azurerm_private_endpoint.moodle-cosmos-pgsql-replica.*.private_dns_zone_configs.0.record_sets.0.fqdn, count.index)
    "POSTGRESQL_PORT"                     = 5432
    "POSTGRESQL_DATABASE"                 = "citus"
    "POSTGRESQL_USERNAME"                 = "citus"
    "POSTGRESQL_PASSWORD"                 = azurerm_cosmosdb_postgresql_cluster.moodle-cosmos-pgsql.administrator_login_password
    "PGBOUNCER_DATABASE"                  = "citus"
    "PGBOUNCER_MAX_CLIENT_CONN"           = "100"
    "PGBOUNCER_DEFAULT_POOL_SIZE"         = "100"
    "PGBOUNCER_POOL_MODE"                 = "transaction"
    "PGBOUNCER_IGNORE_STARTUP_PARAMETERS" = "options"
    "PGBOUNCER_SERVER_TLS_SSLMODE"        = "require"
    "PGBOUNCER_MIN_POOL_SIZE"             = "6"
    "PGBOUNCER_PORT"                      = count.index + 6433
  }

}

resource "kubernetes_secret" "moodle-config" {
  metadata {
    name = "moodle-config"
    namespace = "moodle"
  }
  
  data = {
    "STG_NAME"            = azurerm_storage_account.moodle-assets.name
    "STG_CONTAINER_NAME"  = azurerm_storage_container.moodle-assets.name
    "STG_SAS_TOKEN"       = trimprefix(data.azurerm_storage_account_blob_container_sas.sastoken.sas, "?")
    "REDIS_SESSION_HOST"  = "redis-cluster-svc"
    "REDIS_SESSION_PORT"  = "6379"
    "REDIS_CACHE_HOST"    = "redis-cache-cluster-svc"
    "REDIS_CACHE_PORT"    = "6379"
    "DATABASE_HOST"       = "pgbouncer-svc"
    "DATABASE_PORT"       = "6432"
    "DATABASE_NAME"       = "citus"
    "DATABASE_USER"       = "citus"
    "DATABASE_PASSWORD"   = azurerm_cosmosdb_postgresql_cluster.moodle-cosmos-pgsql.administrator_login_password
    "DATABASE_PREFIX"     = "md_"
    "DATABASE_REPLICAS"   = join(", ", [ for i, host in azurerm_private_endpoint.moodle-cosmos-pgsql-replica.*.private_dns_zone_configs.0.record_sets.0.fqdn : "['dbhost' => 'pgbouncer-svc', 'dbport' => ${6433 + i}]" ])
    "WWW_ROOT"            = "https://${azurerm_cdn_frontdoor_endpoint.moodle-front-door.host_name}"
    "DATA_ROOT"           = "/var/www/moodledata"
    "ADMIN"               = "admin"
    "SSL_PROXY"           = "true"
    "CFG"                 = "$CFG"
  }

}


resource "kubernetes_secret" "moodle-config-cron" {
  metadata {
    name = "moodle-config-cron"
    namespace = "moodle"
  }
  
  data = {
    "STG_NAME"            = azurerm_storage_account.moodle-assets.name
    "STG_CONTAINER_NAME"  = azurerm_storage_container.moodle-assets.name
    "STG_SAS_TOKEN"       = trimprefix(data.azurerm_storage_account_blob_container_sas.sastoken.sas, "?")
    "REDIS_SESSION_HOST"  = "redis-cluster-svc"
    "REDIS_SESSION_PORT"  = "6379"
    "DATABASE_HOST"       = "localhost"
    "DATABASE_PORT"       = "6432"
    "DATABASE_NAME"       = "citus"
    "DATABASE_USER"       = "citus"
    "DATABASE_PASSWORD"   = azurerm_cosmosdb_postgresql_cluster.moodle-cosmos-pgsql.administrator_login_password
    "DATABASE_PREFIX"     = "md_"
    "WWW_ROOT"            = "https://${azurerm_cdn_frontdoor_endpoint.moodle-front-door.host_name}"
    "DATA_ROOT"           = "/var/www/moodledata"
    "ADMIN"               = "admin"
    "SSL_PROXY"           = "true"
    "CFG"                 = "$CFG"
  }

}