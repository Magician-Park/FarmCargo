import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account.dart';
import 'account_role.dart';
import 'auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => MockAuthRepository());

/// 현재 로그인한 계정. null이면 로그아웃 상태이며 메모리에만 유지한다.
class AuthNotifier extends Notifier<Account?> {
  @override
  Account? build() => null;

  /// 차주 전용 앱이라 화주 계정은 로그인시키지 않는다(화주 앱은 별도, 2026-11-19).
  Future<void> signIn({required String phone, required String password}) async {
    final account = await ref
        .read(authRepositoryProvider)
        .signIn(phone: phone, password: password);
    if (account.role != AccountRole.driver) {
      throw const AuthException('화주 계정은 화주용 앱에서 이용해 주세요.');
    }
    state = account;
  }

  void logout() => state = null;
}

final authProvider = NotifierProvider<AuthNotifier, Account?>(AuthNotifier.new);
