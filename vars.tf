variable "prefix" {
    type =string
    default = "first-project"
    description = "The prefix which should be used for all resources in this project"
}

variable "location" {
    type =string
    default = "East US"
    description = "The Azure Region in which all resources in this project should be created."
}

variable "username" {
    type =string
    default = "ali"
    description = "The user name."
}

variable "password" {
    type =string
    default = "Ali@123"
    description = "The password."
}
variable "vm_count"{
    type = number
    default = "2"
    description = "Number of VM"
}
