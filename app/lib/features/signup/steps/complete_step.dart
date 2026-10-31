import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_action_bar.dart';

class CompleteStep extends StatelessWidget {
  const CompleteStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 72, color: AppColors.successText),
                  SizedBox(height: 20),
                  Text('회원가입이 완료되었어요',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('가입한 이메일과 비밀번호로 로그인해 주세요.',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
        BottomActionBar(
          label: '로그인하기',
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ],
    );
  }
}
