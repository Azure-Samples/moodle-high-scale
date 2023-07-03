resource "random_string" "moodle-data-password" {
  length           = 16
  special          = true
  upper            = true
  override_special = "!#$%*()-_=+[]{}:?"
}

resource "azurerm_network_interface" "moodle-data-nic" {
  name                = "moodle-data-nic"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  location            = data.azurerm_resource_group.moodle-high-scale.location

  enable_accelerated_networking = local.settings["moodle_data_accel_net"]

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "moodle-data" {
  name                = "moodle-data"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  location            = data.azurerm_resource_group.moodle-high-scale.location
  size                = local.settings["moodle_data_vmsize"]
  zone                = 1
  
  admin_username                  = "moodle-data-admin"
  admin_password                  = "${random_string.moodle-data-password.result}"
  disable_password_authentication = false
  
  network_interface_ids = [
    azurerm_network_interface.moodle-data-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_managed_disk" "moodle-data" {
  name                 = "moodle-data"
  resource_group_name  = data.azurerm_resource_group.moodle-high-scale.name
  location             = data.azurerm_resource_group.moodle-high-scale.location
  storage_account_type = local.settings["moodle_data_disk_type"]
  tier                 = local.settings["moodle_data_disk_tier"]
  disk_size_gb         = local.settings["moodle_data_disk_size"]
  create_option        = "Empty"
  zone                 = 1
}

resource "azurerm_virtual_machine_data_disk_attachment" "moodle-data" {
  managed_disk_id    = azurerm_managed_disk.moodle-data.id
  virtual_machine_id = azurerm_linux_virtual_machine.moodle-data.id
  lun                = "10"
  caching            = "None"
}

resource "azurerm_virtual_machine_extension" "aadssh" {
  name                 = "aadssh"
  virtual_machine_id   = azurerm_linux_virtual_machine.moodle-data.id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
}