resource "azurerm_service_plan" "cnsdemo" {
  name                = "cnsdemo"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "example" {
  name                = "cnsdemoapp"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  service_plan_id     = azurerm_service_plan.cnsdemo.id
  site_config {
    application_stack {
      docker_image     = "registry.hub.docker.com/library/nginx"
      docker_image_tag = "1.23.3"
    }
  }
}


resource "azurerm_private_endpoint" "appserviceexample" {
  name                = "appserviceexample-endpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "appserviceexample-privateserviceconnection"
    private_connection_resource_id = azurerm_linux_web_app.example.id
    subresource_names              = ["sites"]

    is_manual_connection = false
  }
}

resource "azurerm_private_dns_a_record" "example" {
  name                = azurerm_linux_web_app.example.name
  zone_name           = azurerm_private_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 30
  records             = [azurerm_private_endpoint.appserviceexample.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.example.name
}


resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "appservice"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}
