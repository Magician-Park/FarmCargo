import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account.dart';
import 'auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => MockAuthRepository());

/// 현재 로그인한 계정. null이면 로그아웃 상태이며 메모리에만 유지한다.
class AuthNotifier extends Notifier<Account?> {
  @override
  Account? build() => null;

  Future<void> signIn({required String id, required String password}) async {
    state = await ref
        .read(authRepositoryProvider)
        .signIn(id: id, password: password);
  }

  void logout() => state = null;
}

final authProvider = NotifierProvider<AuthNotifier, Account?>(AuthNotifier.new);
