# Source tree: `app_frontend/`

Purpose: the full folder and file layout of the Flutter app, with a one-line responsibility per file, plus platform notes and config file sketches.

Related: [README](README.md) · [ARCHITECTURE](ARCHITECTURE.md) · [SCREENS](SCREENS.md) · [OFFLINE_AND_SYNC](OFFLINE_AND_SYNC.md) · [LINTING_AND_QUALITY](LINTING_AND_QUALITY.md) · [../CONTRACTS.md](../CONTRACTS.md) · [../SYSTEM_OVERVIEW.md](../SYSTEM_OVERVIEW.md) · [../backend/API.md](../backend/API.md) · [../frontend/DESIGN_SYSTEM.md](../frontend/DESIGN_SYSTEM.md)

---

Legend: `(gen)` generated, not committed · `(gen, committed)` generated and committed · `(dev)` dev/staging only · `(STRETCH)` / `(VISION)` build tier.

## 1. Top level

```text
app_frontend/
├── .fvmrc                         # pinned Flutter version for FVM (latest stable at scaffold time)
├── .gitignore                     # build/, .dart_tool/, *.g.dart, *.freezed.dart, lib/app/l10n/gen/, env/*.json (not *.example), google-services.json
├── README.md                      # 10 lines: points to docs/app/README.md
├── pubspec.yaml                   # app package `hawa_app`; deps, fonts, assets (fixtures flavor-gated)
├── pubspec.lock                   # committed; pins every package version
├── analysis_options.yaml          # very_good_analysis + excludes + custom_lint plugin (LINTING_AND_QUALITY §2)
├── build.yaml                     # build_runner options for freezed, json_serializable, riverpod_generator, drift
├── l10n.yaml                      # gen-l10n config: ARB dir, output dir, untranslated report
├── dart_test.yaml                 # test tags: golden, integration, slow
├── Makefile                       # setup, gen, l10n, lint, fix, test, it, run, apk, gen-api, mock-server
├── env/
│   ├── dev.json.example           # local/fake config; copy to dev.json (gitignored)
│   ├── staging.json.example       # staging HTTPS endpoints, crash reporting on
│   └── prod.json.example          # prod endpoints, dev tools off
├── openapi/
│   ├── openapi.json               # committed snapshot of backend /openapi.json (input to make gen-api)
│   └── generator-config.yaml      # openapi-generator dart-dio options (pubName, serializationLibrary, enumUnknownDefaultCase)
├── packages/
│   └── hawa_api/                  # (gen, committed) generated API client; never edit by hand
├── assets/                        # fonts, images, dev fixtures (see §6)
├── lib/                           # app source (see §2–§4)
├── test/                          # unit, widget, golden tests (see §7)
├── integration_test/              # emulator flows against tool/mock_server (see §7)
├── tool/                          # mock server, hook script, l10n checker (see §7)
├── android/                       # Android host project (see §8)
└── ios/                           # iOS host project, secondary (see §9)

repo root (outside app_frontend/, owned by the app for CI only):
└── .github/workflows/app.yml      # CI with path filter app_frontend/** (LINTING_AND_QUALITY §9)
```

## 2. `lib/` entry and `lib/app/`

```text
lib/
├── main.dart                      # calls bootstrap(); no logic
├── bootstrap.dart                 # binding init; parallel Firebase init + DB open + prefs; error handlers; ProviderScope; runApp
├── firebase/
│   ├── firebase_options_dev.dart      # (gen, committed) flutterfire configure output for hawacommand-dev
│   ├── firebase_options_staging.dart  # (gen, committed) staging project
│   └── firebase_options_prod.dart     # (gen, committed) prod project
└── app/
    ├── app.dart                   # MaterialApp.router: theme modes (light/dark/outdoor), locale, delegates, builder (banners)
    ├── env.dart                   # Env: typed access to --dart-define-from-file values + startup validation
    ├── providers.dart             # root overrides: fake remote sources when USE_FAKE_API, clock, env
    ├── router/
    │   ├── router.dart            # keep-alive GoRouter provider; shells; refreshListenable bridge
    │   ├── routes.dart            # abstract final class Routes: path constants, builders, requiredRoleFor, homeFor
    │   ├── guards.dart            # authRedirect(): pure function of SessionState + Uri (unit tested)
    │   └── deep_links.dart        # hawa://{entity}/{id} → role route table + id validation for push/intent links
    ├── theme/
    │   ├── tokens.dart            # colour + spacing + radius tokens mirroring DESIGN_SYSTEM.md
    │   ├── hawa_colors.dart       # ThemeExtension<HawaColors>: primary…ink, simulated, AQI fills + on-colours
    │   ├── app_theme.dart         # ThemeData builders: light, dark, outdoor (high contrast)
    │   ├── typography.dart        # Inter + Noto Sans Devanagari fallback, per-locale line height
    │   └── aqi_palette.dart       # AqiCategory → fill, on-colour, icon; never used without a label
    └── l10n/
        ├── arb/
        │   ├── app_en.arb         # template ARB (English); every key has @description
        │   └── app_hi.arb         # Hindi; CI fails on missing keys
        ├── gen/                   # (gen) AppLocalizations output from flutter gen-l10n
        ├── l10n_x.dart            # BuildContext.l10n extension
        └── enum_labels.dart       # label()/icon() extensions for CONTRACTS enums incl. unknown
```

## 3. `lib/core/`

