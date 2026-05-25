Upstream source: `https://github.com/deuxfleurs-org/garage`

Vendored chart path upstream: `script/helm/garage`

Version currently vendored:

- chart `0.9.2`
- app `v2.2.0`
- upstream branch `main-v2`

Local changes:

- The former `garage-ui` chart is merged into this chart under `ui.*` values.
- `charts/garage/templates/ui-*.yaml` are local templates and are not part of the upstream Garage chart.
- `image.tag` is explicit so Renovate can update and pin the Garage container digest.

Update process:

1. Fetch the upstream repo to a temporary directory.
2. Replace the upstream-managed Garage files in `charts/garage/` with the contents of `script/helm/garage/`.
3. Reapply or preserve the local `ui.*` values and `templates/ui-*.yaml` files.
4. Keep this file, and update the version notes above.
5. Review the diff, especially `values.yaml` compatibility.
6. Run `helm template garage ./charts/garage`.
