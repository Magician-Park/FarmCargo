import 'account_role.dart';

class Account {
  final String id;
  final AccountRole role;
  final String name;
  final String email;

  const Account({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
  });
}
