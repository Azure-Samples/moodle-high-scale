
provider "kubernetes" {
    host = "${azurerm_kubernetes_cluster.moodle-high-scale.kube_config.0.host}"

    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.moodle-high-scale.kube_config.0.client_certificate)}"
    client_key             = "${base64decode(azurerm_kubernetes_cluster.moodle-high-scale.kube_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.moodle-high-scale.kube_config.0.cluster_ca_certificate)}"
}

provider "helm" {
  kubernetes {
    host = "${azurerm_kubernetes_cluster.moodle-high-scale.kube_config.0.host}"

    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.moodle-high-scale.kube_config.0.client_certificate)}"
    client_key             = "${base64decode(azurerm_kubernetes_cluster.moodle-high-scale.kube_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.moodle-high-scale.kube_config.0.cluster_ca_certificate)}"
  }
}

data "azurerm_subscription" "current" {
}

data "azurerm_resource_group" "moodle-high-scale" {
    name = var.moodle-high-scale-rg
}

data "azurerm_client_config" "current" {
  
}