```text
lib/core/
├── network/
│   ├── dio_provider.dart          # keep-alive Dio with base URL, timeouts, interceptor chain in order
│   ├── bare_dio_provider.dart     # Dio without auth/idempotency, for the S3 presigned POST and token refresh
│   ├── hawa_api_provider.dart     # HawaApi(dio: …) instance; the only place it is constructed
│   ├── api_paths.dart             # path predicates (isAuthCall) used by interceptors
│   ├── connectivity_service.dart  # connectivity_plus stream → online/offline/unknown
│   ├── server_clock.dart          # tracks skew from Date headers; serverNow()
│   └── interceptors/
│       ├── request_id_interceptor.dart   # X-Request-Id per attempt, X-Correlation-Id passthrough
│       ├── idempotency_interceptor.dart  # Idempotency-Key on mutating calls, stable across retries
│       ├── auth_interceptor.dart         # Bearer header, proactive refresh near exp
│       ├── refresh_interceptor.dart      # QueuedInterceptor; single-flight refresh on 401, replay once
│       ├── retry_interceptor.dart        # transient retry with backoff + jitter, Retry-After aware
│       ├── problem_json_interceptor.dart # problem+json → typed Failure on DioException.error
│       └── logging_interceptor.dart      # (dev) redacted request/response logs
├── storage/
│   ├── app_database.dart          # drift @DriftDatabase: tables, DAOs, WAL, MigrationStrategy
│   ├── tables/
│   │   ├── routes_table.dart      # route header per service date (geometry, bbox, version)
│   │   ├── tasks_table.dart       # task rows (driver + inspector), server status + pending status
│   │   ├── stops_table.dart       # ordered stop projection (route_id, sequence, task_id)
│   │   ├── alerts_table.dart      # alert inbox (read/ack state)
│   │   ├── reports_draft_table.dart   # Citizen Eyes drafts + submitted report tracking
│   │   ├── outbox_ops_table.dart  # pending mutations (id = Idempotency-Key)
│   │   ├── sync_state_table.dart  # per-scope freshness, etag, drain lease
│   │   ├── media_files_table.dart # local photos, sha256, object_key after upload
│   │   ├── location_pings_table.dart  # shift-only pings awaiting batch upload
│   │   ├── safe_windows_table.dart    # school safe windows per date
│   │   └── cached_payloads_table.dart # generic JSON cache (inspection bundles, air, site, forecast)
│   ├── daos/
│   │   ├── task_dao.dart          # watch route/stops, upsert from server, apply pending status
│   │   ├── alert_dao.dart         # inbox paging, mark read/acked
│   │   ├── report_dao.dart        # drafts, status timeline cache
│   │   ├── outbox_dao.dart        # enqueue, nextReady (ordering + deps), mark done/failed/superseded
│   │   ├── sync_state_dao.dart    # freshness + lease
│   │   ├── media_dao.dart         # media lifecycle
│   │   └── cache_dao.dart         # cached_payloads get/put with TTL
│   ├── migrations/                # drift schema dumps (schema_v1.json …) + generated migration tests
│   ├── secure_token_store.dart    # flutter_secure_storage wrapper: access/refresh/user/install id
│   ├── settings_store.dart        # shared_preferences wrapper: language, role, theme, data saver, flags
│   └── wipe_service.dart          # logout wipe: DB, tokens, media, prefs except language
├── sync/
│   ├── outbox_op.dart             # OpKind enum + OutboxOp entity + payload codecs
│   ├── outbox_repository.dart     # enqueue within caller's transaction; depth/status streams
│   ├── outbox_drainer.dart        # lease, pick head-of-line ops, execute, classify result
│   ├── backoff.dart               # exponential backoff with full jitter, Retry-After override
│   ├── conflict_resolver.dart     # 409/410 + server-event reconciliation rules (OFFLINE_AND_SYNC §7)
│   ├── conflict_banner_bus.dart   # stream of resolved-conflict notices for the UI
│   ├── sync_triggers.dart         # connectivity regain, resume, push, WS reconnect, periodic
│   ├── background_sync.dart       # workmanager callback: opens DB, drains outbox, refreshes stale scopes
│   ├── stale_policy.dart          # per-scope staleness thresholds
│   └── executors/
│       ├── task_ack_executor.dart        # POST /v1/tasks/{id}/ack
│       ├── task_status_executor.dart     # POST /v1/tasks/{id}/status
│       ├── inspection_close_executor.dart # POST /v1/inspections/{id}/close (outcome + evidence_keys)
│       ├── photo_upload_executor.dart    # presign + S3 presigned POST (multipart form), re-presign on expiry
│       ├── report_submit_executor.dart   # POST /v1/reports
│       ├── alert_ack_executor.dart       # POST /v1/alerts/{id}/ack (proposed)
│       ├── shift_executor.dart           # POST /v1/shifts/{id}/start, /end on asset_shift (proposed)
│       ├── location_batch_executor.dart  # POST /v1/shifts/{id}/locations (proposed); inspector shifts or tag offline only; drops > 6 h
│       ├── push_token_executor.dart      # PUT /v1/me/push-token (latest wins)
│       └── profile_update_executor.dart  # PATCH /v1/me, PUT /v1/me/alert-subscription (proposed)
├── realtime/
│   ├── ws_client.dart             # connect ?token=, subscribe, heartbeat, backoff reconnect, lifecycle
│   ├── ws_message.dart            # freezed server/client message models
│   ├── realtime_dispatcher.dart   # routes events by channel/type to feature appliers
│   └── event_deduper.dart         # 10-min dedupe window shared by WS and FCM
├── notifications/
│   ├── fcm_service.dart           # permission, token, onMessage, onMessageOpenedApp, initial message
│   ├── fcm_background_handler.dart# top-level vm:entry-point handler; drift write + local notification
│   ├── local_notifications.dart   # flutter_local_notifications init, show, tap callback
│   ├── notification_channels.dart # channel ids, importance, localized names
│   ├── push_payload.dart          # freezed FCM data payload (all strings) + parsing
│   ├── push_router.dart           # map hawa:// entity links to role routes, validate ids, switch role, router.go
│   └── push_token_registrar.dart  # enqueue push_token op on login/refresh; delete on logout
├── location/
│   ├── location_service.dart      # geolocator wrapper: permission status, current fix, accuracy
│   ├── shift_location_tracker.dart# foreground-service position stream during shift only
│   ├── sampling_policy.dart       # battery- and proximity-aware accuracy/interval table
│   └── geofence.dart              # arrival detection with dwell for the next stop
├── media/
│   ├── photo_capture.dart         # image_picker camera-only capture + lost-data recovery
│   ├── image_processor.dart       # resize + JPEG re-encode with keepExif=false + sha256
│   └── upload_service.dart        # presign request + bare-Dio presigned POST (fields + file) with progress
├── maps/
│   ├── hawa_tile_layer.dart       # TileLayer with provider URL, key, cached tile provider, attribution
│   ├── tile_cache.dart            # file store, size cap, LRU eviction
│   ├── corridor_prefetcher.dart   # tiles along route buffer z15–z16 + bbox z12–z14, 400-tile cap
│   ├── polyline_simplifier.dart   # Douglas-Peucker
│   └── map_markers.dart           # numbered stop marker, suspect pin, photo marker (icon + number, not colour only)
├── errors/
│   ├── failure.dart               # sealed Failure hierarchy
│   ├── problem_details.dart       # RFC 9457 model
│   ├── failure_messages.dart      # Failure → localized user copy
│   ├── crash_reporter.dart        # Crashlytics wrapper (no-op in dev), hashed user id, custom keys
│   └── app_logger.dart            # package:logging setup + redaction
├── utils/
│   ├── clock.dart                 # injectable Clock provider (fake in tests)
│   ├── ids.dart                   # UUIDv7 generator
│   ├── ist_time.dart              # UTC → IST, en/hi day-part formatting, service date
│   ├── aqi.dart                   # CONTRACTS §10.1 breakpoints (fallback only; server value preferred)
│   ├── geo.dart                   # haversine, bbox, bbox snapping to ~1 km grid
│   └── localized_text.dart        # {en, hi} value object with fallback
└── widgets/
    ├── simulated_badge.dart       # purple "Simulated / सिम्युलेटेड" pill
    ├── simulated_screen_chip.dart # "Includes simulated data" top chip (flask icon + words)
    ├── aqi_chip.dart              # colour + number + category label + "indicative"
    ├── uncertainty_text.dart      # "likely 180 (range 140–240)" formatter widget
    ├── confidence_chip.dart       # High/Medium/Low from 0–1 with DESIGN_SYSTEM thresholds 0.7 / 0.4
    ├── stale_banner.dart          # "Last updated 07:42" amber banner
    ├── offline_banner.dart        # "Offline: showing saved data"
    ├── sync_status_chip.dart      # outbox depth indicator → /settings/sync
    ├── conflict_banner.dart       # resolved-conflict message with dismiss
    ├── big_action_button.dart     # 64 dp icon + label button, outdoor-mode aware
    ├── confirm_sheet.dart         # two-large-button confirmation bottom sheet
    ├── status_pill.dart           # icon + word for Task/Report/Inspection statuses
    ├── empty_state.dart           # icon + message + optional action
    ├── error_view.dart            # Failure message + Retry + Details (request id)
    └── loading_skeleton.dart      # shimmer-free placeholder blocks (cheap on low-end GPUs)
```

