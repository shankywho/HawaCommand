#!/usr/bin/env sh
# Architecture guard (docs/app/LINTING_AND_QUALITY.md §2.3): rules lints cannot express.
set -e
cd "$(dirname "$0")/.."
fail=0
# The prototype theme still used by four citizen screens (excluded in analysis_options.yaml).
legacy='lib/app/theme.dart'
if grep -rn "package:hawa_api" lib | grep -v -E "lib/features/[a-z_]+/data/|lib/core/network/" | grep -v -E "$legacy"; then
  echo "hawa_api imported outside data/ or core/network/"; fail=1
fi
if grep -rn "tile.openstreetmap.org" lib android ios | grep -v -E "$legacy"; then echo "OSM tile server referenced"; fail=1; fi
if grep -n "ACCESS_BACKGROUND_LOCATION" android/app/src/main/AndroidManifest.xml; then
  echo "background location requested"; fail=1
fi
if grep -rn "/data/" lib/features/*/presentation | grep -v -E "$legacy"; then echo "presentation imports data"; fail=1; fi
exit $fail
