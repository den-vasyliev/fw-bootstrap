## Tools Installation

### tfenv
[tfenv](https://github.com/tfutils/tfenv) - Terraform Version Manager
```bash
brew install tfenv
```

### Flux CLI
Flux CLI for GitOps.
```bash
curl -s https://fluxcd.io/install.sh | bash
. <(flux completion zsh)
```

### SOPS: Secrets OPerationS
SOPS allows for encrypted files that support YAML, JSON, ENV, INI, and BINARY formats, with encryption options via AWS KMS, GCP KMS, Azure Key Vault, age, and PGP. 
[More about SOPS](https://github.com/getsops/sops/releases)

### age
A simple, modern, and secure file encryption tool.
```bash
brew install age rage
```

### kubectl & k9s
```bash
alias k=kubectl
go install github.com/kubecolor/kubecolor@latest
alias kubectl=kubecolor
compdef kubecolor=kubectl
curl -sS https://webi.sh/k9s | sh
alias kk="EDITOR='code --wait' ~/.local/opt/k9s-v0.32.5/bin/k9s"
```

### tfctl
[tfctl](https://flux-iac.github.io/tofu-controller/tfctl/) - Tool for managing Terraform controllers.
```bash
brew install weaveworks/tap/tfctl
```

## Initialize Provisioning Cluster
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_ENABLE=true sh -
sudo k3s server --snapshotter native > /dev/null 2>&1&
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml 
sudo chmod o+r /etc/rancher/k3s/k3s.yaml
```

## Create Helm Resources for tf-controller
### HelmRepository
```bash
flux create source helm tf-controller \
    --url=oci://ghcr.io/flux-iac/charts \
    --interval=1h0s \
    -n flux-system --export
```

### HelmRelease
```bash
flux create hr tf-controller -n flux-system \
    --interval=5m \
    --source=HelmRepository/tf-controller \
    --chart=tf-controller \
    --chart-version="0.16.0-rc.4" \
    --crds CreateReplace --export
```

## Explore Terraform Code for GKE Cluster with GPU
Check the example [here](./terraform/).

## Prepare the SOPS Secret

### Generate a New Age Key
```bash
rm ~/.ssh/age-key.txt
age-keygen -o ~/.ssh/age-key.txt
```

### Create a Kubernetes Secret for the Age Key
```bash
cat ~/.ssh/age-key.txt | k create secret generic sops-agekey-secret \
--namespace=flux-system --from-file=age.agekey=/dev/stdin
```

### Export the Public Key
```bash
export AGE_PUB_KEY=age1...
```

## Create a Kubernetes Secret for GCP Authentication
#### Steps:
1. Create service account.
2. Create service account key.
3. Create a Kubernetes secret for the service account key

or use `gcloud auth application-default login` to authenticate with GCP.
```bash
gcloud auth application-default login

k create secret -n flux-system generic gcp-auth-secret \
    --from-file=credentials=${HOME}/.config/gcloud/application_default_credentials.json \
    -o yaml --dry-run=client > clusters/k3s/secrets/gcp-auth-secret.yaml
```

### Encrypt the Secret Using SOPS and the Age Key
```bash
sops --age=$AGE_PUB_KEY \
    --encrypt \
    --encrypted-regex '^(data|stringData)$' \
    --in-place clusters/k3s/secrets/gcp-auth-secret.yaml
```

### Enable Decryption in Flux with `kustomization.yaml` Patch
#### `clusters/k3s/flux-system/kustomization.yaml`
```yaml
patches:
- path: sops-patch.yaml
  target:
    kind: Kustomization
```

#### `clusters/k3s/flux-system/sops-patch.yaml`
```bash
flux create kustomization flux-system \
--source=flux-system \
--path=./clusters/k3s \
--prune=true \
--interval=10m \
--decryption-provider=sops \
--decryption-secret=sops-agekey-secret --export
```

## Export the GitHub Token
```bash
export GITHUB_TOKEN=$(gh auth token)
```

## Terraform with GitOps
Push artifact to OCI.
```bash
flux push artifact oci://ghcr.io/den-vasyliev/fw-bootstrap:$(git rev-parse --short HEAD) \
    --creds $GITHUB_USER:$GITHUB_TOKEN \
    --path="./terraform" \
    --source="$(git config --get remote.origin.url)" \
    --revision="$(git branch --show-current)/$(git rev-parse HEAD)"
```

### Tag the Artifact
```bash
flux tag artifact oci://ghcr.io/den-vasyliev/fw-bootstrap:$(git rev-parse --short HEAD) \
--tag main --creds $GITHUB_USER:$GITHUB_TOKEN 
```

### Create a Terraform OCI Source
```bash
flux create source oci bootstrap-gke-oci \
--url=oci://ghcr.io/den-vasyliev/fw-bootstrap \
--tag=main \
--secret-ref=ghcr-secret \
--interval=1m --export
```

### Create a GitHub Registry Secret
```bash
kubectl create secret docker-registry ghcr-login-secret \
  --namespace=flux-system \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USER \
  --docker-password=$GITHUB_TOKEN \
  --docker-email=den.vasyliev@gmail.com \
  --dry-run=client -o yaml > clusters/k3s/secrets/ghcr-secret.yaml
```

### Encrypt the Secret Using SOPS and the Age Key
```bash
sops --age=$AGE_PUB_KEY \
    --encrypt \
    --encrypted-regex '^(data|stringData)$' \
    --in-place clusters/k3s/secrets/ghcr-login-secret.yaml
```

### Create a Terraform Resource and push it
```yaml
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
```

## Terraform Plan
```bash
k describe secret tfplan-default-bootstrap-gke-tf -n flux-system
kubectl get secret tfplan-default-bootstrap-gke-tf -n flux-system -o jsonpath="{.data.tfplan}" | base64 --decode | gunzip > plan
tfenv install 1.5.7
tfenv use 1.5.7

tfctl show plan -n flux-system bootstrap-gke-tf 
```

## Bootstrap the Ollama Setup on New Cluster
Finally, apply:
```bash
flux create source git ollama -n default --url=https://github.com/den-vasyliev/fw-non-prod --branch=main --interval=5m --export
```
And then:
```bash
flux create source git ollama -n default --url=https://github.com/den-vasyliev/fw-non-prod --branch=main --interval=5m
```

## Check Flux Status
```bash
flux get all -A --status-selector ready=false
```
