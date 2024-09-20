# podman
# apple silicon virtualization framework

# Install tfenv opentofu flux k9s age sops tfctl

# tfenv 
# https://github.com/tfutils/tfenv
```brew install tfenv```

# flux cli
curl -s https://fluxcd.io/install.sh | bash
. <(flux completion zsh)

# SOPS: Secrets OPerationS
# encrypted files that supports YAML, JSON, ENV, INI and BINARY formats 
# and encrypts with AWS KMS, GCP KMS, Azure Key Vault, age, and PGP
https://github.com/getsops/sops/releases

# age is a simple, modern and secure file encryption tool, format, and Go library.
# https://github.com/FiloSottile/age
brew install age rage

# kubectl & k9s
alias k=kubectl
go install github.com/kubecolor/kubecolor@latest
alias kubectl=kubecolor
compdef kubecolor=kubectl
curl -sS https://webi.sh/k9s | sh
alias kk="EDITOR='code --wait' ~/.local/opt/k9s-v0.32.5/bin/k9s"

# tfctl
# https://flux-iac.github.io/tofu-controller/tfctl/
brew install weaveworks/tap/tfctl

# Initialize provisioning cluster

curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_ENABLE=true sh -
sudo k3s server --snapshotter native > /dev/null 2>&1&
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml 
sudo chmod o+r /etc/rancher/k3s/k3s.yaml


# Create a HelmRepository and HelmRelease resources for the tf-controller Helm chart
# https://github.com/flux-iac/tofu-controller

# Crete HelmRepository
flux create source helm tf-controller \
    --url=oci://ghcr.io/flux-iac/charts \
    --interval=1h0s \
    -n flux-system --export

# Create helm release tf-controller
flux create hr tf-controller -n flux-system \
    --interval=5m \
    --source=HelmRepository/tf-controller \
    --chart=tf-controller \
    --chart-version="0.16.0-rc.4" \
    --crds CreateReplace --export

## Explore terrafrom code for GKE cluster with gpu

https://github.com/den-vasyliev/fwdays-workshop/blob/tf-controller/tf-gke-cluster/main.tf


# Prepare the SOPS secret
## Generate a new age key
rm ~/.ssh/age-key.txt
age-keygen -o ~/.ssh/age-key.txt

## Create a Kubernetes secret for the age key
cat ~/.ssh/age-key.txt |
k create secret generic sops-agekey-secret \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin

## Export the public key
export AGE_PUB_KEY=age1luqthsd4r5wc09l989s5yuudcrxfkrd9fka502vqvylk3xa29e9qkre4n3


# Create a Kubernetes secret for GCP authentication
## Create service account
## Create a service account key
## Create a Kubernetes secret for the service account key
gcloud auth application-default login

k create secret -n flux-system  generic gcp-auth-secret \
    --from-file=credentials=${HOME}/.config/gcloud/application_default_credentials.json \
    -o yaml --dry-run=client> clusters/k3s/secrets/gcp-auth-secret.yaml

## Encrypt the secret using SOPS and the age key
sops --age=$AGE_PUB_KEY \
    --encrypt \
    --encrypted-regex '^(data|stringData)$' \
    --in-place clusters/k3s/secrets/gcp-auth-secret.yaml

## Enable decryption in flux with kustomization.yaml patch

### clusters/k3s/flux-system/kustomization.yaml
patches:
- path: sops-patch.yaml
  target:
    kind: Kustomization

### clusters/k3s/flux-system/sops-patch.yaml    
flux create kustomization flux-system \
--source=flux-system \
--path=./clusters/k3s \
--prune=true \
--interval=10m \
--decryption-provider=sops \
--decryption-secret=sops-agekey-secret --export

# export the github token
export GITHUB_TOKEN=$(gh auth token)

# Terraform with GitOps
flux push artifact oci://ghcr.io/den-vasyliev/fw-bootstrap:$(git rev-parse --short HEAD) \
    --creds $GITHUB_USER:$GITHUB_TOKEN \
    --path="./terraform" \
    --source="$(git config --get remote.origin.url)" \
    --revision="$(git branch --show-current)/$(git rev-parse HEAD)"

# tag the artifact
flux tag artifact oci://ghcr.io/den-vasyliev/fw-bootstrap:$(git rev-parse --short HEAD) \
--tag main --creds $GITHUB_USER:$GITHUB_TOKEN 

# Create a Terraform oci source
flux create source oci bootstrap-gke-oci \
--url=oci://ghcr.io/den-vasyliev/fw-bootstrap \
--tag=main \
--secret-ref=ghcr-secret \
--interval=1m --export

# Create a Github registy secret
kubectl create secret docker-registry ghcr-login-secret \
  --namespace=flux-system \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USER \
  --docker-password=$GITHUB_TOKEN \
  --docker-email=den.vasyliev\@gmail.com \
  --dry-run=client -o yaml > clusters/k3s/secrets/ghcr-secret.yaml

  # Encrypt the secret using SOPS and the age key
sops --age=$AGE_PUB_KEY \
    --encrypt \
    --encrypted-regex '^(data|stringData)$' \
    --in-place clusters/k3s/secrets/ghcr-secret.yaml

# Create a Terraform resource
apiVersion: infra.contrib.fluxcd.io/v1alpha2
kind: Terraform
metadata:
  name: <NAME>
spec:
  path: ./
  approvePlan: ""
  interval: 1m
  storeReadablePlan: human
  sourceRef:
    kind: OCIRepository
    name: <NAME>

# terraform plan
k describe secret tfplan-default-bootstrap-gke-tf -n flux-system
kubectl get secret tfplan-default-bootstrap-gke-tf -n flux-system -o jsonpath="{.data.tfplan}" | base64 --decode | gunzip>plan
tfenv install 1.5.7
tfenv use 1.5.7

tfctl show plan -n flux-system bootstrap-gke-tf 


## Bootstrap the ollama setup on new cluster
# finally apply 

# flux create source git ollama -n default --url=https://github.com/den-vasyliev/fw-non-prod --branch=main --interval=5m --export
# flux create source git ollama -n default --url=https://github.com/den-vasyliev/fw-non-prod --branch=main --interval=5m


flux get all -A --status-selector ready=false
