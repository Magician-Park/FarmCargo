import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/bottom_action_bar.dart';
import '../../auth/account_role.dart';
import '../../auth/auth_provider.dart';
import '../../auth/phone_verification.dart';
import '../signup_controller.dart';

/// 휴대폰 번호 인증(필수). 인증한 번호가 로그인 아이디가 된다.
class PhoneStep extends ConsumerWidget {
  const PhoneStep({super.key, required this.role});

  final AccountRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(signupControllerProvider(role).notifier);
    final verified = ref.watch(signupControllerProvider(role)).verifiedPhone;
    final repository = ref.read(authRepositoryProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: PhoneVerification(
              initialVerifiedPhone: verified,
              onSend: repository.sendPhoneCode,
              onVerify: repository.verifyPhoneCode,
              onVerified: controller.setPhoneVerified,
              onInvalidated: controller.clearPhoneVerified,
            ),
          ),
        ),
        BottomActionBar(
          label: '다음',
          onPressed: verified != null ? controller.submitPhone : null,
        ),
      ],
    );
  }
}
