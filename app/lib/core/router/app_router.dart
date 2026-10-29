import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/account_role.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/driver/detail_screen.dart';
import '../../features/driver/lobby_screen.dart';
import '../../features/shipper/shipper_lobby_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const driverHome = '/driver';
  static const shipperHome = '/shipper';

  static String driverOrder(String id) => '$driverHome/orders/$id';
  static String homeFor(AccountRole role) => switch (role) {
        AccountRole.driver => driverHome,
        AccountRole.shipper => shipperHome,
      };
}

final routerProvider = Provider<GoRouter>((ref) {
  // 로그인 상태가 바뀌면 redirect를 다시 평가한다.
  final authChanged = ValueNotifier<int>(0);
  ref.listen(authProvider, (previous, next) => authChanged.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authChanged,
    redirect: (context, state) {
      final role = ref.read(authProvider);
      final location = state.matchedLocation;
      if (role == null) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }
      // 로그인 상태에서는 자기 역할의 영역만 접근할 수 있다.
      final home = AppRoutes.homeFor(role);
      return location.startsWith(home) ? null : home;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
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
