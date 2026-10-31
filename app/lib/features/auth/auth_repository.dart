import 'account.dart';
import 'account_role.dart';
import '../signup/signup_models.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 비밀번호 재설정 링크가 만료됐거나 이미 사용된 경우.
class ResetLinkExpiredException extends AuthException {
  const ResetLinkExpiredException() : super('인증시간이 만료되었습니다.');
}

/// 인증/회원가입 데이터 소스. 서버 연동 시 이 인터페이스의 구현만 교체한다.
abstract interface class AuthRepository {
  /// [identifier]는 이메일 또는 휴대폰 번호.
  Future<Account> signIn(
      {required String identifier, required String password});

  /// 인증번호 문자를 보낸다. 데모 구현은 화면에 안내할 인증번호를 돌려준다.
  Future<String?> sendPhoneCode(String phone);

  Future<bool> verifyPhoneCode(String phone, String code);

  Future<Account> register(SignupRequest request);

  /// 가입된 이메일이면 재설정 링크를 메일로 보낸다. 가입 여부는 호출한 쪽에 알리지 않는다.
  /// 데모 구현은 화면에서 링크를 열 수 있도록 토큰을 돌려준다(실제 구현은 null).
  Future<String?> requestPasswordReset(String email);

  /// 링크의 [token]으로 비밀번호를 바꾼다. 링크는 한 번만 쓸 수 있으며,
  /// 만료됐거나 이미 쓴 링크면 [ResetLinkExpiredException]을 던진다.
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
          email: 'driver@farmcargo.test'),
      password: 'Passw0rd!',
      phone: '01011112222',
    );
    _add(
      const Account(
          id: 'demo-shipper',
          role: AccountRole.shipper,
          name: '박농부',
          email: 'shipper@farmcargo.test'),
      password: 'Passw0rd!',
      phone: '01033334444',
    );
  }

  static const demoCode = '123456';
  static const resetLinkValidity = Duration(minutes: 30);

  final DateTime Function() _now;
  final _resetTokens = <String, _ResetToken>{};
  var _nextTokenId = 1;

  final _accounts = <String, _Record>{}; // 소문자 이메일 -> 기록
  var _nextId = 1;

  void _add(Account account,
      {required String password, required String phone}) {
    _accounts[account.email.toLowerCase()] =
        _Record(account, password: password, phone: phone);
  }

  @override
  Future<Account> signIn(
      {required String identifier, required String password}) async {
    final key = identifier.trim();
    _Record? record = _accounts[key.toLowerCase()];
    record ??= _accounts.values.where((r) => r.phone == key).firstOrNull;
    if (record == null || record.password != password) {
      throw const AuthException('이메일 또는 비밀번호가 올바르지 않아요.');
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
    final email = request.account.email.trim();
    if (_accounts.containsKey(email.toLowerCase())) {
      throw const AuthException('이미 가입된 이메일이에요.');
    }
    if (_accounts.values.any((r) => r.phone == request.phone)) {
      throw const AuthException('이미 가입된 휴대폰 번호예요.');
    }
    final account = Account(
      id: 'user-${_nextId++}',
      role: request.role,
      name: request.account.name.trim(),
      email: email,
    );
    _add(account, password: request.account.password, phone: request.phone);
    return account;
  }

  @override
  Future<String?> requestPasswordReset(String email) async {
    final key = email.trim().toLowerCase();
    if (!_accounts.containsKey(key)) return null;
    // 새 링크를 보내면 이전 링크는 쓸 수 없다.
    for (final t in _resetTokens.values.where((t) => t.email == key)) {
      t.used = true;
    }
    final token = 'reset-${_nextTokenId++}';
    _resetTokens[token] = _ResetToken(key, _now().add(resetLinkValidity));
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
    _accounts[entry.email]!.password = newPassword;
  }
}

class _Record {
  _Record(this.account, {required this.password, required this.phone});

  final Account account;
  String password;
  final String phone;
}

class _ResetToken {
  _ResetToken(this.email, this.expiresAt);

  final String email;
  final DateTime expiresAt;
  bool used = false;
}
