# ==========================================
# Initialise a Github project
# ==========================================

resource "github_repository" "this" {
  name        = var.github_repository
  description = var.github_repository
  visibility  = "private"
  auto_init   = true

  # Enable vulnerability alerts
  vulnerability_alerts = true
}

# ==========================================
# Bootstrap Flux
# ==========================================

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository.this]

  embedded_manifests = true
  path               = "clusters/$${cluster.name}"
}