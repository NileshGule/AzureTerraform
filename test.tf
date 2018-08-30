provider "azurerm" {
}
resource "azurerm_resource_group" "rg" {
        name = "dotnetConfResourceGroup"
        location = "South East Asia"
}