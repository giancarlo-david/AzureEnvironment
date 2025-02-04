terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.17.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id                 = var.az_subscription_id
  resource_provider_registrations = "none"
}

// Create resource group that will house all resources that are created
resource "azurerm_resource_group" "CodingCanalRG" {
  name     = "CodingCanalRG"
  location = "East US"
}

// NSG to allow SSH on port 22 to VM
resource "azurerm_network_security_group" "DevNSG" {
  name                = "Dev-NSG"
  location            = azurerm_resource_group.CodingCanalRG.location
  resource_group_name = azurerm_resource_group.CodingCanalRG.name

    security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Dev"
  }
}

// Associate NSG to NIC
resource "azurerm_network_interface_security_group_association" "dev" {
    network_interface_id = azurerm_network_interface.DevNIC.id
    network_security_group_id = azurerm_network_security_group.DevNSG.id
}

// Create VNet to host all other resources
resource "azurerm_virtual_network" "DevVnet" {
  name                = "dev-network"
  location            = azurerm_resource_group.CodingCanalRG.location
  resource_group_name = azurerm_resource_group.CodingCanalRG.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "Dev"
  }
}

// Cretae subnet
resource "azurerm_subnet" "DevSubnet1" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.CodingCanalRG.name
  virtual_network_name = azurerm_virtual_network.DevVnet.name
  address_prefixes     = ["10.0.1.0/24"]

  private_link_service_network_policies_enabled = true
  private_endpoint_network_policies             = "Enabled"
}

// Creation of storage account with encryption enabled and disabling public network access to ensure private endpoint usage
resource "azurerm_storage_account" "DevStorage" {
  name                     = "devstoragecodingcanal"
  resource_group_name      = azurerm_resource_group.CodingCanalRG.name
  location                 = azurerm_resource_group.CodingCanalRG.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  public_network_access_enabled     = false
  infrastructure_encryption_enabled = true

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_private_endpoint" "StoragePrivateEndpoint" {
  name                = "storage-endpoint"
  location            = azurerm_resource_group.CodingCanalRG.location
  resource_group_name = azurerm_resource_group.CodingCanalRG.name
  subnet_id           = azurerm_subnet.DevSubnet1.id

  private_service_connection {
    name                           = "storage-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.DevStorage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "dev-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.DevPrivateDNSZone.id]
  }
}

resource "azurerm_private_dns_zone" "DevPrivateDNSZone" {
  name                = "devprivatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.CodingCanalRG.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "DevLink" {
  name                  = "dev-link"
  resource_group_name   = azurerm_resource_group.CodingCanalRG.name
  private_dns_zone_name = azurerm_private_dns_zone.DevPrivateDNSZone.name
  virtual_network_id    = azurerm_virtual_network.DevVnet.id
}

// Deploy NIC for VM to be deployed on
resource "azurerm_network_interface" "DevNIC" {
  name                = "dev-nic"
  location            = azurerm_resource_group.CodingCanalRG.location
  resource_group_name = azurerm_resource_group.CodingCanalRG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.DevSubnet1.id
    public_ip_address_id          = azurerm_public_ip.DevVM.id
    private_ip_address_allocation = "Dynamic"
  }
}

// Public IP for VM connection to SSH into 
resource "azurerm_public_ip" "DevVM" {
  name                = "DevVMPublicIp"
  resource_group_name = azurerm_resource_group.CodingCanalRG.name
  location            = azurerm_resource_group.CodingCanalRG.location
  allocation_method   = "Static"

  tags = {
    environment = "Dev"
  }
}

// Create VM
resource "azurerm_linux_virtual_machine" "DevVM" {
  name                = "dev-machine"
  resource_group_name = azurerm_resource_group.CodingCanalRG.name
  location            = azurerm_resource_group.CodingCanalRG.location
  size                = "Standard_F2"
  admin_username      = "testadmin"
  admin_password      = "Password123!"

  // Allows username+password login 
  disable_password_authentication = false



  network_interface_ids = [
    azurerm_network_interface.DevNIC.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

// Create RBAC for 'Developers' and 'Admins'
data "azurerm_subscription" "current" {
}

// Creates role called "Admins" that grants full access similar to the built-in "Owner" role in Azure
resource "azurerm_role_definition" "Admins" {
  name        = "Admins"
  scope       = data.azurerm_subscription.current.id
  description = "Role for Admins that grants full access"

  permissions {
    actions     = ["*"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id,
  ]
}

// Creates role called "Developers" that grants full read access similar ot the built-in "Reader" role in Azure
resource "azurerm_role_definition" "Developers" {
  name        = "Developers"
  scope       = data.azurerm_subscription.current.id
  description = "Role for Developers that grants read-only access"

  permissions {
    actions     = ["*/read"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id, 
  ]
}

// Assign built in policy to configure storage accounts to disable public network access
resource "azurerm_subscription_policy_assignment" "StorageAccountsDisablePublicAccess" {
  name                 = "Storage accounts should disable public network access"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/b2982f36-99f2-4db5-8eff-283140c09693"
  subscription_id      = data.azurerm_subscription.current.id
}

// Create policy that will set minimum TLS version to 1.2
resource "azurerm_policy_definition" "MinimumTLSVersion" {
  name         = "tls-minimum-1.2"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Minimum TLS 1.2"

  policy_rule = <<POLICY_RULE
 {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Storage/storageAccounts"
        },
        {
            "anyOf": [
              {
                "field": "Microsoft.Storage/storageAccounts/minimumTlsVersion",
                "notEquals": "TLS1_2"
              },
              {
                "field": "Microsoft.Storage/storageAccounts/minimumTlsVersion",
                "exists": "false"
              }
            ]
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
POLICY_RULE
}

// Assign policy to the subscription
resource "azurerm_subscription_policy_assignment" "MinimumTLS" {
  name                 = "TLSMinimum"
  policy_definition_id = azurerm_policy_definition.MinimumTLSVersion.id
  subscription_id      = data.azurerm_subscription.current.id
}