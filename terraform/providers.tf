provider "flux" {
  kubernetes = {
    host                   = google_container_cluster.primary.endpoint
    client_certificate     = base64decode(google_container_cluster.primary.master_auth[0].client_certificate)
    client_key             = base64decode(google_container_cluster.primary.master_auth[0].client_key)
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
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
  project     = var.project_id
  region      = var.region
  credentials = var.credentials
}