# Linting and quality

> **Status (as built).** The quality gates are the `app_frontend/Makefile` targets: `format-check`, `analyze` (`--fatal-infos`), `guard` (`tool/architecture_guard.sh`), `lint` (all three) and `test` (`flutter test --coverage`). `analysis_options.yaml` uses `very_good_analysis`; `custom_lint`/`riverpod_lint` are disabled because no release resolves on Dart 3.12.
>
> Gaps:
> - There is no `.github/` CI and no repo-root hook manager, although `tool/hooks/pre_commit.sh` expects one.
> - `make it` and `make golden` point at tests that do not exist.
>
> Not run by the reviewer, because no Flutter SDK was available.


Purpose: the lint, format, hook, commit, CI and testing rules for `app_frontend/`, plus the review checklist and Definition of Done. **Lints must pass with zero issues.**

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [STRUCTURE](STRUCTURE.md) · [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) · [PLAN](PLAN.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md) · [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)

---

## 1. Quality gates at a glance

| Gate | Command | Where | Blocking |
|---|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed <non-generated files>` | pre-commit (staged), CI | yes |
| Static analysis | `flutter analyze --fatal-infos` | pre-commit, CI | yes (zero infos, warnings, errors) |
| Riverpod lints | `dart run custom_lint` | CI (and IDE) | yes |
| Architecture guard | grep rules (§2.3) | CI | yes |
| Translations | `flutter gen-l10n` + `tool/check_untranslated.dart` | CI | yes (no missing `hi`) |
| Tests | `flutter test --coverage` | CI | yes |
| Coverage | ≥ 60 % lines on non-generated code (hackathon), raising to 75 % after | CI | yes |
| Build | `flutter build apk --flavor dev` | CI | yes |
| APK size | arm64 split APK ≤ 25 MB | CI | warning during the hackathon, blocking after |
| Commit message | Conventional Commits | commit-msg hook | yes |

## 2. `analysis_options.yaml`

### 2.1 File sketch

```yaml
# app_frontend/analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

formatter:
  page_width: 100                 # read by `dart format` on Dart >= 3.7 (see §4)

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.drift.dart"
    - "lib/app/l10n/gen/**"
    - "lib/firebase/firebase_options_*.dart"
    - "packages/hawa_api/**"
    - "build/**"
  plugins:
    - custom_lint
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore   # freezed: @JsonKey on factory constructor params is intended

linter:
  rules:
    public_member_api_docs: false       # app code, not a published package (see §2.2)
    lines_longer_than_80_chars: false   # we format at 100 columns
    sort_pub_dependencies: false        # `flutter pub add` ordering is fine; no signal
    require_trailing_commas: false      # Dart >= 3.7 formatter owns trailing commas; rule fights it
```

`very_good_analysis` already enables strict language modes and a large rule set. The `language:` block above is explicit so it survives an upstream change. Keep `packages/hawa_api/analysis_options.yaml` as generated: that package is excluded from the app's analysis, and its own analysis isn't a gate.

### 2.2 Rules we relax, and why

| Rule | Decision | Why |
|---|---|---|
| `public_member_api_docs` | off | App code with feature-local public classes. Docs on every public member add noise without readers. **Do** document non-obvious domain rules (e.g. completion-source precedence) with `///` |
| `lines_longer_than_80_chars` | off | We format at 100 (§4). The formatter enforces width, so the lint would duplicate it |
| `sort_pub_dependencies` | off | Low value, churns diffs |
| `require_trailing_commas` | off (if enabled by the pinned version) | The Dart ≥ 3.7 "tall" formatter adds and removes trailing commas itself |
| `avoid_classes_with_only_static_members` | off only if the pinned version enables it | We use `abstract final class Routes`, `Env` and `ApiPaths` as namespaces |
| Everything else in very_good_analysis | **on** | Includes `always_use_package_imports`, `avoid_print`, `unawaited_futures`, `prefer_const_constructors`, `avoid_dynamic_calls`, `cast_nullable_to_non_nullable` and more |

Never add `// ignore:` or `// ignore_for_file:` without a trailing reason comment. Review rejects bare ignores.

### 2.3 Architecture guard (CI grep rules)

These are rules lints can't express. They run as one CI step (§9) and fail the build on a match.

