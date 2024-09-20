---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: bootstrap-gke-oci
  namespace: flux-system
spec:
  interval: 1m0s
  provider: generic
  secretRef:
    name: ghcr-login-secret
  ref:
    tag: main
  url: oci://ghcr.io/den-vasyliev/fw-bootstrap