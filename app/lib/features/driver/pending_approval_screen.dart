import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

/// 가입 심사 중인 차주가 로그인하면 보는 유일한 화면(사용자 결정 2026-11-11).
/// 오더 찾기·홈 등 다른 화면에는 들어갈 수 없다.
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로그아웃 직후 라우터가 이동시키기 전까지 계정이 null일 수 있다.
    final name = ref.watch(authProvider)?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('승인 대기'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('로그아웃'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 72, color: AppColors.warning),
                const SizedBox(height: 20),
                Text('$name님, 가입 심사 중이에요',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  '팜카고가 제출하신 서류와 차량번호를 확인하고 있어요.\n'
                  '승인되면 오더 찾기와 홈 화면을 이용할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Text('궁금한 점은 고객센터로 문의해 주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
