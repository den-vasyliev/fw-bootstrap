# Install opentofu flux k9s age sops

# Initialize provisioning cluster

# Create a HelmRepository and HelmRelease resources for the tf-controller Helm chart
flux create source helm tf-controller --url=oci://ghcr.io/flux-iac/charts --interval=1h0s -n flux-system --export

# Create helm release tf-controller
flux create hr tf-controller -n flux-system --interval=5m --source=HelmRepository/tf-controller --chart=tf-controller --chart-version="0.16.0-rc.4" --crds CreateReplace --export


## Explore terrafrom code for tls keys module

https://github.com/den-vasyliev/fwdays-workshop/blob/tf-controller/tf-gke-cluster/tf-tls-keys-gr.yaml
https://github.com/den-vasyliev/tf-hashicorp-tls-keys

## terrafrom CR
https://github.com/den-vasyliev/fwdays-workshop/blob/tf-controller/tf-gke-cluster/tls-keys-tf.yaml


## Explore terrafrom code for GKE cluster with gpu

https://github.com/den-vasyliev/fwdays-workshop/blob/tf-controller/tf-gke-cluster/main.tf


# Prepare the SOPS secret
## Generate a new age key
rm ~/.ssh/age-key.txt
age-keygen -o ~/.ssh/age-key.txt

## Create a Kubernetes secret for the age key
cat ~/.ssh/age-key.txt |
k create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin

## Export the public key
export AGE_PUB_KEY=age1luqthsd4r5wc09l989s5yuudcrxfkrd9fka502vqvylk3xa29e9qkre4n3


# Create a Kubernetes secret for GCP authentication
## Create service account
## Create a service account key
## Create a Kubernetes secret for the service account key
gcloud auth application-default login

k create secret -n flux-system  generic gcp-secret --from-file=credentials=${$HOME}/.config/gcloud/application_default_credentials.json -o yaml --dry-run=client>gcp-auth-secret.yaml
#k create secret -n flux-system  generic k8s-k3s-secret --from-file=credentials=../../k8s-k3s-2cbd0214240e.json -o yaml --dry-run=client>k8s-k3s-secret.yaml

## Encrypt the secret using SOPS and the age key
sops --age=$AGE_PUB_KEY --encrypt --encrypted-regex '^(data|stringData)$' --in-place gcp-auth-secret.yaml

## Enable decryption in flux with kustomization.yaml patch
clusters/k3s/flux-system/kustomization.yaml
patches:
- path: sops-patch.yaml
  target:
    kind: Kustomization
clusters/k3s/flux-system/sops-patch.yaml    
flux create kustomization flux-system \
--source=flux-system \
--path=./clusters/k3s \
--prune=true \
--interval=10m \
--decryption-provider=sops \
--decryption-secret=sops-age --export


# Terraform with GitOps
## Create git source for the tf-config repository
flux create source git tf-config -n flux-system --url=https://github.com/den-vasyliev/fwdays-workshop --branch=tf-controller --interval=5m --export

## Create kustomization for the tf-config repository
flux bootstrap git \
  --url=https://github.com/den-vasyliev/fwdays-workshop \
  --branch=tf-controller \
  --path=tf-gke-cluster \
  --token-auth

k get tf -A

## Bootstrap the ollama setup on new cluster
# finally apply 

# flux create source git ollama -n default --url=https://github.com/den-vasyliev/fw-non-prod --branch=main --interval=5m --export
# flux create source git ollama -n default --url=https://github.com/den-vasyliev/fw-non-prod --branch=main --interval=5m


# On new cluster
flux bootstrap git \
  --url=https://github.com/den-vasyliev/fw-non-prod \
  --branch=main \
  --path=clusters/my-cluster \
  --token-auth --export

flux get all -A --status-selector ready=false
