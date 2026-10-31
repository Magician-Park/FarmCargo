import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/account_role.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/onboarding/permissions_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/driver/detail_screen.dart';
import '../../features/driver/lobby_screen.dart';
import '../../features/shipper/shipper_lobby_screen.dart';
import '../../features/signup/role_select_screen.dart';
import '../../features/signup/signup_flow_screen.dart';

abstract final class AppRoutes {
  static const permissions = '/permissions';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const driverHome = '/driver';
  static const shipperHome = '/shipper';

  static String resetPasswordLink(String token) =>
      '$resetPassword?token=${Uri.encodeQueryComponent(token)}';
  static String signupFlow(AccountRole role) => '$signup/${role.name}';
  static String driverOrder(String id) => '$driverHome/orders/$id';
  static String homeFor(AccountRole role) => switch (role) {
        AccountRole.driver => driverHome,
        AccountRole.shipper => shipperHome,
      };
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
      // 로그인 상태에서는 자기 역할의 영역만 접근할 수 있다.
      final home = AppRoutes.homeFor(account.role);
      return location.startsWith(home) ? null : home;
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
        path: AppRoutes.signup,
        builder: (context, state) => const RoleSelectScreen(),
        routes: [
          GoRoute(
            path: ':role',
            redirect: (context, state) =>
                AccountRole.values.asNameMap()[state.pathParameters['role']] ==
                        null
                    ? AppRoutes.signup
                    : null,
            builder: (context, state) => SignupFlowScreen(
              role: AccountRole.values.byName(state.pathParameters['role']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        builder: (context, state) => const LobbyScreen(),
        routes: [
          GoRoute(
            path: 'orders/:id',
            builder: (context, state) =>
                DetailScreen(orderId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.shipperHome,
        builder: (context, state) => const ShipperLobbyScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanged.dispose();
  });
  return router;
});
