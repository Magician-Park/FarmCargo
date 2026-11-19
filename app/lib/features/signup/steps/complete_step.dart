import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_action_bar.dart';

/// 가입 마지막 화면. 사측 심사가 남아 있어 ‘가입 신청 완료’로 안내한다.
class CompleteStep extends StatelessWidget {
  const CompleteStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      size: 72, color: AppColors.warning),
                  SizedBox(height: 20),
                  Text('가입 신청이 접수되었어요',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    '팜카고가 제출한 서류를 확인하고 있어요.\n'
                    '심사 중에 로그인하면 승인 대기 화면이 보여요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        BottomActionBar(
          label: '처음 화면으로',
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ],
    );
  }
}
