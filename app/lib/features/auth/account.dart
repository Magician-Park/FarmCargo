import 'account_role.dart';

/// 가입 심사 상태. 차주는 사측 심사가 끝나기 전까지 승인 대기 화면만 본다.
enum AccountStatus { approved, pending }

class Account {
  final String id;
  final AccountRole role;
  final String name;
  final String phone; // 로그인 아이디
  final AccountStatus status;

  const Account({
    required this.id,
    required this.role,
    required this.name,
    required this.phone,
    this.status = AccountStatus.approved,
  });

  bool get isPending => status == AccountStatus.pending;
}