## 4. `lib/features/`

Every feature has the same four folders. Files marked `fake_*` implement the remote source from `assets/fixtures/` and are wired only when `USE_FAKE_API=true`.

```text
lib/features/
├── auth/
│   ├── presentation/
│   │   ├── language_screen.dart         # first-run हिन्दी / English picker (/onboarding/language)
│   │   ├── phone_screen.dart            # +91 number entry, Send OTP (/auth/phone)
│   │   ├── otp_screen.dart              # 6-digit code, resend timer, SMS consent autofill (/auth/otp)
│   │   └── widgets/
│   │       ├── phone_field.dart         # fixed +91 prefix, 10 digits starting 6–9
│   │       └── otp_boxes.dart           # six 56 dp boxes, paste support
│   ├── application/
│   │   ├── session_controller.dart      # SessionState, activeRole, switchRole, logout, expiry handling
│   │   ├── otp_controller.dart          # request/verify, countdown, failure mapping
│   │   └── sms_consent_service.dart     # SMS User Consent API wrapper (Android)
│   ├── domain/
│   │   ├── session_state.dart           # sealed: booting / signedOut / signedIn(user, roles, activeRole)
│   │   ├── app_user.dart                # id, roles, lang, display name, ward ids
│   │   ├── user_role.dart               # UserRole enum + unknown, isWebOnly, app role order
│   │   └── auth_repository.dart         # interface
│   └── data/
│       ├── auth_repository_impl.dart    # OTP, tokens, /v1/me cache, logout
│       ├── auth_remote_source.dart      # hawa_api Auth + Me calls
│       ├── token_refresher.dart         # refresh on bare Dio for RefreshInterceptor
│       └── fake_auth_remote_source.dart # (dev) OTP 123456, fixture users
├── shell/
│   ├── presentation/
│   │   ├── role_picker_screen.dart      # multi-role chooser (/auth/role)
│   │   ├── permission_education_screen.dart # rationale + request for :kind
│   │   ├── unsupported_role_screen.dart # officers → "use the web console"
│   │   ├── driver_shell.dart            # tabs Route, Map, More
│   │   ├── inspector_shell.dart         # tabs Targets, Map, More
│   │   ├── school_shell.dart            # tabs Today, Air, Alerts, More
│   │   ├── citizen_shell.dart           # tabs Air, Report, My reports, More
│   │   ├── site_shell.dart              # single page + More (VISION)
│   │   └── widgets/
│   │       ├── shell_app_bar.dart       # title, sync chip, simulated chip, outdoor toggle, bell
│   │       └── role_tile.dart           # large role option with icon and bilingual label
│   ├── application/
│   │   └── permission_controller.dart   # status/request/openSettings per permission kind
│   ├── domain/
│   │   ├── app_permission.dart          # notifications | location | camera, which roles need which
│   │   └── permission_repository.dart   # interface
│   └── data/
│       └── permission_repository_impl.dart # permission_handler + firebase_messaging permission
├── driver_route/                        # BUILD (Flow B)
│   ├── presentation/
│   │   ├── today_route_screen.dart      # next-stop hero + ordered list (/driver)
│   │   ├── route_map_screen.dart        # polyline + numbered markers (/driver/map)
│   │   ├── stop_detail_screen.dart      # what to do, window, navigate, status (/driver/stops/:taskId)
│   │   ├── skip_reason_screen.dart      # reason picker as modal page (/driver/stops/:taskId/skip)
│   │   ├── manual_done_screen.dart      # HawaTag-offline fallback (/driver/stops/:taskId/manual-done)
│   │   ├── shift_summary_screen.dart    # done/skipped/pending + verified (/driver/shift/summary)
│   │   └── widgets/
│   │       ├── next_stop_hero.dart      # big card: stop n, place, window, what to do, Navigate
│   │       ├── stop_card.dart           # list row with number, status icon + word, window
│   │       ├── shift_bar.dart           # Start/End shift button + location-sharing indicator
│   │       ├── tag_status_chip.dart     # HawaTag online/offline with last seen
│   │       ├── what_to_do_panel.dart    # spray/sweep/smog-gun instruction with icon and litres/length
│   │       ├── auto_done_overlay.dart   # full-screen tick + haptics (respects reduce motion)
│   │       ├── route_changed_banner.dart# added/removed/reordered summary
│   │       └── verified_chip.dart       # effect ± CI, verdict, lower-evidence label
│   ├── application/
│   │   ├── today_route_controller.dart  # drift stream + refresh
│   │   ├── shift_controller.dart        # start/end shift, tracker lifecycle, auto-end
│   │   ├── stop_actions_controller.dart # navigate (en_route), arrived, manual done, skip
│   │   ├── arrival_watcher.dart         # geofence → local 'arrived' state (driver never posts in_progress)
│   │   ├── auto_done_events.dart        # stream of AutoDoneEvent for overlay/haptics/sound
│   │   └── route_change_detector.dart   # diffs route versions → RouteDiff
│   ├── domain/
│   │   ├── today_route.dart             # route header + stops + asset + shift window
│   │   ├── stop.dart                    # stop entity (ARCHITECTURE §8)
│   │   ├── asset_summary.dart           # asset + HawaTag status
│   │   ├── shift.dart                   # shift id, started/ended, scheduled window
│   │   ├── skip_reason.dart             # SkipReason enum (proposed contract)
│   │   ├── impact_summary.dart          # effect_pct, ci_low, ci_high, method, verdict
│   │   ├── route_diff.dart              # added/removed/moved stops
│   │   └── driver_route_repository.dart # interface
│   └── data/
│       ├── driver_route_repository_impl.dart # fetch/cache, outbox ops, optimistic status
│       ├── task_remote_source.dart      # hawa_api Tasks calls
│       ├── shift_remote_source.dart     # hawa_api Shifts calls (proposed endpoints)
│       ├── task_local_source.dart       # TaskDao mapping
│       ├── task_mapper.dart             # hawa_api models → entities
│       ├── task_event_applier.dart      # WS/push task.* → drift upsert + conflict resolution
│       └── fake_task_remote_source.dart # (dev) fixtures + "simulate spray"
├── inspector/                           # BUILD (online first), offline capture STRETCH
│   ├── presentation/
│   │   ├── targets_screen.dart          # ordered targets with cause + confidence (/inspector)
│   │   ├── inspector_map_screen.dart    # targets + suspect pins (/inspector/map)
│   │   ├── target_detail_screen.dart    # evidence + navigate + arrived (/inspector/targets/:targetId)
│   │   ├── outcome_screen.dart          # outcome, photos, notes (/inspector/targets/:targetId/outcome)
│   │   ├── photo_viewer_screen.dart     # full-screen evidence photo (/inspector/targets/:targetId/photos/:index)
│   │   └── widgets/
│   │       ├── evidence_card.dart       # spike, photo, trajectory sections
│   │       ├── spike_chart.dart         # CustomPainter mini-chart with baseline line
│   │       ├── trajectory_map.dart      # suspect pin + back-trajectory + uncertainty circle
│   │       ├── cause_confidence_chip.dart # "Likely burning, 86 %, high"
│   │       ├── outcome_choice.dart      # three large outcome options
│   │       └── photo_strip.dart         # captured photos with remove
│   ├── application/
│   │   ├── targets_controller.dart
│   │   ├── target_detail_controller.dart
│   │   └── outcome_form_controller.dart # validation, draft persistence, outbox photo_upload → inspection_close
│   ├── domain/
│   │   ├── inspection_target.dart
│   │   ├── evidence_bundle.dart
│   │   ├── inspection_outcome.dart      # closed_confirmed | closed_not_found | closed_unreachable
│   │   └── inspector_repository.dart
│   └── data/
│       ├── inspector_repository_impl.dart
│       ├── inspection_remote_source.dart # tasks/mine (inspect) + inspections?status=assigned + inspections/{id} (proposed) + hotspots/{id}
│       ├── inspection_local_source.dart
│       ├── evidence_thumbnail_cache.dart # downloads signed thumbs before expiry
│       ├── inspection_mapper.dart
│       └── fake_inspection_remote_source.dart
├── school/                              # STRETCH (F19)
│   ├── presentation/
│   │   ├── school_today_screen.dart     # safe windows today/tomorrow + advice (/school)
│   │   ├── indoor_outdoor_screen.dart   # HawaPod-S pair readings (/school/air)
│   │   ├── forecast_screen.dart         # 72 h P10/P50/P90 band (/school/forecast)
│   │   └── widgets/
│   │       ├── safe_window_card.dart
│   │       ├── ventilation_advice_card.dart # keep windows shut / ventilate now
│   │       ├── indoor_outdoor_chart.dart
│   │       ├── forecast_band_chart.dart
│   │       └── language_toggle.dart     # हिन्दी | English segmented control
│   ├── application/
│   │   ├── school_today_controller.dart
│   │   ├── indoor_outdoor_controller.dart
│   │   └── forecast_controller.dart
│   ├── domain/
│   │   ├── school_profile.dart
│   │   ├── safe_window.dart
│   │   ├── classroom_advice.dart        # ClassroomAdvice normal | seal | ventilate (backend DATA_MODEL §7.7) + unknown
│   │   ├── indoor_outdoor_series.dart
│   │   ├── forecast_series.dart
│   │   └── school_repository.dart
│   └── data/
│       ├── school_repository_impl.dart
│       ├── school_remote_source.dart
│       ├── school_local_source.dart
│       ├── school_mapper.dart
│       └── fake_school_remote_source.dart
├── citizen_air/                         # STRETCH (F16 app surface)
│   ├── presentation/
│   │   ├── air_near_me_screen.dart      # AQI hero + dominant pollutant + advice (/citizen)
│   │   ├── subscription_screen.dart     # alert area + kinds (/citizen/subscription)
│   │   ├── route_tip_screen.dart        # (STRETCH) cleaner-route tip from alert advice (/citizen/route-tip)
│   │   └── widgets/
│   │       ├── aqi_hero.dart
│   │       ├── advice_list.dart
│   │       ├── pollutant_row.dart
│   │       └── cell_map.dart
│   ├── application/
│   │   ├── air_near_me_controller.dart
│   │   └── subscription_controller.dart
│   ├── domain/
│   │   ├── air_snapshot.dart
│   │   ├── advice_rules.dart            # pure: dominant pollutant + cause → advice keys (unit tested)
│   │   ├── alert_subscription.dart
│   │   └── citizen_air_repository.dart
│   └── data/
│       ├── citizen_air_repository_impl.dart
│       ├── open_air_remote_source.dart  # /open/v1/air with snapped bbox
│       ├── subscription_remote_source.dart
│       └── fake_open_air_remote_source.dart
├── citizen_reports/                     # STRETCH (F20)
│   ├── presentation/
│   │   ├── report_privacy_screen.dart   # first-use privacy notice (/citizen/report/privacy)
│   │   ├── report_capture_screen.dart   # camera + GPS capture (/citizen/report/new)
│   │   ├── report_review_screen.dart    # preview, note, category, Send (/citizen/report/review)
│   │   ├── my_reports_screen.dart       # list with status pills (/citizen/reports)
│   │   ├── report_status_screen.dart    # timeline + outcome (/citizen/reports/:reportId)
│   │   └── widgets/
│   │       ├── status_timeline.dart
│   │       ├── outcome_card.dart
│   │       ├── photo_preview.dart
│   │       └── location_quality_chip.dart
│   ├── application/
│   │   ├── report_composer_controller.dart
│   │   ├── my_reports_controller.dart
│   │   └── report_status_controller.dart
│   ├── domain/
│   │   ├── citizen_report.dart
│   │   ├── report_draft.dart
│   │   ├── report_status.dart           # ReportStatus + unknown
│   │   ├── report_category.dart         # ReportCategory (proposed contract)
│   │   └── reports_repository.dart
│   └── data/
│       ├── reports_repository_impl.dart
│       ├── reports_remote_source.dart
│       ├── reports_local_source.dart
│       ├── report_mapper.dart
│       └── fake_reports_remote_source.dart
├── alerts/                              # shared inbox (school ack is STRETCH)
│   ├── presentation/
│   │   ├── alert_inbox_screen.dart      # /alerts
│   │   ├── alert_detail_screen.dart     # /alerts/:alertId with Acknowledge
│   │   └── widgets/
│   │       ├── alert_tile.dart
│   │       ├── ack_button.dart
│   │       └── in_app_alert_banner.dart
│   ├── application/
│   │   ├── alert_inbox_controller.dart
│   │   └── alert_detail_controller.dart
│   ├── domain/
│   │   ├── app_alert.dart
│   │   ├── alert_kind.dart              # AlertKind + proposed route_changed, task_done_auto + unknown
│   │   └── alerts_repository.dart
│   └── data/
│       ├── alerts_repository_impl.dart
│       ├── alerts_remote_source.dart
│       ├── alerts_local_source.dart
│       ├── alert_mapper.dart
│       └── fake_alerts_remote_source.dart
├── site/                                # VISION
│   ├── presentation/
│   │   ├── site_score_screen.dart       # /site
│   │   └── widgets/
│   │       ├── grade_badge.dart         # A/B/C with word, not colour alone
│   │       └── pm10_trend_chart.dart
│   ├── application/site_score_controller.dart
│   ├── domain/
│   │   ├── site_score.dart
│   │   └── site_repository.dart
│   └── data/
│       ├── site_repository_impl.dart
│       ├── site_remote_source.dart
│       └── fake_site_remote_source.dart
├── profile/
│   ├── presentation/profile_screen.dart # /profile: name, masked own phone, roles, ward, version
│   ├── application/profile_controller.dart
│   ├── domain/profile.dart
│   └── data/profile_repository_impl.dart # from cached /v1/me
└── settings/
    ├── presentation/
    │   ├── settings_screen.dart         # /settings: language, notifications, data saver, theme, logout
    │   ├── sync_queue_screen.dart       # /settings/sync: pending/failed outbox ops, retry now
    │   └── dev_tools_screen.dart        # (dev) simulate spray, test push, go offline, reset DB
    ├── application/
    │   ├── settings_controller.dart
    │   ├── sync_queue_controller.dart
    │   └── logout_controller.dart       # unsent-outbox warning, then wipe
    ├── domain/
    │   ├── app_settings.dart
    │   └── settings_repository.dart
    └── data/settings_repository_impl.dart # prefs + profile_update outbox op
```

