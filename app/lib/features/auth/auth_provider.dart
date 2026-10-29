import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_role.dart';

/// 데모 로그인 상태. null이면 로그아웃 상태이며 메모리에만 유지한다.
class AuthNotifier extends Notifier<AccountRole?> {
  @override
  AccountRole? build() => null;

  void login(AccountRole role) => state = role;

  void logout() => state = null;
}

final authProvider =
    NotifierProvider<AuthNotifier, AccountRole?>(AuthNotifier.new);
