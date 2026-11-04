import 'account.dart';
import 'account_role.dart';
import '../signup/signup_models.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 이미 가입된 휴대폰 번호로 가입하려는 경우. 휴대폰 번호가 기본 아이디다.
class DuplicatePhoneException extends AuthException {
  const DuplicatePhoneException() : super('이미 가입된 휴대폰 번호예요.');
}

/// 비밀번호 재설정 인증이 만료됐거나 이미 사용된 경우.
class ResetLinkExpiredException extends AuthException {
  const ResetLinkExpiredException() : super('인증시간이 만료되었습니다.');
}

/// 인증/회원가입 데이터 소스. 서버 연동 시 이 인터페이스의 구현만 교체한다.
abstract interface class AuthRepository {
  /// 아이디는 휴대폰 번호다.
  Future<Account> signIn({required String phone, required String password});

  /// 가입용 인증번호 문자를 보낸다. 데모 구현은 화면에 안내할 인증번호를 돌려준다.
  Future<String?> sendPhoneCode(String phone);

  Future<bool> verifyPhoneCode(String phone, String code);

  Future<Account> register(SignupRequest request);

  /// 비밀번호 재설정용 인증번호 문자를 보낸다. 가입 여부는 호출한 쪽에 알리지 않는다.
  /// 데모 구현은 가입된 번호일 때만 화면에 안내할 인증번호를 돌려준다(실제 구현은 null).
  Future<String?> sendPasswordResetCode(String phone);

  /// 인증번호가 맞으면 재설정 토큰을 돌려주고, 틀리거나 가입되지 않은 번호면 null.
  Future<String?> verifyPasswordResetCode(String phone, String code);

  /// [token]으로 비밀번호를 바꾼다. 토큰은 한 번만 쓸 수 있으며, 만료됐거나 이미 쓴
  /// 토큰이면 [ResetLinkExpiredException]을 던진다.
  Future<void> resetPassword(
      {required String token, required String newPassword});
}

/// 메모리에만 저장하는 데모 구현. 앱을 다시 실행하면 가입한 계정이 사라진다.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({DateTime Function()? now}) : _now = now ?? DateTime.now {
    _add(
      const Account(
          id: 'demo-driver',
          role: AccountRole.driver,
          name: '김기사',
          phone: '01011112222'),
      password: 'Passw0rd!',
    );
    _add(
      const Account(
          id: 'demo-shipper',
          role: AccountRole.shipper,
          name: '박농부',
          phone: '01033334444'),
      password: 'Passw0rd!',
    );
  }

  static const demoCode = '123456';
  static const resetTokenValidity = Duration(minutes: 10);

  final DateTime Function() _now;
  final _accounts = <String, _Record>{}; // 휴대폰 번호 -> 기록
  final _resetTokens = <String, _ResetToken>{};
  var _nextId = 1;
  var _nextTokenId = 1;

  void _add(Account account, {required String password}) {
    _accounts[account.phone] = _Record(account, password: password);
  }

  @override
  Future<Account> signIn(
      {required String phone, required String password}) async {
    final record = _accounts[phone.replaceAll(RegExp(r'[\s-]'), '')];
    if (record == null || record.password != password) {
      throw const AuthException('휴대폰 번호 또는 비밀번호가 올바르지 않아요.');
    }
    return record.account;
  }

  @override
  Future<String?> sendPhoneCode(String phone) async => demoCode;

  @override
  Future<bool> verifyPhoneCode(String phone, String code) async =>
      code == demoCode;

  @override
  Future<Account> register(SignupRequest request) async {
    if (_accounts.containsKey(request.phone)) {
      throw const DuplicatePhoneException();
    }
    final account = Account(
      id: 'user-${_nextId++}',
      role: request.role,
      name: request.account.name.trim(),
      phone: request.phone,
    );
    _add(account, password: request.account.password);
    return account;
  }

  @override
  Future<String?> sendPasswordResetCode(String phone) async =>
      _accounts.containsKey(phone) ? demoCode : null;

  @override
  Future<String?> verifyPasswordResetCode(String phone, String code) async {
    if (!_accounts.containsKey(phone) || code != demoCode) return null;
    // 새로 인증하면 이전에 받은 토큰은 쓸 수 없다.
    for (final t in _resetTokens.values.where((t) => t.phone == phone)) {
      t.used = true;
    }
    final token = 'reset-${_nextTokenId++}';
    _resetTokens[token] = _ResetToken(phone, _now().add(resetTokenValidity));
    return token;
  }

  @override
  Future<void> resetPassword(
      {required String token, required String newPassword}) async {
    final entry = _resetTokens[token];
    if (entry == null || entry.used || !_now().isBefore(entry.expiresAt)) {
      throw const ResetLinkExpiredException();
    }
    entry.used = true;
    _accounts[entry.phone]!.password = newPassword;
  }
}

class _Record {
  _Record(this.account, {required this.password});

  final Account account;
  String password;
}

class _ResetToken {
  _ResetToken(this.phone, this.expiresAt);

  final String phone;
  final DateTime expiresAt;
  bool used = false;
}
