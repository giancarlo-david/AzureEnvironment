output "vm_public_ip" {
    value = azurerm_linux_virtual_machine.DevVM.public_ip_address
}