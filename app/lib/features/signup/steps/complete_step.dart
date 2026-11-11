import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../auth/account_role.dart';

/// 가입 마지막 화면. 차주는 사측 심사가 남아 있어 ‘가입 신청 완료’로 안내한다.
class CompleteStep extends StatelessWidget {
  const CompleteStep({super.key, required this.role});

  final AccountRole role;

  @override
  Widget build(BuildContext context) {
    final driver = role == AccountRole.driver;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(driver ? Icons.hourglass_top_rounded : Icons.check_circle,
                      size: 72,
                      color: driver ? AppColors.warning : AppColors.successText),
                  const SizedBox(height: 20),
                  Text(driver ? '가입 신청이 접수되었어요' : '회원가입이 완료되었어요',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    driver
                        ? '팜카고가 제출한 서류를 확인하고 있어요.\n'
                            '심사 중에 로그인하면 승인 대기 화면이 보여요.'
                        : '가입한 휴대폰 번호와 비밀번호로 로그인해 주세요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        BottomActionBar(
          label: driver ? '처음 화면으로' : '로그인하기',
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ],
    );
  }
}
