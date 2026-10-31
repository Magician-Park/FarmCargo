import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/labeled_text_field.dart';
import 'auth_provider.dart';
import 'auth_repository.dart';

/// 이메일(또는 휴대폰 번호)과 비밀번호로 로그인한다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  late final _all = Listenable.merge([_id, _password]);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // 성공하면 로그인 상태가 바뀌어 라우터가 홈으로 이동시킨다.
      await ref
          .read(authProvider.notifier)
          .signIn(identifier: _id.text, password: _password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '뒤로가기',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrGo(context, AppRoutes.welcome),
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
                    const Text('로그인',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 28),
                    LabeledTextField(
                      label: '이메일 주소',
                      controller: _id,
                      hint: 'example@farmcargo.kr',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    LabeledTextField(
                      label: '비밀번호',
                      controller: _password,
                      hint: '비밀번호를 입력해 주세요',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          foregroundColor: AppColors.textMuted,
                        ),
                        child: const Text('비밀번호를 잊으셨나요?',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.signup),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('혹시 회원이 아니신가요?',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _all,
              builder: (context, _) => BottomActionBar(
                label: '로그인',
                loading: _submitting,
                onPressed:
                    _id.text.trim().isNotEmpty && _password.text.isNotEmpty
                        ? _login
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
