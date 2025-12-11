#!/usr/bin/env bash
set -euo pipefail

# Entrypoint for the ACE-Step container.
# - No args: show ACE-Step help
# - Option-style first arg (-*): forward to `acestep`
# - Otherwise: execute provided command

ACESTEP_CMD="acestep"

if [ "$#" -eq 0 ]; then
  exec "$ACESTEP_CMD" --help
fi

case "$1" in
  -*)
    exec "$ACESTEP_CMD" "$@"
    ;;
  *)
    exec "$@"
    ;;
esac
