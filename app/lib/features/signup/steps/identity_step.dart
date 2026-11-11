import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/account_role.dart';
import '../../auth/auth_provider.dart';
import '../../auth/phone_verification.dart';
import '../signup_controller.dart';

/// 차주 이름 입력 + 휴대폰 문자 인증(필수). 인증한 번호가 로그인 아이디가 된다.
class IdentityStep extends ConsumerStatefulWidget {
  const IdentityStep({super.key});

  @override
  ConsumerState<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends ConsumerState<IdentityStep> {
  static const _role = AccountRole.driver;

  late final _name = TextEditingController(
      text: ref.read(signupControllerProvider(_role)).name ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(signupControllerProvider(_role).notifier);
    final verified = ref.watch(signupControllerProvider(_role)).verifiedPhone;
    final repository = ref.read(authRepositoryProvider);

    return Column(
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
                PhoneVerification(
                  initialVerifiedPhone: verified,
                  onSend: repository.sendPhoneCode,
                  onVerify: repository.verifyPhoneCode,
                  onVerified: controller.setPhoneVerified,
                  onInvalidated: controller.clearPhoneVerified,
                ),
              ],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: _name,
          builder: (context, _) => BottomActionBar(
            label: '다음',
            onPressed: verified != null && _name.text.trim().isNotEmpty
                ? () => controller.submitIdentity(_name.text.trim())
                : null,
          ),
        ),
      ],
    );
  }
}
