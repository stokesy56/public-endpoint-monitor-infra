# variables.tf
variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west2"
}

variable "cluster_name" {
  type = string
}

variable "identity_pool_id" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "registry_name" {
  type = string
}
