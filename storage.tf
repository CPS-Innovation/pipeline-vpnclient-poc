resource "azurerm_storage_account" "example" {
  name                          = "cnsstorageaccounttest"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  account_tier                  = "Standard"
  account_replication_type      = "GRS"
  public_network_access_enabled = false # 
}

resource "azurerm_private_endpoint" "storageaccount" {
  name                = "storageaccount"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = "storageaccount"
    private_connection_resource_id = azurerm_storage_account.example.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_private_dns_zone" "blobstorage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone" "storageaccount" {
  name                = "privatelink.web.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_a_record" "storageaccount" {
  name                = azurerm_storage_account.example.name
  zone_name           = azurerm_private_dns_zone.storageaccount.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 30
  records             = [azurerm_private_endpoint.storageaccount.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "storagecontainer" {
  name                = azurerm_storage_account.example.name
  zone_name           = azurerm_private_dns_zone.blobstorage.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 30
  records             = [azurerm_private_endpoint.storageaccount.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "storageaccount" {
  name                  = "storageaccount"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.storageaccount.name
  virtual_network_id    = azurerm_virtual_network.example.id
}
resource "azurerm_private_dns_zone_virtual_network_link" "blobstorage" {
  name                  = "blobstorage"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.blobstorage.name
  virtual_network_id    = azurerm_virtual_network.example.id
}


resource "azurerm_storage_container" "example" {
  depends_on = [
    azurerm_private_dns_a_record.storageaccount,
    azurerm_private_dns_a_record.storagecontainer,
  ]
  name                  = "content"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "example" {
  name                   = "helloworld"
  storage_account_name   = azurerm_storage_account.example.name
  storage_container_name = azurerm_storage_container.example.name
  type                   = "Block"
  source_content         = "helloworld"
}
