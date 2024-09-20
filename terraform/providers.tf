provider "flux" {
  kubernetes = {
    host                   = module.gke_auth.host
    token                  = module.gke_auth.token
    cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  }
  git = {
    url = "https://github.com/${var.github_org}/${var.github_repository}.git"
    http = {
      username = "git"
      password = var.github_token
    }
  }
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "google" {
  project = var.project_id
  region  = var.region
  access_token = var.access_token
}