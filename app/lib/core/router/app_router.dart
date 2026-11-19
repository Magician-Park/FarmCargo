import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/onboarding/permissions_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/driver/detail_screen.dart';
import '../../features/driver/driver_shell.dart';
import '../../features/driver/jobs_screen.dart';
import '../../features/driver/lobby_screen.dart';
import '../../features/driver/my_orders_screen.dart';
import '../../features/driver/settings_screen.dart';
import '../../features/driver/settlement_screen.dart';
import '../../features/driver/trip_screen.dart';
import '../../features/driver/pending_approval_screen.dart';
import '../../features/driver/preferred_routes_screen.dart';
import '../../features/signup/signup_flow_screen.dart';

abstract final class AppRoutes {
  static const permissions = '/permissions';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const driverHome = '/driver';
  static const driverJobs = '/driver/jobs';
  static const driverMyOrders = '/driver/my-orders';
  static const driverSettlement = '/driver/settlement';
  static const driverSettings = '/driver/settings';
  static const driverPreferredRoutes = '/driver/settings/preferred-routes';
  static const driverPending = '/pending';

  static String resetPasswordLink(String token) =>
      '$resetPassword?token=${Uri.encodeQueryComponent(token)}';
  static String driverOrder(String id) => '$driverHome/orders/$id';
  static String driverTrip(String orderId) => '$driverHome/trips/$orderId';
}

/// 로그인하지 않아도 볼 수 있는 경로.
bool _isPublic(String location) =>
    location == AppRoutes.permissions ||
    location == AppRoutes.welcome ||
    location == AppRoutes.login ||
    location == AppRoutes.forgotPassword ||
    location == AppRoutes.resetPassword ||
    location.startsWith(AppRoutes.signup);

final routerProvider = Provider<GoRouter>((ref) {
  // 로그인 상태가 바뀌면 redirect를 다시 평가한다.
  final authChanged = ValueNotifier<int>(0);
  ref.listen(authProvider, (previous, next) => authChanged.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.permissions,
    refreshListenable: authChanged,
    redirect: (context, state) {
      final account = ref.read(authProvider);
      final location = state.matchedLocation;
      if (account == null) {
        return _isPublic(location) ? null : AppRoutes.welcome;
      }
      // 심사 중인 차주는 승인 대기 화면만 볼 수 있다(사용자 결정 2026-11-11).
      if (account.isPending) {
        return location == AppRoutes.driverPending
            ? null
            : AppRoutes.driverPending;
      }
      // 로그인 상태에서는 자기 역할의 영역만 접근할 수 있다.
      // 차주 전용 앱: 로그인하면 차주 영역만 쓴다.
      return location.startsWith(AppRoutes.driverHome)
          ? null
          : AppRoutes.driverHome;
    },
    routes: [
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverPending,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        // 메일 링크: /reset-password?token=...
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        // 차주 전용 앱이라 역할 선택 없이 바로 차주 가입으로 간다.
        path: AppRoutes.signup,
        builder: (context, state) => const SignupFlowScreen(),
        routes: [
          // 예전 주소(/signup/driver 등)는 가입 첫 화면으로 보낸다.
          GoRoute(
            path: ':role',
            redirect: (context, state) => AppRoutes.signup,
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DriverShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.driverHome,
              builder: (context, state) => const LobbyScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.driverJobs,
              builder: (context, state) => const JobsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.driverMyOrders,
              builder: (context, state) => const MyOrdersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.driverSettlement,
              builder: (context, state) => const SettlementScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.driverSettings,
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'preferred-routes',
                  builder: (context, state) => const PreferredRoutesScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
      // 탭 밖의 상세 화면: 하단 탭을 가리고 뒤로 가면 보던 탭으로 돌아간다.
      GoRoute(
        path: '${AppRoutes.driverHome}/orders/:id',
        builder: (context, state) =>
            DetailScreen(orderId: state.pathParameters['id']!),
      ),
      // 운행 진행·증빙(D05). 상세처럼 하단 탭을 가린다.
      GoRoute(
        path: '${AppRoutes.driverHome}/trips/:id',
        builder: (context, state) =>
            TripScreen(orderId: state.pathParameters['id']!),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanged.dispose();
  });
  return router;
});
