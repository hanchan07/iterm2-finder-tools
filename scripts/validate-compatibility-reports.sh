#!/bin/zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
schema="$repo_root/specs/001-modernize-macos-support/contracts/compatibility-report.schema.json"

if (( $# == 0 )); then
  set -- "$repo_root"/docs/compatibility/*.json
fi

npx --yes --package=ajv-cli@5.0.0 --package=ajv-formats@2.1.1 \
  ajv validate --spec=draft2020 -c ajv-formats -s "$schema" -d "$@"
