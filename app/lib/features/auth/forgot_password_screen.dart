import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'auth_provider.dart';

/// 가입할 때 등록한 이메일로 비밀번호 재설정 링크를 받는다.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _sentTo;
  String? _demoToken;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final email = _email.text.trim();
      final token =
          await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      // 가입 여부와 상관없이 같은 안내를 보여 가입된 이메일을 추측하지 못하게 한다.
      setState(() {
        _sent = true;
        _sentTo = email;
        _demoToken = token;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '뒤로가기',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: _sent ? _sentView() : _formView(),
      ),
    );
  }

  Widget _formView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('비밀번호 재설정',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  '가입할 때 등록한 이메일 주소를 입력해 주세요.\n비밀번호를 다시 설정할 수 있는 링크를 보내드려요.',
                  style: TextStyle(color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 28),
                LabeledTextField(
                  label: '이메일 주소',
                  controller: _email,
                  hint: 'example@farmcargo.kr',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      isValidEmail(v) ? null : '이메일 형식이 올바르지 않아요.',
                ),
              ],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: _email,
          builder: (context, _) => BottomActionBar(
            label: '재설정 링크 보내기',
            loading: _sending,
            onPressed: isValidEmail(_email.text) ? _send : null,
          ),
        ),
      ],
    );
  }

  Widget _sentView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mark_email_read_outlined,
                    size: 56, color: AppColors.primary),
                const SizedBox(height: 20),
                const Text('메일을 보냈어요',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  '$_sentTo 로 비밀번호 재설정 링크를 보냈어요.\n'
                  '가입된 주소라면 곧 도착해요. 메일이 보이지 않으면 스팸함도 확인해 주세요.',
                  style:
                      const TextStyle(color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 8),
                const Text('링크는 30분 동안만 쓸 수 있고, 한 번 쓰면 다시 쓸 수 없어요.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('[데모] 실제 메일은 발송되지 않아요.',
                          style: TextStyle(
                              color: AppColors.primaryDark, fontSize: 12)),
                      if (_demoToken != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => context
                              .push(AppRoutes.resetPasswordLink(_demoToken!)),
                          child: const Text('메일의 링크 열기'),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('가입되지 않은 주소라 링크가 만들어지지 않았어요.',
                              style: TextStyle(
                                  color: AppColors.primaryDark, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          label: '로그인으로 돌아가기',
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
