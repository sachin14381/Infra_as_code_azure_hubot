#provider "azurerm" {
#  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
#  version = "=1.24.0"

#  subscription_id = "05ec1026-b7a2-4fdf-8bfc-0c93d5ba7db6"
#}

variable "prefix1" {
  default = "hubot"
}


resource "azurerm_resource_group" "main2" {
  name     = "${var.prefix1}-resources"
  location = "West US 2"
}


resource "azurerm_virtual_network" "main1" {
  name                = "${var.prefix1}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main2.location}"
  resource_group_name = "${azurerm_resource_group.main2.name}"
}

resource "azurerm_subnet" "internal1" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.main2.name}"
  virtual_network_name = "${azurerm_virtual_network.main1.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_security_group" "test3" {
  name                = "acceptanceTestSecurityGroup2"
  location            = "${azurerm_resource_group.main2.location}"
  resource_group_name = "${azurerm_resource_group.main2.name}"
}


#resource "azurerm_network_security_group" "test4" {
#  name                = "acceptanceTestSecurityGroup3"
#  location            = "${azurerm_resource_group.main2.location}"
#  resource_group_name = "${azurerm_resource_group.main2.name}"
#}




resource "azurerm_network_security_rule" "outboundinbound12" {
  name                        = "tcpport1"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.main2.name}"
  network_security_group_name = "${azurerm_network_security_group.test3.name}"

 }

resource "azurerm_network_security_rule" "inbound1" {
  name                        = "tcpport"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.main2.name}"
  network_security_group_name = "${azurerm_network_security_group.test3.name}"
}


resource "azurerm_public_ip" "myterraformpublicip1" {
    name                         = "myPublicIP3"
    location                     = "${azurerm_resource_group.main2.location}"
    resource_group_name          = "${azurerm_resource_group.main2.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "dev"
    }
}


resource "azurerm_network_interface" "main1" {
  name                = "${var.prefix1}-nic"
  location            = "${azurerm_resource_group.main2.location}"
  resource_group_name = "${azurerm_resource_group.main2.name}"
  network_security_group_id = "${azurerm_network_security_group.test3.id}"
#  network_security_group_id = "${azurerm_network_security_group.test4.id}"
  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.internal1.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip1.id}"
  }
}

resource "azurerm_virtual_machine" "main1" {
  name                  = "${var.prefix1}-vm"
  location              = "${azurerm_resource_group.main2.location}"
  resource_group_name   = "${azurerm_resource_group.main2.name}"
  network_interface_ids = ["${azurerm_network_interface.main1.id}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
   delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk0010934"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostnamehubot"
    admin_username = "ubuntu"
    admin_password = "Password12345!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }




  provisioner "remote-exec" {

    inline = [
      "sudo apt-get install npm -y",
      "sleep 10",
      "sudo apt-get install nodejs",
      "sleep 10",
      "node -v",
      "npm -v",
      "sudo apt-get update",
      "sleep 10",
      "sudo npm install -g yo generator-hubot",
#      "sudo chown ubuntu -R /home/ubuntu/.config",
      "sleep 40",
      "mkdir hubotApp",
      "cd hubotApp/",
      "yo hubot --y  --adapter=campfire --owner='mybot' --name=testbot --description='such bot'",
     #"sudo bin/hubot"
     "sudo npm install hubot-slack --save",
    "HUBOT_SLACK_TOKEN=xoxb-619205963984-607778638546-jmU2wEkdMcCyyiVmeCeiTKXM ./bin/hubot --adapter slack &> /dev/null &"
]
}




  connection {
      type = "ssh",
      user = "ubuntu"
      password = "Password12345!"
      timeout = "3m"
      agent = false
      }

  tags = {
    environment = "dev"}

}


