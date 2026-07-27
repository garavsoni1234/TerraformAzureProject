terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name = "tfstate-rg"
    storage_account_name = "tfstate561f17"
    container_name       = "tfstate"
    key                  = "myapp.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "azurerm" {
  features {}
}