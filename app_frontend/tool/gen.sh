#!/usr/bin/env bash
# Code generation (gen-l10n + build_runner) behind a directory lock, so concurrent runs in one
# checkout never corrupt .dart_tool/build. Usage: sh tool/gen.sh
set -euo pipefail
cd "$(dirname "$0")/.."
lock=.gen.lock
waited=0
until mkdir "$lock" 2>/dev/null; do
  sleep 3
  waited=$((waited + 3))
  if [ "$waited" -gt 900 ]; then echo "gen lock held for 15 min; remove $lock if stale" >&2; exit 1; fi
done
trap 'rmdir "$lock"' EXIT
flutter gen-l10n
dart run build_runner build
