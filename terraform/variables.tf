variable "location" {
  description = "Azure region"
  default     = "East US"
}

variable "resource_group_name" {
  default = "DevOpsRG"
}

variable "vnet_name" {
  default = "vnet"
}

variable "vnet_address_space" {
  default = "10.0.0.0/16"
}

variable "subnet_name" {
  default = "subnet"
}

variable "subnet_prefix" {
  default = "10.0.1.0/24"
}

variable "nic_name" {
  default = "nic"
}

variable "public_ip_name" {
  default = "publicIP"
}

variable "vm_name" {
  default = "devops-vm"
}

variable "vm_size" {
  default = "Standard_B1s"
}

variable "admin_username" {
  default = "azureuser"
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  default     = "~/.ssh/id_rsa.pub"
}
