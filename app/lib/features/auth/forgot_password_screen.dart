import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bottom_action_bar.dart';
import 'auth_provider.dart';
import 'phone_verification.dart';

/// 가입할 때 인증한 휴대폰 번호로 인증번호를 받아 비밀번호 재설정을 시작한다.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  String? _token; // 인증번호가 맞을 때 받는 재설정 토큰

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '뒤로가기',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('비밀번호 재설정',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text(
                      '가입할 때 인증한 휴대폰 번호를 입력해 주세요.\n문자로 받은 인증번호를 확인하면 새 비밀번호를 설정할 수 있어요.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    PhoneVerification(
                      onSend: repository.sendPasswordResetCode,
                      onVerify: (phone, code) async {
                        _token = await repository.verifyPasswordResetCode(
                            phone, code);
                        return _token != null;
                      },
                      onVerified: (_) => setState(() {}),
                      onInvalidated: () => setState(() => _token = null),
                      // 가입 여부를 알리지 않으려고 화면은 가입된 번호와 똑같이 동작한다.
                      noDemoCodeMessage: '[데모] 가입되지 않은 번호라 인증번호가 만들어지지 않았어요.',
                    ),
                  ],
                ),
              ),
            ),
            BottomActionBar(
              label: '새 비밀번호 설정하기',
              onPressed: _token == null
                  ? null
                  : () => context
                      .pushReplacement(AppRoutes.resetPasswordLink(_token!)),
            ),
          ],
        ),
      ),
    );
  }
}
