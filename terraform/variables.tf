variable "project_id" {
  description = "The project ID to deploy resources to"
}

variable "location" {
  description = "The location to deploy resources to"
  default     = "us-central1-a"

}

variable "region" {
  description = "The region to deploy resources to"
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  default     = "fw-cluster"

}

variable "machine_type" {
  description = "The machine type to use for the default node pool"
  default     = "e2-standard-4"
}

variable "zone" {
  description = "The zone to deploy resources to"
  default     = "us-central1-a"

}

variable "credentials" {
  description = "value of the credentials"
  type = string
  sensitive = true
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository"
  type        = string
}

variable "github_token" {
  description = "GitHub token"
  sensitive   = true
  type        = string
}
