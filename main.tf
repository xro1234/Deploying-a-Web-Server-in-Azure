

provider "azurerm" {
version = "=2.33.0"
  features {}
}
# Create a Resource Group.
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = {
    "name" = "Deploying a Web Server in Azure"
  }

}
#Create a Virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    "name" = "Deploying a Web Server in Azure"
  
  }

}

#Create a subnet on that virtual network.
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

}

#Create a Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowOutbound"
    description                = "Allow to access from other VMs "
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "10.0.0.0/16"
  }

  security_rule {
    name                       = "DenyInternetAccess"
    description                = "Deny all traffic came from the Internet"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "10.0.0.0/16"
  }

  tags = {
    "name" = "Deploying a Web Server in Azure"
  }
} 


#Create a Public IP.
 resource "azurerm_public_ip" "main" {
   name                         = "${var.prefix}-publicIPForLB"
   location                     = azurerm_resource_group.main.location
   resource_group_name          = azurerm_resource_group.main.name
   allocation_method            = "Static"

       tags = {
    "name" = "Deploying a Web Server in Azure"
  }
 }

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-main-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.main.id
  }
      tags = {
    "name" = "Deploying a Web Server in Azure"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-acctestpool"
}
#Create a Network Interface.
resource "azurerm_network_interface" "main" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-nic-configuration"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
    tags = {
    "name" = "Deploying a Web Server in Azure"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "${var.prefix}-association-configuration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

#Create a virtual machine availability set.
resource "azurerm_availability_set" "main" {
  name                        = "${var.prefix}-aset"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  platform_fault_domain_count = 2

  tags = {
    "name" = "Deploying a Web Server in Azure"
  
  }
}
#Create virtual machines.
resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.vm_count
  name                            = "${var.prefix}-${count.index}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids           = [element(azurerm_network_interface.main.*.id, count.index)]
  availability_set_id             = azurerm_availability_set.main.id
  source_image_id                 = "/subscriptions/***************************/resourceGroups/first-project-rg/providers/Microsoft.Compute/images/first-project"


  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    "name" = "Deploying a Web Server in Azure"
  
  }

}
#Create managed disks for your virtual machines.
#create a virtual disk for each VM created.
resource "azurerm_managed_disk" "main" {
  count                           = var.vm_count
  name                            = "data-disk-${count.index}"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  storage_account_type            = "Standard_LRS"
  create_option                   = "Empty"
  disk_size_gb                    = 1

    tags = {
    "name" = "Deploying a Web Server in Azure"
  
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.main.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.main.*.id[count.index]
  lun                = 10 * count.index
  caching            = "ReadWrite"


}

