output "paw_ip_address" {
  value = azurerm_public_ip.main.ip_address
}

output "db_admin_username" {
  value = "${var.db_admin_username}@${data.azuread_domains.default.domains.0.domain_name}"
}