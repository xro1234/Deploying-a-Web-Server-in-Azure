# Deploying a Web Server in Azure.

## Introduction

#### In this project, you will create a web server with a load balancer. in azure by using Terraform

#### & Packer

## Getting Started

## Before you build a web server, you will need to:

#### 1. Understand the previous lessons

#### 2. PC

## Dependencies

## In order to build a web server, you will need the following supplies:

#### ● Create an Azure Account

#### ● Install the Azure command line interface

#### ● Install Packer

#### ● Install Terraform

## Instructions

## Once you've collected your dependencies, to build your web server:

#### 1. login to your Azure account by using:

#### az login

#### 2. Create and Apply a Tagging Policy-in

#### this part you decide to deny any resource without tags


#### Note: see tagging_policy.json file to better understanding

#### 3. Packer Template

#### you need to use Packer to deploy vm but first you need to prepare:

#### Create a resource group

#### az group create -n first-project-rg -l eastus --tags name=project-

#### Create a service principal

#### az ad sp create-for-rbac --query "{ client_id: appId, client_secret:

#### password, tenant_id: tenant }"

#### get subscription ID

#### az account show --query "{ subscription_id: id }"

#### take this information (client_id, client_secret, tenant_id) and put it in this part and the

#### resource group in its

```
"client_id": "######################################",
"client_secret": "##################################",
"subscription_id": "################################",
"tenant_id": "######################################"
"managed_image_resource_group_name": "first-project-rg",
```
#### Use an Ubuntu 18.04-LTS SKU as your base image

```
"os_type":"Linux",
"image_publisher": "Canonical",
"image_offer": "UbuntuServer",
"image_sku": "18.04-LTS",
```
#### Don’t forget Tags

```
"azure_tags": {
"name": "packer-part"
},
```
#### After you prepare to deploy now you need to deploy Ubuntu Server *Run the

#### following command to deploy

#### az packer build server.json

#### Note: see server.json file to better understanding


#### 4. terraform Template

#### Create a Resource Group.

```
resource "azurerm_resource_group""main"{
name = "${var.prefix}-rg"
location = var.location
tags = {
"name"= "${var.name}"
}
```
#### Create a Virtual network and a subnet on that virtual network.

```
#Create a Virtual network
resource "azurerm_virtual_network""main" {
name = "${var.prefix}-network"
address_space = ["10.0.0.0/16"]
location = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name
```
```
tags = {
"name"= "${var.name}"
}
}
```
```
#Create a subnet on that virtual network.
resource "azurerm_subnet""main" {
name = "${var.prefix}-subnet"
resource_group_name = azurerm_resource_group.main.name
virtual_network_name = azurerm_virtual_network.main.name
address_prefixes = ["10.0.2.0/24"]
```
```
}
```
#### Create a Network Security Group. Ensure that you explicitly allow access to other

#### VMs on the subnet and deny direct access from the internet.

```
resource "azurerm_network_security_group""main" {
name = "${var.prefix}-nsg"
location = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name
```
```
security_rule {
name = "AllowOutbound"
description = "Allow to access from other VMs "
priority = 100
```

```
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "*"
source_address_prefix = "10.0.0.0/16"
destination_address_prefix = "10.0.0.0/16"
}
```
```
security_rule {
name = "DenyInternetAccess"
priority = 101
direction = "Inbound"
access = "Deny"
protocol = "*"
source_port_range = "*"
destination_port_range = "*"
source_address_prefix = "Internet"
destination_address_prefix = "10.0.0.0/16"
}

tags = {
"name"= "${var.name}"
}
}
resource "azurerm_subnet_network_security_group_association""main" {
subnet_id = azurerm_subnet.main.id
network_security_group_id = azurerm_network_security_group.main.id
}
```
#### Create a Network Interface.
```
resource "azurerm_network_interface""main" {
count = var.vm_count
name = "${var.prefix}-nic-${count.index}"
location = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name

ip_configuration {
name = "${var.prefix}-nic-configuration"
subnet_id = azurerm_subnet.main.id
private_ip_address_allocation = "Dynamic"
}
tags = {
"name" = "${var.name}"
}
}
```

#### Create a Public IP.
```
resource "azurerm_public_ip""main"{
name ="${var.prefix}-publicIPForLB"
location = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name
allocation_method ="Static"

tags = {
"name" = "${var.name}"
}
}
```
#### Create a Load Balancer. Your load balancer will need a backend address pool and