## 5. `packages/hawa_api/` (generated, committed, do not edit)

```text
packages/hawa_api/
├── .openapi-generator/            # FILES and VERSION written by openapi-generator
├── pubspec.yaml                   # package hawa_api; depends on dio, json_annotation
├── lib/
│   ├── hawa_api.dart              # barrel: HawaApi + all APIs + models
│   └── src/
│       ├── api/                   # one class per OpenAPI tag (AuthApi, TasksApi, ReportsApi, …)
│       ├── auth/                  # generated auth helpers (unused: our interceptor sets Bearer)
│       └── model/                 # request/response models with json_serializable
└── README.md                      # generated usage notes
```

Regenerate with `make gen-api`. A CI step can regenerate from `openapi/openapi.json` and fail on `git diff --exit-code packages/hawa_api`, which catches hand edits.

## 6. `assets/`

```text
assets/
├── fonts/
│   ├── Inter-Regular.ttf
│   ├── Inter-SemiBold.ttf
│   ├── NotoSansDevanagari-Regular.ttf
│   ├── NotoSansDevanagari-SemiBold.ttf
│   └── OFL.txt                    # SIL Open Font License for both families (shown in Settings → Licences)
├── images/
│   ├── app_logo.png               # 1x/2x/3x variants
│   └── onboarding_*.png           # permission education illustrations (small, 8-bit PNG)
└── fixtures/                      # (dev) flavor-gated; also read by tests and tool/mock_server
    ├── api/
    │   ├── me_driver.json
    │   ├── me_multi_role.json     # driver + citizen, for role picker
    │   ├── tasks_mine_driver.json # 6 stops, is_simulated true, route geometry
    │   ├── tasks_mine_inspector.json
    │   ├── inspections_assigned.json # report-origin inspection without a task
    │   ├── inspection_detail.json
    │   ├── school_me.json
    │   ├── safe_window_2026-11-13.json
    │   ├── indoor_outdoor.json
    │   ├── forecast_cell.json
    │   ├── open_air_bbox.json
    │   ├── alerts.json
    │   ├── reports_mine.json
    │   ├── report_detail_closed.json
    │   ├── sites_me.json
    │   └── problem_409_task_done.json # conflict example
    └── ws/
        ├── task_done_hawatag.json
        ├── task_verified.json
        ├── task_cancelled.json
        └── alert_requested_safe_window.json
```

