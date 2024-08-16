# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 0.7.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.67.0"
    }
  }

}

provider "azuread" {}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

