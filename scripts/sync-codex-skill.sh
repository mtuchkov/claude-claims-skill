#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/plugins/claims/skills/claims"
DST_DIR="${ROOT_DIR}/skills/claims"

mkdir -p "${DST_DIR}/references" "${DST_DIR}/examples"

cp "${SRC_DIR}/SKILL.md" "${DST_DIR}/SKILL.md"
cp "${SRC_DIR}/references/format.md" "${DST_DIR}/references/format.md"
cp "${SRC_DIR}/examples/sample-output.md" "${DST_DIR}/examples/sample-output.md"

echo "Synced Codex skill bundle into ${DST_DIR}"
