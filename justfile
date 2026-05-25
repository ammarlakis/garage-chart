precommit:
    pre-commit install

release:
    ./scripts/release.sh

docs:
    helm-docs

fmt:
    prettier --write .

lint:
    helm lint charts/garage
    helm lint charts/garage -f charts/garage/values.production.example.yaml

template:
    helm template garage charts/garage

template-production:
    helm template garage charts/garage -f charts/garage/values.production.example.yaml
