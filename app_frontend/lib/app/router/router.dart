import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/router/guards.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/features/air_map/presentation/air_map_screen.dart';
import 'package:hawa_app/features/air_map/presentation/place_search_screen.dart';
import 'package:hawa_app/features/alerts/presentation/alert_detail_screen.dart';
import 'package:hawa_app/features/alerts/presentation/alert_inbox_screen.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/auth/presentation/language_screen.dart';
import 'package:hawa_app/features/auth/presentation/otp_screen.dart';
import 'package:hawa_app/features/auth/presentation/phone_screen.dart';
import 'package:hawa_app/features/auth/presentation/splash_screen.dart';
import 'package:hawa_app/features/citizen_air/presentation/air_near_me_screen.dart';
import 'package:hawa_app/features/citizen_air/presentation/route_tip_screen.dart';
import 'package:hawa_app/features/citizen_air/presentation/subscription_screen.dart';
import 'package:hawa_app/features/citizen_air/presentation/safe_route_screen.dart';
import 'package:hawa_app/features/citizen_air/presentation/live_operations_screen.dart';
import 'package:hawa_app/features/citizen_air/presentation/ward_scorecard_screen.dart';
import 'package:hawa_app/features/citizen_reports/presentation/my_reports_screen.dart';
import 'package:hawa_app/features/citizen_reports/presentation/report_capture_screen.dart';
import 'package:hawa_app/features/citizen_reports/presentation/missed_machine_screen.dart';
import 'package:hawa_app/features/citizen_reports/presentation/report_privacy_screen.dart';
import 'package:hawa_app/features/citizen_reports/presentation/report_review_screen.dart';
import 'package:hawa_app/features/citizen_reports/presentation/report_status_screen.dart';
import 'package:hawa_app/features/driver_route/presentation/manual_done_screen.dart';
import 'package:hawa_app/features/driver_route/presentation/route_map_screen.dart';
import 'package:hawa_app/features/driver_route/presentation/shift_summary_screen.dart';
import 'package:hawa_app/features/driver_route/presentation/skip_reason_screen.dart';
import 'package:hawa_app/features/driver_route/presentation/stop_detail_screen.dart';
import 'package:hawa_app/features/driver_route/presentation/today_route_screen.dart';
import 'package:hawa_app/features/inspector/presentation/inspector_map_screen.dart';
import 'package:hawa_app/features/inspector/presentation/outcome_screen.dart';
import 'package:hawa_app/features/inspector/presentation/photo_viewer_screen.dart';
import 'package:hawa_app/features/inspector/presentation/target_detail_screen.dart';
import 'package:hawa_app/features/inspector/presentation/targets_screen.dart';
import 'package:hawa_app/features/profile/presentation/profile_screen.dart';
import 'package:hawa_app/features/school/presentation/forecast_screen.dart';
import 'package:hawa_app/features/school/presentation/indoor_outdoor_screen.dart';
import 'package:hawa_app/features/school/presentation/school_today_screen.dart';
import 'package:hawa_app/features/settings/presentation/dev_tools_screen.dart';
import 'package:hawa_app/features/settings/presentation/notification_settings_screen.dart';
import 'package:hawa_app/features/settings/presentation/settings_screen.dart';
import 'package:hawa_app/features/settings/presentation/sync_queue_screen.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/presentation/citizen_shell.dart';
import 'package:hawa_app/features/shell/presentation/driver_shell.dart';
import 'package:hawa_app/features/shell/presentation/inspector_shell.dart';
import 'package:hawa_app/features/shell/presentation/permission_education_screen.dart';
import 'package:hawa_app/features/shell/presentation/role_picker_screen.dart';
import 'package:hawa_app/features/shell/presentation/school_shell.dart';
import 'package:hawa_app/features/shell/presentation/site_shell.dart';
import 'package:hawa_app/features/shell/presentation/unsupported_role_screen.dart';
import 'package:hawa_app/features/site/presentation/site_score_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Modal pages (skip reason, manual done, permission education) cover the tab bar.
Page<void> _modal(GoRouterState state, Widget child) =>
    MaterialPage<void>(key: state.pageKey, fullscreenDialog: true, child: child);

