terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.42.0"

    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "UK South"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network_dns_servers" "example" {
  virtual_network_id = azurerm_virtual_network.example.id
  dns_servers        = [azurerm_private_dns_resolver_inbound_endpoint.example.ip_configurations[0].private_ip_address]
}

resource "azurerm_private_dns_resolver" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  virtual_network_id  = azurerm_virtual_network.example.id
}

resource "azurerm_subnet" "inbounddns" {
  name                                          = "inbounddns"
  resource_group_name                           = azurerm_resource_group.example.name
  virtual_network_name                          = azurerm_virtual_network.example.name
  address_prefixes                              = ["10.0.0.0/28"]
  private_link_service_network_policies_enabled = true

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "example" {
  name                    = "example-drie"
  private_dns_resolver_id = azurerm_private_dns_resolver.example.id
  location                = azurerm_private_dns_resolver.example.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.inbounddns.id
  }
}

resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet" "gatewaysubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.90.0/24"]
}

resource "azurerm_public_ip" "gateway" {
  name                = "gateway"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "example" {
  name                = "gateway"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Standard"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gatewaysubnet.id
  }

  vpn_client_configuration {
    address_space = ["192.168.90.0/24"]

    root_certificate {
      name = "testcert"

      public_cert_data = <<EOF
MIIC5jCCAc6gAwIBAgIIao/HkAJOAVIwDQYJKoZIhvcNAQELBQAwETEPMA0GA1UE
AxMGVlBOIENBMB4XDTIzMDEyNjIyMjgzNFoXDTI2MDEyNTIyMjgzNFowETEPMA0G
A1UEAxMGVlBOIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnaQx
Z1dfJxYsGVOrcA1xeEgFqDDgLDoSL7vd2GBY27UeVhkXF8kUPkjWhbY8hfhniOWl
IaCyt1osNi/f3K6jWonZTDXWy+x6zXQxLR4UzS5rCOkBC1hjd+c0S7h5KiQBhWsL
8PxMyGEADJLEFwvsJOsL/bEqvyb20j2cMu5qGRz9d5yudvWnOfURv/Cm0oxrPnrU
ungGaR2rRk2esjmoKC47Z/UWJtC7ivKzwq8TyQs3jBdiOr+dKz7mUAh+m/SsKFJr
+sFwiEWogqOLd+g5/vATFfvlkLWPkf6cRRR1DN96UDhujd0JeARmPrhuxpZCojzE
koSP/BLYKJKkmEks5QIDAQABo0IwQDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB
/wQEAwIBBjAdBgNVHQ4EFgQUcDqfwT/oLXs3Deo66nwRQYO7lJ0wDQYJKoZIhvcN
AQELBQADggEBAHJy1lPtHco2t5lNLtML2WG8dd7T06lhVR/OCDpsQhhJPVgmM2XP
oFLy9tB6WSiAsUvnOvxGGbUeO20G7HRS+C9GGwuHErFT2iVjl4V3eoMAjDGnOlC/
0r7faX2eqZ48Wq2cRFeZ+QQFi3hMCNQkOGhV9L5IenQq5ssI9fU7E9SrmknVay3x
Ne4QS+bbxic/elvpcTf3KFZmOfa1d391qEHe2/nU3MfWn8EFh1adwWJqYl61yFe4
PTKuUMvY0s5AwsX4bFaUI0zPIJ+a3d5WM92khCmDmXT7zqUkWeU0U4SAvZIdM9ee
KkI7qk6aHwfqVTnAHJo7cpGJg9DHOF1EU3w=
EOF

    }
  }
}

