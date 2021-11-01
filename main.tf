terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features{}

  subscription_id             = var.subscription_id
  client_id                   = var.client_id 
  client_secret               = var.client_secret
  tenant_id                   = var.tenant_id 
}



resource "azurerm_resource_group" "jenkin" {
    name     = "jenkinsci_cd"
    location = "eastus"

}

# Create virtual network
resource "azurerm_virtual_network" "jenkinsnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.jenkin.name

}

# Create subnet
resource "azurerm_subnet" "terraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.jenkin.name
    virtual_network_name = azurerm_virtual_network.jenkinsnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}


# Create public IPs
resource "azurerm_public_ip" "publicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.jenkin.name
    allocation_method            = "Dynamic"

}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.jenkin.name

    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTP"
        priority                   = 301
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


}


# Create network interface
resource "azurerm_network_interface" "terraformnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.jenkin.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.terraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.publicip.id
    }


}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nicassociate" {
    network_interface_id      = azurerm_network_interface.terraformnic.id
    network_security_group_id = azurerm_network_security_group.terraformnsg.id
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "terraformvm" {
    name                  = "myjekVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.jenkin.name
    network_interface_ids = [azurerm_network_interface.terraformnic.id]
    size                  = "Standard_B1s"

    os_disk {
        name                 = "myOsDisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    computer_name  = "myjekVM"
    admin_username = "testadmin"
    admin_password = "Password1234!"

    disable_password_authentication = false
  }
