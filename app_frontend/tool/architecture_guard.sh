#!/usr/bin/env sh
# Architecture guard (docs/app/LINTING_AND_QUALITY.md §2.3): rules lints cannot express.
set -e
cd "$(dirname "$0")/.."
fail=0
# Legacy files from the first prototype (not imported anywhere; excluded in analysis_options.yaml).
# Delete them, then drop this filter.
legacy='lib/app/router.dart|lib/app/theme.dart|lib/core/(air|api_client|config|geo|i18n|prefs).dart|lib/features/auth/[a-z_]+\.dart|lib/features/(citizen|driver|hub)/|lib/features/school/[a-z_]+\.dart|lib/features/settings/settings_screen.dart|lib/widgets/'
if grep -rn "package:hawa_api" lib | grep -v -E "lib/features/[a-z_]+/data/|lib/core/network/" | grep -v -E "$legacy"; then
  echo "hawa_api imported outside data/ or core/network/"; fail=1
fi
if grep -rn "tile.openstreetmap.org" lib android ios | grep -v -E "$legacy"; then echo "OSM tile server referenced"; fail=1; fi
if grep -n "ACCESS_BACKGROUND_LOCATION" android/app/src/main/AndroidManifest.xml; then
  echo "background location requested"; fail=1
fi
if grep -rn "/data/" lib/features/*/presentation | grep -v -E "$legacy"; then echo "presentation imports data"; fail=1; fi
exit $fail
