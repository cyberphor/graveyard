variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "p7aks"
}

variable "container_registry_name" {
  type    = string
  default = "p7acrcyberphor"
}

variable "kubernetes_cluster_name" {
  type    = string
  default = "p7cluster"
}

variable "kubernetes_node_size" {
  type    = string
  default = "Standard_D2S_v3" 
}

variable "kubernetes_node_count" {
  type    = number
  default = 5
}