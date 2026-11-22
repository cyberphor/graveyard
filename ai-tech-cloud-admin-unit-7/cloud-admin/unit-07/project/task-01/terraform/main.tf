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

resource "azurerm_mssql_firewall_rule" "main" {
  name             = "AllowAzureServicesAndResourcesAccessToThisServer"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}