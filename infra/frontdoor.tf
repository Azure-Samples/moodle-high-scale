resource "azurerm_cdn_frontdoor_profile" "moodle-front-door" {
  name                = "moodle-front-door"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  sku_name            = "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "moodle-front-door" {
  name                     = "moodle-front-door-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.moodle-front-door.id

}

resource "azurerm_cdn_frontdoor_origin_group" "moodle-front-door" {
  name                     = "moodle-front-door"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.moodle-front-door.id

  load_balancing {}
}