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
import 'auth_repository.dart';

/// 메일 링크로 들어와 새 비밀번호를 설정한다.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final _all = Listenable.merge([_password, _confirm]);
  bool _submitting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _valid =>
      isValidPassword(_password.text) && _confirm.text == _password.text;

  Future<void> _showResult({required String message, required bool success}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle : Icons.error_outline,
          size: 40,
          color: success ? AppColors.successText : Colors.red,
        ),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    String? error;
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(token: widget.token, newPassword: _password.text);
    } on AuthException catch (e) {
      error = e.message;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      await _showResult(message: '비밀번호가 성공적으로 재설정되었습니다!', success: true);
    } else {
      await _showResult(message: error, success: false);
    }
    if (!mounted) return;
    // 성공이든 만료든 로그인 화면에서 이어간다.
    context.go(AppRoutes.login);
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
                    const SizedBox(height: 20),
                    const Text('새로 사용할 비밀번호를 입력해 주세요.',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('8~16자 이내의 영문, 숫자, 기호를 포함한 문자열',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    LabeledTextField(
                      label: '새 비밀번호',
                      controller: _password,
                      hint: '새 비밀번호 입력',
                      obscureText: true,
                      validator: (v) => isValidPassword(v)
                          ? null
                          : '8~16자의 영문, 숫자, 기호를 모두 포함해 주세요.',
                    ),
                    LabeledTextField(
                      label: '새 비밀번호 확인',
                      controller: _confirm,
                      hint: '새 비밀번호 확인',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          v == _password.text ? null : '비밀번호가 일치하지 않아요.',
                    ),
                  ],
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _all,
              builder: (context, _) => BottomActionBar(
                label: '비밀번호 재설정하기',
                loading: _submitting,
                onPressed: _valid ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
