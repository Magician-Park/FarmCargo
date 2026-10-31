import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/account_role.dart';
import '../signup_controller.dart';
import '../signup_models.dart';

/// 이름 / 이메일 / 비밀번호 / 비밀번호 확인.
class AccountStep extends ConsumerStatefulWidget {
  const AccountStep({super.key, required this.role});

  final AccountRole role;

  @override
  ConsumerState<AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<AccountStep> {
  late final _name = TextEditingController();
  late final _email = TextEditingController();
  late final _password = TextEditingController();
  late final _confirm = TextEditingController();

  late final _all = Listenable.merge([_name, _email, _password, _confirm]);

  @override
  void initState() {
    super.initState();
    final saved = ref.read(signupControllerProvider(widget.role)).account;
    if (saved != null) {
      _name.text = saved.name;
      _email.text = saved.email;
      _password.text = saved.password;
      _confirm.text = saved.password;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      isValidEmail(_email.text) &&
      isValidPassword(_password.text) &&
      _confirm.text == _password.text;

  void _next() {
    ref.read(signupControllerProvider(widget.role).notifier).submitAccount(
          AccountInfo(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _all,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledTextField(
                    label: '이름',
                    controller: _name,
                    hint: '실명을 입력해 주세요',
                  ),
                  LabeledTextField(
                    label: '이메일',
                    controller: _email,
                    hint: 'example@farmcargo.kr',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        isValidEmail(v) ? null : '이메일 형식이 올바르지 않아요.',
                  ),
                  LabeledTextField(
                    label: '비밀번호',
                    controller: _password,
                    hint: '8~16자 영문, 숫자, 기호 포함',
                    obscureText: true,
                    validator: (v) => isValidPassword(v)
                        ? null
                        : '8~16자의 영문, 숫자, 기호를 모두 포함해 주세요.',
                  ),
                  LabeledTextField(
                    label: '비밀번호 확인',
                    controller: _confirm,
                    hint: '비밀번호를 한 번 더 입력해 주세요',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                        v == _password.text ? null : '비밀번호가 일치하지 않아요.',
                  ),
                ],
              ),
            ),
          ),
          BottomActionBar(label: '다음', onPressed: _valid ? _next : null),
        ],
      ),
    );
  }
}