/// One GoRouter (ARCHITECTURE §5). Role shells are StatefulShellRoute.indexedStack so each tab
/// keeps its stack; shared routes are pushed on top.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(ref.read(sessionControllerProvider), state.uri),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.splash),
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.language, builder: (_, _) => const LanguageScreen()),
      GoRoute(
        path: Routes.phone,
        builder: (_, s) => PhoneScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (_, s) => OtpScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(path: Routes.rolePicker, builder: (_, _) => const RolePickerScreen()),
      GoRoute(path: Routes.unsupportedRole, builder: (_, _) => const UnsupportedRoleScreen()),
      GoRoute(
        path: Routes.permissionPattern,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, s) => _modal(
          s,
          PermissionEducationScreen(
            kind: AppPermission.fromName(s.pathParameters['kind']) ?? AppPermission.notifications,
          ),
        ),
      ),

      // Driver: Route · Map · More.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => DriverShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.driver,
                builder: (_, _) => const TodayRouteScreen(),
                routes: [
                  GoRoute(
                    path: 'stops/:taskId',
                    builder: (_, s) => StopDetailScreen(taskId: s.pathParameters['taskId']!),
                    routes: [
                      GoRoute(
                        path: 'skip',
                        parentNavigatorKey: rootNavigatorKey,
                        pageBuilder: (_, s) =>
                            _modal(s, SkipReasonScreen(taskId: s.pathParameters['taskId']!)),
                      ),
                      GoRoute(
                        path: 'manual-done',
                        parentNavigatorKey: rootNavigatorKey,
                        pageBuilder: (_, s) =>
                            _modal(s, ManualDoneScreen(taskId: s.pathParameters['taskId']!)),
                      ),
                    ],
                  ),
                  GoRoute(path: 'shift/summary', builder: (_, _) => const ShiftSummaryScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.driverMap, builder: (_, _) => const RouteMapScreen())],
          ),
        ],
      ),

      // Inspector: Targets · Map · More. `:targetId` is the inspection id.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => InspectorShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inspector,
                builder: (_, _) => const TargetsScreen(),
                routes: [
                  GoRoute(
                    path: 'targets/:targetId',
                    builder: (_, s) => TargetDetailScreen(targetId: s.pathParameters['targetId']!),
                    routes: [
                      GoRoute(
                        path: 'outcome',
                        parentNavigatorKey: rootNavigatorKey,
                        pageBuilder: (_, s) =>
                            _modal(s, OutcomeScreen(targetId: s.pathParameters['targetId']!)),
                      ),
                      GoRoute(
                        path: 'photos/:index',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (_, s) => PhotoViewerScreen(
                          targetId: s.pathParameters['targetId']!,
                          index: int.tryParse(s.pathParameters['index'] ?? '') ?? 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.inspectorMap, builder: (_, _) => const InspectorMapScreen()),
            ],
          ),
        ],
      ),

      // School: Today · Air · (Alerts) · More.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => SchoolShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.school,
                builder: (_, s) => SchoolTodayScreen(date: s.uri.queryParameters['date']),
                routes: [GoRoute(path: 'forecast', builder: (_, _) => const ForecastScreen())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.schoolAir, builder: (_, _) => const IndoorOutdoorScreen()),
            ],
          ),
        ],
      ),

      // Citizen: Map · Air · Report · My reports · More.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => CitizenShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.citizenMap, builder: (_, _) => const AirMapScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.citizen,
                builder: (_, _) => const AirNearMeScreen(),
                routes: [
                  GoRoute(path: 'subscription', builder: (_, _) => const SubscriptionScreen()),
                  GoRoute(path: 'route-tip', builder: (_, _) => const RouteTipScreen()),
                  GoRoute(path: 'safe-route', builder: (_, _) => const SafeRouteScreen()),
                  GoRoute(path: 'live-ops', builder: (_, _) => const LiveOperationsScreen()),
                  GoRoute(path: 'ward-score', builder: (_, _) => const WardScorecardScreen()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reportCapture,
                builder: (_, _) => const ReportCaptureScreen(),
                routes: [
                  GoRoute(path: 'missed-machine', builder: (_, _) => const MissedMachineScreen()),
                ],
              ),
              GoRoute(path: Routes.reportPrivacy, builder: (_, _) => const ReportPrivacyScreen()),
              GoRoute(
                path: Routes.reportReview,
                builder: (_, s) => ReportReviewScreen(draftId: s.uri.queryParameters['draft']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.myReports,
                builder: (_, _) => const MyReportsScreen(),
                routes: [
                  GoRoute(
                    path: ':reportId',
                    builder: (_, s) => ReportStatusScreen(reportId: s.pathParameters['reportId']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Site manager: Site · More.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => SiteShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.site, builder: (_, _) => const SiteScoreScreen())],
          ),
        ],
      ),

      // Shared, pushed on top of any shell.
      GoRoute(
        path: Routes.map,
        builder: (_, _) => const AirMapScreen(standalone: true),
        routes: [
          GoRoute(
            path: 'search',
            builder: (_, s) =>
                PlaceSearchScreen(isOrigin: s.uri.queryParameters['field'] == 'from'),
          ),
        ],
      ),
      GoRoute(
        path: Routes.alerts,
        builder: (_, _) => const AlertInboxScreen(),
        routes: [
          GoRoute(
            path: ':alertId',
            builder: (_, s) => AlertDetailScreen(alertId: s.pathParameters['alertId']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'sync', builder: (_, _) => const SyncQueueScreen()),
          GoRoute(path: 'notifications', builder: (_, _) => const NotificationSettingsScreen()),
          GoRoute(path: 'dev', builder: (_, _) => const DevToolsScreen()),
        ],
      ),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
    ],
  );
  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
}