Fixtures follow [../backend/API.md](../backend/API.md). When API.md changes, fixtures change in the same PR as the regenerated client.

## 7. `test/`, `integration_test/`, `tool/`

```text
test/
├── flutter_test_config.dart       # loads bundled fonts for goldens, sets default locale
├── helpers/
│   ├── pump_app.dart              # wraps widget in ProviderScope + MaterialApp (theme, l10n en/hi, textScaler)
│   ├── in_memory_db.dart          # AppDatabase(NativeDatabase.memory())
│   ├── fake_clock.dart            # controllable Clock
│   ├── mocks.dart                 # mocktail mocks for remote sources, services
│   └── fixtures.dart              # loads assets/fixtures/**
├── app/router/guards_test.dart    # redirect matrix
├── core/                          # interceptors, backoff, drainer (fake_async), image EXIF, ist_time, aqi, deep links
├── features/<feature>/            # mirrors lib/features: data (repository), application (controller), presentation (widget)
└── goldens/                       # baselines: <screen>_<locale>_<mode>_<scale>.png

integration_test/
├── flow_b_driver_test.dart        # login → route → start shift → mock spray → auto-done → end shift
├── inspector_offline_test.dart    # record outcome offline → reconnect → synced once
├── citizen_eyes_test.dart         # capture (fake camera) → submit offline → sync → status timeline
└── robots/                        # screen robots (tap/find helpers) shared by tests

tool/
├── mock_server/
│   ├── pubspec.yaml               # shelf, shelf_router, shelf_web_socket
│   ├── bin/server.dart            # serves fixtures on :8081, /healthz, WS /v1/ws, control API /__mock/*
│   └── lib/
│       ├── scenarios.dart         # scripted states: driver_morning, spike_path, school_evening
│       ├── ws_hub.dart            # per-connection subscriptions, emit helpers
│       └── failure_injection.dart # /__mock/fail?path=&status=&count=, latency, drop WS
├── hooks/pre_commit.sh            # format check on staged Dart files + analyze (LINTING_AND_QUALITY §7)
└── check_untranslated.dart        # fails if gen-l10n reports untranslated hi messages
```

