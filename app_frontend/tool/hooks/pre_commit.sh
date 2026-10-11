#!/usr/bin/env bash
# app_frontend/tool/hooks/pre_commit.sh: format check on staged Dart files + analyze when any are
# staged. Called from the repo-root hook manager.
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
files="$(git -C "$root" diff --cached --name-only --diff-filter=ACMR -- 'app_frontend/*.dart' \
  | grep -v -E '\.g\.dart$|\.freezed\.dart$|\.drift\.dart$|^app_frontend/packages/hawa_api/|^app_frontend/lib/app/l10n/gen/|^app_frontend/tool/mock_server/' || true)"
[ -z "$files" ] && exit 0
cd "$root/app_frontend"
echo "$files" | sed 's#^app_frontend/##' | xargs fvm dart format --output=none --set-exit-if-changed \
  || { echo "dart format would change files. Run: make format"; exit 1; }
fvm flutter analyze --fatal-infos --no-pub
sh tool/architecture_guard.sh
