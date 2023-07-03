data "azurerm_private_link_service" "moodle-svc-pls" {
  name                = "moodle-svc-pls"
  resource_group_name = data.azurerm_kubernetes_cluster.moodle-high-scale.node_resource_group
}

data "azurerm_cdn_frontdoor_endpoint" "moodle-front-door" {
  name                = "moodle-front-door-endpoint"
  profile_name        = "moodle-front-door"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
}

data "azurerm_cdn_frontdoor_origin_group" "moodle-front-door" {
  name                = "moodle-front-door"
  profile_name        = "moodle-front-door"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
}

resource "azurerm_cdn_frontdoor_origin" "moodle-front-door" {
  name                           = "moodle-front-door"
  cdn_frontdoor_origin_group_id  = data.azurerm_cdn_frontdoor_origin_group.moodle-front-door.id
  enabled                        = true
  host_name                      = data.azurerm_cdn_frontdoor_endpoint.moodle-front-door.host_name
  origin_host_header             = data.azurerm_cdn_frontdoor_endpoint.moodle-front-door.host_name
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true

  private_link {
    request_message        = "Private Link Origin Frontdoor"
    location               = data.azurerm_resource_group.moodle-high-scale.location
    private_link_target_id = data.azurerm_private_link_service.moodle-svc-pls.id
  }

}

resource "azurerm_cdn_frontdoor_route" "moodle-front-door" {
  name                          = "moodle-front-door-route"
  cdn_frontdoor_endpoint_id     = data.azurerm_cdn_frontdoor_endpoint.moodle-front-door.id
  cdn_frontdoor_origin_group_id = data.azurerm_cdn_frontdoor_origin_group.moodle-front-door.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.moodle-front-door.id]
  enabled                       = true

  forwarding_protocol    = "HttpOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain          = true

  cache {
    query_string_caching_behavior = "UseQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml", "application/json", "application/xml", "text/css", "text/js"]
  }
}