#### address pool association for the network interface and the load balancer.
```
resource "azurerm_lb""main" {
name = "${var.prefix}-main-lb"
location = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name

frontend_ip_configuration {
name ="primary"
public_ip_address_id = azurerm_public_ip.main.id
}
tags = {
"name" ="${var.name}"
}
}

resource "azurerm_lb_backend_address_pool""main" {
resource_group_name = azurerm_resource_group.main.name
loadbalancer_id = azurerm_lb.main.id
name = "${var.prefix}-backend_address_pool"
}

resource "azurerm_network_interface_backend_address_pool_association""main"
{
count = var.vm_count
network_interface_id = azurerm_network_interface.main[count.index].id
ip_configuration_name = "${var.prefix}-nic-configuration"
backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

```
#### Create a virtual machine availability set.

```
resource "azurerm_availability_set""main" {
name ="${var.prefix}-aset"
location = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name
platform_fault_domain_count = 2

tags = {
"name" ="${var.name}"
}
}
```
#### Create virtual machines.

```
resource "azurerm_linux_virtual_machine""main" {
count = var.vm_count
name = "${var.prefix}-${count.index}-vm"
resource_group_name = azurerm_resource_group.main.name
location = azurerm_resource_group.main.location
size = "Standard_D2s_v3"
admin_username = var.username
admin_password = var.password
disable_password_authentication = false
network_interface_ids =
[element(azurerm_network_interface.main.*.id,count.index)]
availability_set_id = azurerm_availability_set.main.id
source_image_id =
"/subscriptions/**********************/resourceGroups/first-project-rg/provi
ders/Microsoft.Compute/images/first-project"
```
```
os_disk {
storage_account_type ="Standard_LRS"
caching ="ReadWrite"
}
tags = {
"name"="${var.name}"
}
}
```
#### Make sure you use the image you deployed using Packer! by using:

#### source_image_id ="/subscriptions/**********************/resourceGroups/first-project-rg/providers/Microsoft.Compute/images/first-project"

#### Create managed disks for your virtual machines.

#### create a virtual disk for each VM created.
```
resource "azurerm_managed_disk""main" {
count = var.vm_count
name = "data-disk-${count.index}"
location = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name
storage_account_type = "Standard_LRS"
create_option = "Empty"
disk_size_gb = 1

tags = {
"name" = "${var.name}"
}
}

resource "azurerm_virtual_machine_data_disk_attachment""main" {
count = var.vm_count
managed_disk_id = azurerm_managed_disk.main.*.id[count.index]
virtual_machine_id = azurerm_linux_virtual_machine.main.*.id[count.index]
lun = 10 * count.index
caching = "ReadWrite"
}

```
#### Edit Terraform variables

```
variable "prefix" {
type =string
default ="first-project"
description = "The prefix which should be usedfor all resources in this
project"
}
```
```
variable "location" {
type =string
default ="East US"
description = "The Azure Region in which all resourcesin this project
should be created."
}
```
```
variable "username" {
type =string
default ="ali"
description = "The user name."
}
```
```
variable "password" {
type =string
default ="Ali@123"
description = "The password."
}
variable "vm_count"{
type = number
default ="2"
description = "Number of VM"
}
```
```
variable "name"{
description = "Name of the project, used to tag resources"
default ="Deploy web server in Azure"
}
```
#### Run the following command to prepare

#### terraform init

#### import vm by using this command


#### terraform import

#### azurerm_resource_group.main/subscriptions/*************************/resourceGroups/first-project-rg

#### Run the following command to deploy

#### terraform plan -out solution.plan

#### if everything fine, run following command

#### terraform apply

#### Note: see main file to better understanding


### Vars.tf
```
variable "prefix" {
type =string
default ="first-project"
description = "The prefix which should be usedfor all resources in this
project"
}

variable "location" {
type =string
default ="East US"
description = "The Azure Region in which all resourcesin this project should be
created."
}

variable "username" {
type =string
default ="ali"
description = "The user name."
}

variable "password" {
type =string
default ="Ali@123"
description = "The password."
}
variable "vm_count"{
type = number
default ="2"
description = "Number of VM"
}

variable "name"{
description = "Name of the project, used to tag resources"
default ="Deploy web server in Azure"
}

```


## Output

#### Note: see images Output1 and Output2 to better understanding
