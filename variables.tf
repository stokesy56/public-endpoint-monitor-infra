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

variable "service_account_id_ci" {
  type = string
}

variable "service_account_name_ci" {
  type = string
}

variable "service_account_id_argo" {
  type = string
}

variable "service_account_name_argo" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_repository_argo" {
  type = string
}

variable "registry_name" {
  type = string
}

variable "helm_id" {
  type = string
}

variable "helm_chart" {
  type = string
}

variable "helm_version" {
  type = string
}