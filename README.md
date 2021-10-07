# Deploying a Web Server in Azure.

## Introduction
In this project, you will create a web server with a load balancer. in azure by using Terraform & Packer

## Getting Started
***Before you build a web server, you will need to:***
* Understand the previous lessons
* PC


## Dependencies
***In order to build a web server, you will need the following supplies:***
* Create an Azure Account
* Install the Azure command line interface
* Install Packer
* Install Terraform

## Instructions
***Once you've collected your dependencies, to build your web server:***
### 1. login to youre Azure acount by using
<pre>az login</pre>
### 2. Create and Apply a Tagging Policy 
* in this part you decide to deny any resource without tags
> **Note:** see tagging_policy.json file to better understanding
### 3. Packer Template
***you need to use Packer to deploy vm but first you need to prepare***

* Create a resource group 
<pre> az group create -n first-project-rg -l eastus --tags name=project-1</pre>
* Create a service principal
<pre>az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"</pre> 
* get subscription ID
<pre>az account show --query "{ subscription_id: id }"</pre>
* take this information (client_id, client_secret, tenant_id) and put it in variable part and the resource group in its 
<pre> managed_image_resource_group_name</pre>
After you prepare to deploy now you need to deploy Ubuntu Server
*Run the following command to deploy
<pre> az packer build server.json </pre>
    
**Note:** see server.json file to better understanding

### 4. terraform Template

* Run the following command to prepare
 
 <pre>terraform init</pre>

* import vm by using this command

<pre>terraform import azurerm_resource_group.main /subscriptions/6f43e450-06c6-4987-b7e1-a1a28de906e0/resourceGroups/first-project-rg
</pre>

* Run the following command to deploy
 
 <pre>terraform plan -out solution.plan</pre>
 
* if everything fine, run following command
 
 <pre>terraform apply</pre>
 
**Note:** see main file to better understanding


## Output

The problem is back-end address pool association was not found in Network Interface even though it was created in the resource group.

I modified the version to v2.33 but it doesn't work.

Kindly visiting the following link to show my ask 

https://knowledge.udacity.com/questions/708180


