import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

/// 앱 버전. 바꿀 때 `pubspec.yaml`의 version과 맞춘다.
const appVersion = '0.1.0';

/// 차주 설정(사용자 결정 2026-11-12 항목). 대부분 서버 연결 전이라 ‘준비 중’ 안내를 띄운다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _notReady(BuildContext context, String title, [String? message]) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message ?? '준비 중인 기능이에요. 정식 오픈 때 이용할 수 있어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 내 정보
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.local_shipping_outlined,
                      color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${account?.name ?? ''}님',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(account?.vehicleLabel ?? '차량 정보 없음',
                          style: const TextStyle(color: AppColors.textChip)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Tile(
            icon: Icons.description_outlined,
            label: '회원 가입 서류 변경',
            onTap: () => _notReady(context, '회원 가입 서류 변경'),
          ),
          _Tile(
            icon: Icons.notifications_none,
            label: '알림 설정',
            onTap: () => _notReady(context, '알림 설정',
                '배차·취소·증빙 알림은 앱 푸시와 카카오 알림톡으로 보내요. 알림 설정은 준비 중이에요.'),
          ),
          _Tile(
            icon: Icons.lock_outline,
            label: '비밀번호 재설정',
            onTap: () => _notReady(context, '비밀번호 재설정',
                '지금은 로그아웃한 뒤 로그인 화면의 ‘비밀번호를 잊으셨나요?’에서 바꿀 수 있어요.'),
          ),
          const _SectionGap(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: FilledButton.icon(
              onPressed: () => _notReady(context, '고객센터',
                  '고객센터는 24시간 전화로 응대해요. 전화번호는 정식 오픈 때 안내해 드려요.'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primaryDark,
              ),
              icon: const Icon(Icons.call),
              label: const Text('고객센터 전화',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('정산·오더 문의, 사고 신고는 고객센터로 전화해 주세요.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const _SectionGap(),
          _Tile(
            icon: Icons.policy_outlined,
            label: '약관 및 정책',
            onTap: () => _notReady(context, '약관 및 정책',
                '약관 전문은 서비스 오픈 전 법무 검토를 거쳐 게재될 예정이에요.'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.textMuted),
            title: Text('앱 버전'),
            trailing: Text(appVersion,
                style: TextStyle(color: AppColors.textMuted)),
          ),
          _Tile(
            icon: Icons.logout,
            label: '로그아웃',
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right, color: AppColors.borderStrong),
        onTap: onTap,
      );
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 16, thickness: 8, color: AppColors.surfaceMuted);
}