| Rule | Check |
|---|---|
| Generated client only in the data layer | `grep -rn "package:hawa_api" lib \| grep -v -E "lib/features/[a-z_]+/data/\|lib/core/network/"` must be empty |
| No OSM tile servers | `grep -rn "tile.openstreetmap.org" lib android ios` must be empty |
| No background location | `grep -n "ACCESS_BACKGROUND_LOCATION" android/app/src/main/AndroidManifest.xml` must be empty |
| No hand edits to generated client | regenerate from `openapi/openapi.json` and `git diff --exit-code packages/hawa_api` (optional job) |
| No presentation → data imports | `grep -rn "/data/" lib/features/*/presentation` must be empty |

## 3. `custom_lint` + `riverpod_lint`

- `custom_lint` and `riverpod_lint` are dev dependencies. The analyzer plugin is registered in `analysis_options.yaml` (`plugins: [custom_lint]`), so riverpod diagnostics show in the IDE.
- **CI runs `dart run custom_lint` separately.** `flutter analyze` does not always surface plugin diagnostics.
- All riverpod_lint rules are on by default. Examples (names per the pinned version's README): provider dependency checks, `avoid_public_notifier_properties`, rules against using `BuildContext` in providers, and rules for generated-provider correctness. Disable a rule only in `analysis_options.yaml` under `custom_lint: rules:` with a comment.
- If the pinned `riverpod_lint` has moved to the Dart analyzer plugin system (a top-level `plugins:` entry for the package itself), follow its README. The `dart run custom_lint` step is then replaced by `flutter analyze`, which reports plugin diagnostics.

## 4. Formatting

- `dart format` at **page width 100**, set once in `analysis_options.yaml` (`formatter: page_width: 100`, supported on Dart ≥ 3.7) so the IDE, CLI and CI agree.
- **Why 100:** Riverpod + widget trees nest deeply, 80 columns wrap most `ref.watch(...)` lines, and 100 still fits side-by-side diffs on a laptop. One number for the whole app, never per-file.
- The CLI formats non-generated tracked files only (see `make format` / `make format-check` in [STRUCTURE §9.3](STRUCTURE.md#93-makefile)). Generated files are rewritten by their generators.
- IDE: format on save, `editor.rulers: [100]`.

## 5. `dart fix`

- `make fix` = `dart fix --apply` + format. Run it after bumping `very_good_analysis`, Flutter or Dart, and commit the result as its own `chore(app): dart fix` commit.
- `dart fix --dry-run` is a useful review aid, not a CI gate (`flutter analyze --fatal-infos` already fails on anything fixable).

## 6. Generated files

| Output | Generator | Committed | Analyzer | Format | Coverage |
|---|---|---|---|---|---|
| `*.g.dart`, `*.freezed.dart` | build_runner (json_serializable, freezed, riverpod_generator, drift_dev) | no (`.gitignore`) | excluded | excluded | excluded |
| `lib/app/l10n/gen/**` | `flutter gen-l10n` | no | excluded | excluded | excluded |
| `lib/firebase/firebase_options_*.dart` | flutterfire CLI | yes | excluded | excluded | excluded |
| `packages/hawa_api/**` | openapi-generator `dart-dio` + build_runner | **yes** (contract snapshot) | excluded | excluded | excluded |

CI runs `dart run build_runner build -d` and `flutter gen-l10n` **before** analysis and tests. A stale generated file is never the reason CI passes locally but fails remotely.

## 7. Pre-commit hooks

**One hook manager per repository.** The web team uses Husky + lint-staged ([SYSTEM_OVERVIEW §6](../SYSTEM_OVERVIEW.md#6-technology-stack-whole-system)). Two managers conflict (`core.hooksPath` vs `.git/hooks`), so the app ships a script that the root hook calls:

```sh
# .husky/pre-commit (repo root, shared with web; one added line, agreed with the web lead)
pnpm lint-staged
sh app_frontend/tool/hooks/pre_commit.sh
```

```bash
#!/usr/bin/env bash
# app_frontend/tool/hooks/pre_commit.sh: format check on staged Dart files + analyze when any are staged
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
files="$(git -C "$root" diff --cached --name-only --diff-filter=ACMR -- 'app_frontend/*.dart' \
  | grep -v -E '\.g\.dart$|\.freezed\.dart$|\.drift\.dart$|^app_frontend/packages/hawa_api/|^app_frontend/lib/app/l10n/gen/' || true)"
[ -z "$files" ] && exit 0
cd "$root/app_frontend"
echo "$files" | sed 's#^app_frontend/##' | xargs fvm dart format --output=none --set-exit-if-changed \
  || { echo "dart format would change files. Run: make format"; exit 1; }
# Analysis needs whole-program context, so it runs on the package, but only when Dart files are staged.
fvm flutter analyze --fatal-infos --no-pub
```

If the repo has no Husky setup when the app starts, use **lefthook at the repo root** with both web and app commands. Don't install two managers. Hooks are a convenience: CI is the gate, and `--no-verify` is never accepted as a reason for red CI.

## 8. Conventional commits

Format: `type(scope): imperative subject`, subject ≤ 72 characters.

| Type | Use |
|---|---|
| `feat` | user-visible feature |
| `fix` | bug fix |
| `refactor` | no behaviour change |
| `test` | tests only |
| `docs` | docs only |
| `chore` | tooling, deps, regenerated client |
| `ci` | workflow changes |
| `perf` | performance |
| `build` | Gradle, flavors, signing |

Scope for app work is `app`. Put the feature in the subject: `feat(app): driver stop auto-done overlay`, `fix(app): outbox keeps order per task after 409`, `chore(app): regenerate hawa_api`. A breaking change to a contract the app depends on is written `feat(app)!:` with a `BREAKING CHANGE:` footer. The web team's commitlint (if present) validates messages. Otherwise the commit-msg hook uses this regex: `^(feat|fix|refactor|test|docs|chore|ci|perf|build)(\(app\))?!?: .{1,72}$`.

## 9. CI workflow (`.github/workflows/app.yml`, repo root)

```yaml
name: app

on:
  pull_request:
    paths: ["app_frontend/**", ".github/workflows/app.yml"]
  push:
    branches: [main, dev]
    paths: ["app_frontend/**", ".github/workflows/app.yml"]
  workflow_dispatch:
    inputs:
      integration:
        description: "Run Flow B integration test on an emulator"
        type: boolean
        default: false

concurrency:
  group: app-${{ github.ref }}
  cancel-in-progress: true

defaults:
  run:
    working-directory: app_frontend

jobs:
  quality:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Read Flutter version from .fvmrc
        id: fvm
        run: echo "version=$(jq -r .flutter .fvmrc)" >> "$GITHUB_OUTPUT"

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.fvm.outputs.version }}
          channel: stable
          cache: true              # caches the SDK and the pub cache

      - run: flutter --version
      - run: flutter pub get
      - run: dart run build_runner build -d
      - run: flutter gen-l10n && dart run tool/check_untranslated.dart

      - name: Format check (non-generated files)
        run: |
          git ls-files '*.dart' \
            | grep -v -E '\.g\.dart$|\.freezed\.dart$|\.drift\.dart$|^packages/hawa_api/|^lib/app/l10n/gen/' \
            | xargs dart format --output=none --set-exit-if-changed

      - run: flutter analyze --fatal-infos
      - run: dart run custom_lint

      - name: Architecture guard
        run: |
          set -e
          ! grep -rn "package:hawa_api" lib | grep -v -E "lib/features/[a-z_]+/data/|lib/core/network/"
          ! grep -rn "tile.openstreetmap.org" lib android ios
          ! grep -n "ACCESS_BACKGROUND_LOCATION" android/app/src/main/AndroidManifest.xml
          ! grep -rn "/data/" lib/features/*/presentation

      - name: Tests with coverage
        run: flutter test --coverage --reporter expanded

      - uses: VeryGoodOpenSource/very_good_coverage@v3
        with:
          path: app_frontend/coverage/lcov.info
          min_coverage: 60
          exclude: "**/*.g.dart **/*.freezed.dart **/*.drift.dart lib/app/l10n/gen/** lib/firebase/**"

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: golden-failures
          path: app_frontend/test/**/failures/**
          if-no-files-found: ignore

  build-apk:
    needs: quality
    runs-on: ubuntu-latest
    timeout-minutes: 30
    if: ${{ github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository }}
    env:
      HAS_FIREBASE_SA: ${{ secrets.FIREBASE_SA_JSON != '' }}   # step-level env is not visible in a step's own `if`
    steps:
      - uses: actions/checkout@v4
      - id: fvm
        run: echo "version=$(jq -r .flutter .fvmrc)" >> "$GITHUB_OUTPUT"
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.fvm.outputs.version }}
          channel: stable
          cache: true
      - run: flutter pub get && dart run build_runner build -d && flutter gen-l10n

      - name: Write dev env + Firebase config from secrets
        env:
          MAP_API_KEY: ${{ secrets.MAP_API_KEY }}
          GOOGLE_SERVICES_DEV_B64: ${{ secrets.GOOGLE_SERVICES_DEV_B64 }}
        run: |
          jq --arg key "$MAP_API_KEY" '.MAP_API_KEY=$key | .USE_FAKE_API=true | .SHOW_DEV_TOOLS=true' \
            env/dev.json.example > env/dev.json
          mkdir -p android/app/src/dev
          echo "$GOOGLE_SERVICES_DEV_B64" | base64 -d > android/app/src/dev/google-services.json

      - name: Build dev APK (fake-API demo build, split per ABI)
        run: flutter build apk --flavor dev --dart-define-from-file=env/dev.json --split-per-abi

      - name: APK size budget (arm64 <= 25 MB)
        run: |
          apk=$(ls build/app/outputs/flutter-apk/*arm64-v8a*dev*release.apk | head -1)
          size=$(stat -c%s "$apk"); echo "arm64 APK: $((size/1024/1024)) MB"
          if [ "$size" -gt $((25*1024*1024)) ]; then echo "::warning::APK over 25 MB budget"; fi

      - uses: actions/upload-artifact@v4
        with:
          name: hawa-dev-apk-${{ github.sha }}
          path: app_frontend/build/app/outputs/flutter-apk/*.apk
          retention-days: 14

      - name: Firebase App Distribution (optional, dev branch only)
        if: ${{ github.ref == 'refs/heads/dev' && env.HAS_FIREBASE_SA == 'true' }}
        env:
          FIREBASE_SA: ${{ secrets.FIREBASE_SA_JSON }}
          FIREBASE_APP_ID_DEV: ${{ secrets.FIREBASE_APP_ID_DEV }}
        run: |
          echo "$FIREBASE_SA" > "$RUNNER_TEMP/sa.json"
          export GOOGLE_APPLICATION_CREDENTIALS="$RUNNER_TEMP/sa.json"
          apk=$(ls build/app/outputs/flutter-apk/*arm64-v8a*dev*release.apk | head -1)
          npx --yes firebase-tools appdistribution:distribute "$apk" \
            --app "$FIREBASE_APP_ID_DEV" --groups "field-testers" \
            --release-notes "dev ${GITHUB_SHA::7}"

  integration:
    needs: quality
    if: ${{ github.event_name == 'workflow_dispatch' && inputs.integration }}
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - id: fvm
        run: echo "version=$(jq -r .flutter .fvmrc)" >> "$GITHUB_OUTPUT"
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: "17" }
      - uses: subosito/flutter-action@v2
        with: { flutter-version: "${{ steps.fvm.outputs.version }}", channel: stable, cache: true }
      - name: Enable KVM
        working-directory: .
        run: |
          echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
          sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=kvm
      - run: flutter pub get && dart run build_runner build -d && flutter gen-l10n
      - name: Start mock server
        run: |
          cd tool/mock_server && dart pub get
          nohup dart run bin/server.dart --port 8081 > "$RUNNER_TEMP/mock.log" 2>&1 &
          for i in $(seq 1 30); do curl -fsS http://localhost:8081/healthz && break; sleep 1; done
      - name: CI env
        env:
          GOOGLE_SERVICES_DEV_B64: ${{ secrets.GOOGLE_SERVICES_DEV_B64 }}
        run: |
          jq '.API_BASE_URL="http://10.0.2.2:8081" | .WS_URL="ws://10.0.2.2:8081/v1/ws" | .USE_FAKE_API=false' \
            env/dev.json.example > env/ci.json
          mkdir -p android/app/src/dev
          echo "$GOOGLE_SERVICES_DEV_B64" | base64 -d > android/app/src/dev/google-services.json
      - uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          target: google_apis
          arch: x86_64
          working-directory: app_frontend
          script: flutter test integration_test/flow_b_driver_test.dart --flavor dev --dart-define-from-file=env/ci.json
```

Secrets used: `MAP_API_KEY`, `GOOGLE_SERVICES_DEV_B64`, optional `FIREBASE_SA_JSON` + `FIREBASE_APP_ID_DEV`. None of them are compiled into source control. The dev CI APK uses fake API mode, so testers can demo Flow B without a backend. A staging build against the real backend is produced locally or by a manual workflow when the staging API exists. Pin action major versions as shown and review Dependabot bumps.

## 10. Testing strategy

### 10.1 Pyramid

| Level | Share | What | Tools |
|---|---|---|---|
| Unit | ~70 % | Repositories, controllers, mappers, interceptors, outbox drainer + backoff + conflict resolver, `authRedirect`, deep-link allow-list, `advice_rules`, `ist_time` (en/hi day parts), AQI fallback, sampling policy, geofence | `flutter_test`, **mocktail**, `fake_async`, fake `Clock`, in-memory drift, `http_mock_adapter` |
| Widget | ~20 % | Every screen in each standard state (loading, empty, offline, stale, error, simulated), plus interactions | `pump_app.dart` helper with overridden providers |
| Golden | ~5 % | Key screens × en/hi × light/outdoor × text scale 1.0/2.0 | `matchesGoldenFile` with bundled fonts loaded in `flutter_test_config.dart` (or a maintained golden helper such as alchemist, if adopted) |
| Integration | ~5 % | Flow B on an emulator against `tool/mock_server`. Inspector offline outcome. Citizen Eyes offline submit | `integration_test`, robots |

### 10.2 Conventions

- **Mocks** use mocktail: `class _MockTaskRemote extends Mock implements TaskRemoteSource {}`, with `registerFallbackValue` for custom args in `setUpAll`. Don't mock drift: use `AppDatabase(NativeDatabase.memory())`.
- **Controllers** are tested through `ProviderContainer` with overrides. Never instantiate a notifier directly.

```dart
// test/features/driver_route/application/today_route_controller_test.dart (sketch)
test('skip enqueues a task_status op and overlays pending status', () async {
  final db = inMemoryDb();
  final remote = _MockTaskRemote();
  when(() => remote.fetchMine(any())).thenAnswer((_) async => fixtureTodayRoute());
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    taskRemoteSourceProvider.overrideWithValue(remote),
    clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026, 11, 13, 0, 50))),
  ]);
  addTearDown(container.dispose);

  await container.read(todayRouteControllerProvider.future);
  await container.read(todayRouteControllerProvider.notifier).skip('t2', SkipReason.roadBlocked);

  final ops = await db.outboxDao.pendingFor('task:t2');
  expect(ops.single.kind, OpKind.taskStatus);
  final route = await container.read(todayRouteControllerProvider.future);
  expect(route.stop('t2').pendingStatus, TaskStatus.skipped);
});
```

- **Fixtures** live in `assets/fixtures/`. They're shared by fake mode, tests and the mock server. A contract test deserializes every API fixture with the **generated `hawa_api` models**, so a fixture that drifts from OpenAPI fails CI.
- **Goldens** are generated on Linux (CI or a Linux container) only, so font rasterisation is consistent. Update with `make golden` and review the PNG diff in the PR. Required golden set:

| Screen | Variants |
|---|---|
| D1 Today's route | en/hi × light/outdoor × 1.0/2.0 |
| D3 Stop detail (auto-done + verified) | en/hi × outdoor |
| A4 OTP | en/hi × 2.0 |
| I3 Target detail | en/hi × outdoor |
| S1 School today | en/hi × light |
| C1 Air near me | en/hi × light |
| C7 Report status (closed) | en/hi × light |

- **Accessibility assertions** in widget tests: `expectLater(tester, meetsGuideline(androidTapTargetGuideline))`, `labeledTapTargetGuideline` and `textContrastGuideline` for D1, D3, I4, C5.

### 10.3 Invariant tests (must exist)

| Invariant | Test |
|---|---|
| Honesty: simulated items show the badge | Widget tests with `is_simulated: true` fixtures for D1, D3, I1, I3, S1, S2, C1 find `SimulatedBadge` per item |
| Uncertainty always shown | Forecast, safe window, verified chip and cause chip widgets render the range/confidence. A fixture without P10/P90 renders "range unavailable" |
| Location only during shift | `ShiftLocationTracker` never subscribes unless `shift.active`. `endShift()` cancels within 1 s. Merged manifest has no background location (CI grep) |
| EXIF stripped | `image_processor_test.dart`: output has no GPS/Make/Model EXIF tags |
| Phone numbers never shown | Inspector and report widgets rendered with fixtures containing phone-like fields show no `+91`/10-digit pattern in any `Text` |
| Idempotency | Drainer retries the same op 3 times → same `Idempotency-Key` header each time (captured by `http_mock_adapter`) |
| Auto-done wins over manual | Conflict resolver test (OFFLINE_AND_SYNC §7 rows 1–3) |
| Backend state machine respected | Driver controllers never enqueue `in_progress`. Manual done is offered only from `acknowledged`/`en_route` with the tag offline. Skip is hidden once `in_progress` |
| Design tokens mirror DESIGN_SYSTEM | `tokens_test.dart` compares `lib/app/theme/tokens.dart` with `../frontend/src/styles/tokens.json` when present |
| Unknown enums don't crash | Mapper tests with `"status": "brand_new_value"` → `TaskStatus.unknown`, rendered as "Unknown / पता नहीं" |

### 10.4 Flow B integration test (emulator + mock server)

1. Launch with `env/ci.json` (mock server on `10.0.2.2:8081`). Choose हिन्दी. Log in with OTP `123456` (mock accepts it).
2. Mock scenario `driver_morning`: `tasks/mine` returns 6 simulated stops. The test injects the `route_assignment` payload through `PushRouter.open(...)`, since FCM delivery itself is verified manually on a real phone.
3. Assert D1 shows 6 stops in order, the Simulated chip, and Hindi strings.
4. Tap **Start shift**. The location provider is overridden with a fake stream (or `adb emu geo fix`). Assert the shift bar shows "शिफ्ट चालू".
5. Move the fake location into stop 1's geofence → assert the local "arrived" card appears and that **no** `in_progress` status was posted (`GET /__mock/requests`). The server owns that transition.
6. `POST /__mock/emit` `task.in_progress`, then `task.done` (`source=hawatag`) for stop 1 → assert "Spraying…" then "HawaTag ने पूरा किया" within 2 s, and the hero advances to stop 2.
7. Inject a 503 ×3 on `/status`, skip stop 2 (reason road blocked) → assert eventual single apply and an empty outbox.
8. **End shift** → assert the tracker stopped and D6 counts are correct.

## 11. Code review checklist

- [ ] **Layers:** presentation imports no `data/`, `hawa_api`, `dio` or `drift`. Domain has no Flutter imports. Cross-feature access only via domain types/providers.
- [ ] **Generated client only:** no hand-written `/v1` HTTP calls. `packages/hawa_api` untouched except via `make gen-api`.
- [ ] **Mutations via outbox** with a UUIDv7 op id = `Idempotency-Key`, enqueued in the same transaction as the optimistic change. Ordering key and dependencies correct.
- [ ] **Offline:** the screen renders from cache, with offline/stale/error states handled ([SCREENS §0.1](SCREENS.md#01-standard-states-apply-to-every-data-screen-unless-the-screen-says-otherwise)).
- [ ] **Honesty:** `is_simulated` → badge. AQI labelled indicative. Model outputs show range/confidence. Manual/naive evidence labelled "lower evidence".
- [ ] **Contracts:** enum names and units exactly as CONTRACTS.md. An `unknown` fallback exists. Times stored UTC, displayed IST.
- [ ] **i18n:** every new string in `app_en.arb` **and** `app_hi.arb`, with `@description`. No concatenated sentences. Placeholders used.
- [ ] **Accessibility:** icon + word (never colour alone), ≥ 48 dp targets (64 dp primary in field shells), semantics labels, works at 200 % text.
- [ ] **Privacy:** no location outside shift. No PII in logs. No other user's phone rendered. Photos via `image_processor`.
- [ ] **Riverpod:** no `ref` use after `await` without `ref.mounted`. No state flags for one-shot events. `keepAlive` only for core singletons.
- [ ] **Navigation:** paths via `Routes.*` only. New deep-link patterns added to the allow-list.
- [ ] **Tests:** new logic has unit tests. New screens have widget tests for the standard states. Goldens updated for touched key screens.
- [ ] **Dependencies:** any new package has a maintenance/licence/size note. No GPL in the binary without sign-off.
- [ ] **Docs:** SCREENS.md or OFFLINE_AND_SYNC.md updated if behaviour changed. Contract gaps are raised as proposals, not hacked around.

## 12. Definition of Done

A change is done when **all** of these hold:

1. `make lint` passes with **zero** issues (format, analyze `--fatal-infos`, custom_lint) and the architecture guard passes.
2. `make test` is green. Coverage meets the threshold. New or changed logic has tests, including the relevant invariant tests (§10.3).
3. Goldens for touched key screens are regenerated (en + hi) and reviewed.
4. The screen's acceptance criteria in [SCREENS.md](SCREENS.md) are met and **demonstrated on a real Android phone** (release or profile build) for user-facing work, including one offline pass.
5. Every user-facing string exists in en and hi. `check_untranslated` is clean.
6. Simulated badge, indicative label and uncertainty display are present wherever the data calls for them.
7. No contract drift: fixtures parse with the generated models. Missing API needs are listed as contract proposals ([PLAN §11](PLAN.md#11-contract-proposals-to-raise)).
8. CI is green, including the dev APK build. The PR title is a Conventional Commit and the description lists any new packages and screenshots (en + hi).
