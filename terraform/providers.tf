provider "flux" {
  kubernetes = {
    host                   = gke_cluster.this.endpoint
    client_certificate     = gke_cluster.this.client_certificate
    client_key             = gke_cluster.this.client_key
    cluster_ca_certificate = gke_cluster.this.cluster_ca_certificate
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