## 8. Android notes

| File | What to set |
|---|---|
| `android/app/build.gradle.kts` | `minSdk = 24`, `targetSdk` = Play's current requirement, `compileSdk` latest. `flavorDimensions += "env"`, flavors `dev` (`applicationIdSuffix = ".dev"`, `resValue("string","app_name","Hawa DEV")`), `staging` (`.stg`, "Hawa STG"), `prod` ("HawaCommand"). Release signing from `key.properties` if present, else the debug key (dev/staging CI builds only) |
| `android/app/src/main/AndroidManifest.xml` | Permissions below. `android:allowBackup="false"`, `android:fullBackupContent="false"`, `usesCleartextTraffic="false"`. `<queries>` for `google.navigation` and `https` VIEW intents. Intent filter for the `hawa://` scheme (backend `alert.deep_link` form). FCM default notification icon + channel meta-data |
| `android/app/src/dev/res/xml/network_security_config.xml` | cleartext allowed for `10.0.2.2` and `localhost` only. Referenced only in the dev source set |
| `android/app/src/<flavor>/google-services.json` | from Firebase per flavor. **Not committed**, written by CI from a secret |
| `android/app/src/main/res/drawable/ic_stat_hawa.png` | monochrome notification small icon |
| `android/app/src/main/res/raw/stop_done.ogg` | short chime used as the `route_updates` / auto-done sound (no audio package needed) |

