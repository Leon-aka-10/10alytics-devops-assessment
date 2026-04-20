terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstate10alytics"
    container_name       = "tfstate"
    key                  = "devops.terraform.tfstate"
  }
}