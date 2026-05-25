#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="charts/garage"
CHART_FILE="${CHART_DIR}/Chart.yaml"
CHART_README="${CHART_DIR}/README.md"
CHANGELOG_FILE="CHANGELOG.md"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Required file not found: $1" >&2
    exit 1
  fi
}

require_cmd git
require_cmd git-cliff
require_cmd helm
require_cmd helm-docs
require_cmd prettier
require_cmd python3

require_file "${CHART_FILE}"
require_file "${CHART_README}"
require_file "${CHART_DIR}/values.production.example.yaml"
require_file "${CHANGELOG_FILE}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit or stash changes before releasing." >&2
  exit 1
fi

release_push="${RELEASE_PUSH:-true}"
if [[ "${release_push}" != "false" ]]; then
  if ! git remote get-url origin >/dev/null 2>&1; then
    echo "No usable origin remote is configured. Set RELEASE_PUSH=false or add origin." >&2
    exit 1
  fi
fi

current_version="$(python3 - "${CHART_FILE}" <<'PY'
import sys
from pathlib import Path

for line in Path(sys.argv[1]).read_text().splitlines():
    if line.startswith("version:"):
        print(line.split(":", 1)[1].strip().strip('"'))
        break
else:
    raise SystemExit("Chart version not found")
PY
)"

if [[ -n "${RELEASE_VERSION:-}" ]]; then
  raw_version="${RELEASE_VERSION}"
elif git tag --list 'v[0-9]*' | grep -q .; then
  raw_version="$(git cliff --bumped-version)"
else
  raw_version="${current_version}"
fi

if [[ -z "${raw_version}" ]]; then
  echo "Could not determine next version" >&2
  exit 1
fi

if [[ "${raw_version}" == v* ]]; then
  tag="${raw_version}"
  new_version="${raw_version#v}"
else
  new_version="${raw_version}"
  tag="v${raw_version}"
fi

if [[ ! "${new_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]]; then
  echo "Release version must be SemVer-like: ${new_version}" >&2
  exit 1
fi

if git rev-parse "${tag}" >/dev/null 2>&1; then
  echo "Tag ${tag} already exists" >&2
  exit 1
fi

echo "Current chart version: ${current_version}"
echo "Preparing release: ${tag}"

python3 - "${new_version}" "${CHART_FILE}" <<'PY'
import sys
from pathlib import Path

version, chart_file = sys.argv[1:]
path = Path(chart_file)
lines = path.read_text().splitlines()

for index, line in enumerate(lines):
    if line.startswith("version:"):
        lines[index] = f"version: {version}"
        path.write_text("\n".join(lines) + "\n")
        break
else:
    raise SystemExit(f"Could not find chart version in {chart_file}")
PY

echo "Regenerating Helm docs..."
helm-docs

echo "Formatting chart README..."
prettier "${CHART_README}" -w

echo "Updating ${CHANGELOG_FILE} with git-cliff..."
git cliff --unreleased --tag "${tag}" --prepend "${CHANGELOG_FILE}"
python3 - "${CHANGELOG_FILE}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
content = path.read_text().rstrip() + "\n"
path.write_text(content)
PY

echo "Validating release files..."
git diff --check
helm lint "${CHART_DIR}"
helm lint "${CHART_DIR}" -f "${CHART_DIR}/values.production.example.yaml"
helm template garage "${CHART_DIR}" >/dev/null
helm template garage "${CHART_DIR}" -f "${CHART_DIR}/values.production.example.yaml" >/dev/null

git add "${CHART_FILE}" "${CHART_README}" "${CHART_DIR}/values.production.example.yaml" "${CHANGELOG_FILE}"

git commit --no-verify -m "chore(release): prepare for ${new_version} #ignore" || {
  echo "Nothing to commit; aborting" >&2
  exit 1
}

echo "Creating tag ${tag} on HEAD..."
git tag "${tag}"

if [[ "${release_push}" == "false" ]]; then
  echo "RELEASE_PUSH=false; leaving release commit and tag local."
else
  echo "Pushing commit and tag to origin..."
  git push origin HEAD
  git push origin "${tag}"
  echo "Tag push will trigger GitHub Release assets and Helm registry update."
fi

echo "Done. Released ${tag}."