Permissions:

| Permission | Why (shown in the education screen, not the manifest) | Requested when |
|---|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | API, WS, connectivity checks | install |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Route position and stop arrival during shift. Citizen report GPS and coarse "air near me" | driver/inspector before first **Start shift**. Citizen at first "air near me" or report |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` | Keep location during shift with a visible notification (Android 14+ requires the typed permission) | install (normal permissions) |
| `POST_NOTIFICATIONS` | Route at 05:30, alerts (Android 13+ runtime) | after role selection, education screen first |
| `CAMERA` | Citizen Eyes and inspector evidence photos | just in time, first capture |
| `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` | Added by workmanager/local notifications for background sync | install |
| **Not requested** | `ACCESS_BACKGROUND_LOCATION`, `READ_SMS`/`RECEIVE_SMS` (SMS User Consent needs neither), storage/media, contacts, microphone | never |

The foreground service: verify that the merged manifest (`build/app/intermediates/merged_manifests/`) declares the geolocator service with `android:foregroundServiceType="location"`. If not, add:

```xml
<service
    android:name="com.baseflow.geolocator.GeolocatorLocationService"
    android:foregroundServiceType="location"
    android:exported="false"
    tools:node="merge" />
```

For Play Console, apps targeting Android 14+ must complete the foreground-service declaration (type `location`, with a short video of the shift flow) before release, including internal testing. Firebase: `flutterfire configure` per flavor with the matching package name. The Gradle google-services plugin reads the flavor source set file.

## 9. iOS notes (secondary)

| File | What to set |
|---|---|
| `ios/Podfile` | `platform :ios` = the higher of Flutter's and Firebase's current minimums |
| `ios/Runner/Info.plist` | `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription` (no photo-library key: camera only). `UIBackgroundModes`: `remote-notification`, `location` (shift only, with `showsBackgroundLocationIndicator`). `CFBundleLocalizations`: `en`, `hi` |
| `ios/Runner/en.lproj/InfoPlist.strings`, `ios/Runner/hi.lproj/InfoPlist.strings` | Localized permission strings (same text as the education screens) |
| `ios/Runner/GoogleService-Info.plist` | Per flavor via build phase script (post-hackathon), not committed |
| Xcode schemes | `dev`/`staging`/`prod` schemes + xcconfigs after the hackathon. Until then iOS runs a single configuration pointed at staging |
| APNs | APNs auth key uploaded to each Firebase project. Push capability + background modes enabled |

## 10. Configuration file sketches

### 10.1 `.fvmrc`

```json
{ "flutter": "<latest stable at scaffold time, e.g. 3.x.y>" }
```

### 10.2 `pubspec.yaml` (dependency names; versions come from `flutter pub add`, pinned in `pubspec.lock`)

```bash
fvm flutter pub add flutter_riverpod riverpod_annotation go_router dio freezed_annotation json_annotation \
  drift sqlite3_flutter_libs path_provider path flutter_secure_storage shared_preferences \
  web_socket_channel connectivity_plus firebase_core firebase_messaging firebase_crashlytics \
  flutter_local_notifications workmanager geolocator battery_plus permission_handler url_launcher \
  flutter_map latlong2 flutter_map_cache dio_cache_interceptor http_cache_file_store \
  image_picker flutter_image_compress crypto uuid intl logging package_info_plus clock collection \
  "hawa_api:{\"path\":\"packages/hawa_api\"}"
fvm flutter pub add --dev build_runner riverpod_generator freezed json_serializable drift_dev \
  very_good_analysis custom_lint riverpod_lint mocktail fake_async http_mock_adapter
