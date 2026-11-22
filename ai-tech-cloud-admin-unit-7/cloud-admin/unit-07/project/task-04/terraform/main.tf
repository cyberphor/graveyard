resource "random_pet" "main" {
  length     = 2
  separator  = ""
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_mssql_server" "main" {
  name                          = random_pet.main.id
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  administrator_login           = var.admin_username
  administrator_login_password  = var.admin_password
  version                       = "12.0"
  public_network_access_enabled = "true" 
  identity {
    type = "SystemAssigned" 
  }
}

resource "azurerm_mssql_database" "main" {
  server_id                    = azurerm_mssql_server.main.id
  name                         = var.db_name
  max_size_gb                  = 2
  sku_name                     = "Basic"
}

resource "azurerm_virtual_network" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                = random_pet.main.id
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                 = random_pet.main.id
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "main" {
  depends_on          = [ azurerm_resource_group.main ]
  name                = random_pet.main.id
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  name                            = random_pet.main.id
  location                        = var.location
  resource_group_name             = var.resource_group_name
  ip_configuration {
    name                          = random_pet.main.id
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_security_group" "main" {
  name                = random_pet.main.id
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = random_pet.main.id
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  size                            = var.vm_size
  network_interface_ids           = [
    azurerm_network_interface.main.id
  ]
  disable_password_authentication = false
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  os_disk {
    caching                       = "ReadWrite"
    storage_account_type          = var.vm_os_disk_storage_type
    name                          = random_pet.main.id
  }
  source_image_reference {
    publisher                     = var.vm_image_publisher
    offer                         = var.vm_image_offer
    sku                           = var.vm_image_sku
    version                       = var.vm_image_version
  }
}

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "AllowAccessFromPrivilegedAccessWorkstation"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = azurerm_public_ip.main.ip_address
  end_ip_address   = azurerm_public_ip.main.ip_address
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = random_pet.main.id
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Free"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = random_pet.main.id
  target_resource_id         = "${azurerm_mssql_server.main.id}/databases/master"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
}

resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id              = azurerm_mssql_server.main.id
  log_monitoring_enabled = true
}

resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  database_id            = "${azurerm_mssql_server.main.id}/databases/master"
  log_monitoring_enabled = true
}

resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  database_id            = "${azurerm_mssql_server.main.id}/databases/${var.db_name}"
  log_monitoring_enabled = true
}