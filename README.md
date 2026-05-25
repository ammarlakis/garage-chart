# Garage Helm Chart

Helm chart for deploying [Garage](https://garagehq.deuxfleurs.fr/) on Kubernetes, with an optional web UI for browsing S3 buckets.

## Installation

```bash
helm repo add ammarlakis https://ammarlakis.github.io/helm-charts
helm repo update
helm install garage ammarlakis/garage
```

## Garage UI

The web UI is packaged in the same chart and is disabled by default. Enable it with:

```yaml
ui:
  enabled: true
  s3:
    existingSecret: garage-ui-s3-credentials
```

The credentials Secret must contain the keys configured by `ui.s3.accessKeyKey` and `ui.s3.secretAccessKeyKey`.

## Production Values

The chart includes `charts/garage/values.production.example.yaml` with a production-oriented baseline for persistence, resources, probes, ingress, monitoring, topology spread constraints, PodDisruptionBudgets, and the optional UI. Values are validated by `charts/garage/values.schema.json`.

## Release

Run `just release` to prepare a chart release locally. Pushing a `v*` tag triggers the release workflow, uploads the packaged chart to GitHub Releases, and dispatches the Helm registry update workflow.

## License

This project is licensed under the MIT License.