fvm flutter pub add --dev "flutter_test:{\"sdk\":\"flutter\"}" "integration_test:{\"sdk\":\"flutter\"}"
```

Add `flutter_localizations: {sdk: flutter}` by hand. Choose one SMS User Consent plugin (check its maintenance at scaffold time) or write a ~40-line platform channel. Record every package added after scaffold in the PR description with a maintenance, licence and size note.

```yaml
name: hawa_app
publish_to: none
environment:
  sdk: ^3.0.0            # set to the Dart SDK of the pinned Flutter
flutter:
  uses-material-design: true
  generate: true         # l10n
  assets:
    - assets/images/
    - path: assets/fixtures/
      flavors: [dev]     # flavor-conditional assets (recent Flutter); if unsupported, keep fixtures test-only
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
    - family: NotoSansDevanagari
      fonts:
        - asset: assets/fonts/NotoSansDevanagari-Regular.ttf
        - asset: assets/fonts/NotoSansDevanagari-SemiBold.ttf
          weight: 600
```

### 10.3 `l10n.yaml`

```yaml
arb-dir: lib/app/l10n/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/app/l10n/gen
nullable-getter: false
untranslated-messages-file: build/l10n_untranslated.json   # tool/check_untranslated.dart fails CI if non-empty
# synthetic-package: false   # needed only on older Flutter versions; remove if flutter warns it is unsupported
```

### 10.4 `build.yaml`

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          field_rename: snake
          explicit_to_json: true
          checked: true
        generate_for:
          - lib/**/domain/**.dart
          - lib/core/**.dart
      freezed:
        generate_for:
          - lib/**/domain/**.dart
          - lib/core/**.dart
          - lib/**/application/**.dart
      riverpod_generator:
        generate_for:
          - lib/**.dart
      drift_dev:
        options:
          named_parameters: true
          store_date_time_values_as_text: false
        generate_for:
          - lib/core/storage/**.dart
```

Option names must match the pinned builder versions. Check each builder's README when scaffolding.

### 10.5 `openapi/generator-config.yaml`

```yaml
generatorName: dart-dio
additionalProperties:
  pubName: hawa_api
  pubAuthor: HawaCommand
  serializationLibrary: json_serializable
  enumUnknownDefaultCase: "true"      # unknown enum values → sentinel (CONTRACTS §12.5)
  dateLibrary: core
```

### 10.6 `dart_test.yaml`

```yaml
tags:
  golden: {}
  slow: {}
```

### 10.7 `Makefile`

```make
FLAVOR ?= dev
API_URL ?= http://localhost:8000
OPENAPI_GENERATOR_IMAGE ?= openapitools/openapi-generator-cli:<pinned tag>
DART_SRC = git ls-files '*.dart' | grep -v -E '\.g\.dart$$|\.freezed\.dart$$|^packages/hawa_api/|^lib/app/l10n/gen/'

setup:        ; fvm install && fvm flutter pub get && $(MAKE) gen
gen:          ; fvm dart run build_runner build -d
watch:        ; fvm dart run build_runner watch -d
l10n:         ; fvm flutter gen-l10n && fvm dart run tool/check_untranslated.dart
format:       ; $(DART_SRC) | xargs fvm dart format
format-check: ; $(DART_SRC) | xargs fvm dart format --output=none --set-exit-if-changed
analyze:      ; fvm flutter analyze --fatal-infos
custom-lint:  ; fvm dart run custom_lint
lint:         format-check analyze custom-lint
fix:          ; fvm dart fix --apply && $(MAKE) format
test:         ; fvm flutter test --coverage
golden:       ; fvm flutter test --tags golden --update-goldens
it:           ; fvm flutter test integration_test/flow_b_driver_test.dart --flavor dev --dart-define-from-file=env/dev.json
run:          ; fvm flutter run --flavor $(FLAVOR) --dart-define-from-file=env/$(FLAVOR).json
apk:          ; fvm flutter build apk --flavor $(FLAVOR) --dart-define-from-file=env/$(FLAVOR).json --split-per-abi
mock-server:  ; cd tool/mock_server && fvm dart run bin/server.dart --port 8081
gen-api:
	curl -fsS $(API_URL)/openapi.json -o openapi/openapi.json
	docker run --rm -v "$(CURDIR):/local" $(OPENAPI_GENERATOR_IMAGE) generate \
	  -i /local/openapi/openapi.json -o /local/packages/hawa_api -c /local/openapi/generator-config.yaml
	cd packages/hawa_api && fvm dart pub get && fvm dart run build_runner build -d
.PHONY: setup gen watch l10n format format-check analyze custom-lint lint fix test golden it run apk mock-server gen-api
```

## 11. Naming and import conventions

| Thing | Convention | Example |
|---|---|---|
| Files | `snake_case.dart`, suffix by role: `_screen`, `_controller`, `_repository`, `_repository_impl`, `_remote_source`, `_local_source`, `_mapper`, `_dao`, `_table`, `_executor` | `stop_detail_screen.dart` |
| Providers | generated from annotated names: `todayRouteControllerProvider`, `driverRouteRepositoryProvider` | |
| Route paths | only via `Routes.*` | `Routes.stop(taskId)` |
| ARB keys | `feature` + `Element` + `Purpose`, lowerCamel | `driverStartShiftButton`, `citizenReportPrivacyBody` |
| Enums | Dart lowerCamel values mapped to CONTRACTS `snake_case` wire values, always with `unknown` | `TaskStatus.enRoute` ↔ `en_route` |
| Imports | `package:hawa_app/...` absolute imports (`always_use_package_imports` from very_good_analysis). No relative imports across features | |
| Tests | mirror the source path, `_test.dart` suffix | `test/features/driver_route/data/driver_route_repository_impl_test.dart` |
