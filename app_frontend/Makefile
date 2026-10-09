FLAVOR ?= dev
API_URL ?= http://localhost:8000
OPENAPI_GENERATOR_IMAGE ?= openapitools/openapi-generator-cli:v7.17.0
FLUTTER ?= fvm flutter
DART ?= fvm dart
DART_SRC = git ls-files --cached --others --exclude-standard '*.dart' | grep -v -E '\.g\.dart$$|\.freezed\.dart$$|\.drift\.dart$$|^packages/hawa_api/|^lib/app/l10n/gen/|^tool/mock_server/'

setup:        ; fvm install && $(FLUTTER) pub get && $(MAKE) gen
gen:          ; $(FLUTTER) gen-l10n && $(DART) run build_runner build
watch:        ; $(DART) run build_runner watch
l10n:         ; $(FLUTTER) gen-l10n && $(DART) run tool/check_untranslated.dart
format:       ; $(DART_SRC) | xargs $(DART) format
format-check: ; $(DART_SRC) | xargs $(DART) format --output=none --set-exit-if-changed
analyze:      ; $(FLUTTER) analyze --fatal-infos
# custom_lint/riverpod_lint: see analysis_options.yaml (no release resolves on Dart 3.12).
guard:        ; sh tool/architecture_guard.sh
lint:         format-check analyze guard
fix:          ; $(DART) fix --apply && $(MAKE) format
test:         ; $(FLUTTER) test --coverage
golden:       ; $(FLUTTER) test --tags golden --update-goldens
it:           ; $(FLUTTER) test integration_test/flow_b_driver_test.dart --flavor dev --dart-define-from-file=env/dev.json
run:          ; $(FLUTTER) run --flavor $(FLAVOR) --dart-define-from-file=env/$(FLAVOR).json
apk:          ; $(FLUTTER) build apk --flavor $(FLAVOR) --dart-define-from-file=env/$(FLAVOR).json --split-per-abi
mock-server:  ; cd tool/mock_server && $(DART) pub get && $(DART) run bin/server.dart --port 8081
gen-api:
	curl -fsS $(API_URL)/openapi.json -o openapi/openapi.json
	$(MAKE) gen-api-local
# Regenerates packages/hawa_api from the committed openapi/openapi.json snapshot.
gen-api-local:
	docker run --rm -v "$(CURDIR):/local" $(OPENAPI_GENERATOR_IMAGE) generate \
	  -i /local/openapi/openapi.json -o /local/packages/hawa_api -c /local/openapi/generator-config.yaml
	cd packages/hawa_api && $(DART) pub get && $(DART) run build_runner build
.PHONY: setup gen watch l10n format format-check analyze guard lint fix test golden it run apk mock-server gen-api gen-api-local
