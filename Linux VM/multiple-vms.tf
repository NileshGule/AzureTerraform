# variable "node_count" {
#   default = 2
# }

# variable "count" {
#   default = 2
# }

# resource "azurerm_network_interface" "terraform-CnetFace" {
#   count    = "${var.count}"
#   name     = "cacctni-${format("%02d", count.index+1)}"
#   location = "South East Asia"

#   # resource_group_name = "${azurerm_resource_group.terraform-test.name}"
#   resource_group_name = "dotnetConfResourceGroup"

#   ip_configuration {
#     name                          = "cIpconfig-${format("%02d", count.index+1)}"
#     subnet_id                     = "${azurerm_subnet.terraform-test.id}"
#     private_ip_address_allocation = "dynamic"
#   }

#   count = "${var.node_count}"
# }

# variable "confignode_count" {
#   default = 2
# }

# resource "azurerm_virtual_machine" "terraform-test" {
#   count    = "${var.count}"
#   name     = "confignode-${format("%02d", count.index+1)}"
#   location = "South East Asia"

#   #   resource_group_name   = "${azurerm_resource_group.terraform-test.name}"
#   resource_group_name   = "dotnetConfResourceGroup"
#   network_interface_ids = ["${element(azurerm_network_interface.terraform-CnetFace.*.id, count.index)}"]
#   vm_size               = "Standard_A0"
#   availability_set_id   = "${azurerm_availability_set.terraform-test.id}"

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "14.04.2-LTS"
#     version   = "latest"
#   }

#   storage_os_disk {
#     name          = "configosdisk-${format("%02d", count.index+1)}"
#     vhd_uri       = "${azurerm_storage_account.terraform-test.primary_blob_endpoint}${azurerm_storage_container.terraform-test.name}/configosdisk-${format("%02d", count.index+1)}.vhd"
#     caching       = "ReadWrite"
#     create_option = "FromImage"
#   }

#   storage_data_disk {
#     name          = "configdatadisk-${format("%02d", count.index+1)}"
#     vhd_uri       = "${azurerm_storage_account.terraform-test.primary_blob_endpoint}${azurerm_storage_container.terraform-test.name}/configdatadisk-${format("%02d", count.index+1)}.vhd"
#     disk_size_gb  = "50"
#     create_option = "empty"
#     lun           = 0
#   }

#   os_profile {
#     computer_name  = "confignode-${format("%02d", count.index+1)}"
#     admin_username = "ubuntu"
#     admin_password = "Qawzsx12345"
#   }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }

#   tags {
#     environment = "Production"
#   }

#   provisioner "local-exec" {
#     command = "sleep 30"
#   }

#   #Loop for Count
#   count = "${var.confignode_count}"
# }

variable "resourcename" {
  default = "dotnetConfResourceGroup"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "dotnetConfResourceGroup"
    location = "South East Asia"

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "South East Asia"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "South East Asia"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "South East Asia"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

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

    tags {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "South East Asia"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is definedss
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "South East Asia"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "South East Asia"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa put our key here"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Terraform Demo"
    }
}