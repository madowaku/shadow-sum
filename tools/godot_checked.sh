#!/usr/bin/env bash
# Godot can exit zero after script/compile errors. Treat diagnostics as failures.
set -euo pipefail
log=$(mktemp)
trap 'rm -f "$log"' EXIT
godot "$@" 2>&1 | tee "$log"
if grep -Eq 'SCRIPT ERROR:|SHADER ERROR:|(^|[[:space:]])ERROR:' "$log"; then
  echo "Godot emitted error diagnostics despite a zero exit code." >&2
  exit 1
fi
