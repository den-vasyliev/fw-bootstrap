terraform {
  required_version = ">= 1.5.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.3.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.3.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.1"
    }
  }
}