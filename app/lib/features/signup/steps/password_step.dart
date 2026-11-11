import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/account_role.dart';
import '../signup_controller.dart';

/// 차주 비밀번호·비밀번호 확인. 휴대폰 인증 다음 단계다(2026-11-05).
class PasswordStep extends ConsumerStatefulWidget {
  const PasswordStep({super.key});

  @override
  ConsumerState<PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends ConsumerState<PasswordStep> {
  static const _role = AccountRole.driver;

  late final _password = TextEditingController(
      text: ref.read(signupControllerProvider(_role)).password ?? '');
  late final _confirm = TextEditingController(text: _password.text);
  late final _all = Listenable.merge([_password, _confirm]);

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _valid =>
      isValidPassword(_password.text) && _confirm.text == _password.text;

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
          BottomActionBar(
            label: '다음',
            onPressed: _valid
                ? () => ref
                    .read(signupControllerProvider(_role).notifier)
                    .submitPassword(_password.text)
                : null,
          ),
        ],
      ),
    );
  }
}
