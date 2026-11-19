import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/section_card.dart';
import '../orders/order_policy.dart';
import '../orders/orders_providers.dart';

/// 설정 > 경고·정지 내역(D14). 지금 경고 수, 경고마다의 사유, 정지 상태와 제재 규칙을 보여 준다.
class SanctionScreen extends ConsumerWidget {
  const SanctionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sanction = ref.watch(sanctionProvider);
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(
          title: const Text('경고·정지 내역',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: AsyncValueView(
        value: sanction,
        onRetry: () => ref.invalidate(sanctionProvider),
        builder: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusCard(sanction: s, now: now),
            const SizedBox(height: 16),
            Text('경고 ${s.warningCount}회',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (s.warnings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('받은 경고가 없어요.',
                    style: TextStyle(color: AppColors.textMuted)),
              )
            else
              for (final (i, w) in s.warnings.indexed)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.warningSoft,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warningText)),
                    ),
                    title: Text(w.reason),
                    subtitle: Text(formatDeadline(w.at)),
                  ),
                ),
            if (s.resetAt != null) ...[
              const SizedBox(height: 8),
              Text('${formatDeadline(s.resetAt!)}에 경고가 모두 초기화돼요(최초 경고 1년 뒤).',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
            const SizedBox(height: 20),
            const SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('경고·정지 기준',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    '· 경고 사유: 이유 없이 운행 시간을 지키지 않음, 사유가 불명확한 취소, '
                    '과도한 취소(하루 3건째부터), 앱 밖 직거래 시도, 패널티가 있는 조건 변경 거절\n'
                    '· 경고 1회: 24시간 오더 수락 정지\n'
                    '· 경고 2회: 7영업일 정지 · 3회: 30영업일 정지(영업일은 일요일만 뺌)\n'
                    '· 그 뒤에 또 경고를 받으면 영구 정지 심사\n'
                    '· 정지되면 아직 상차하지 않은 배차는 풀려 다른 차주에게 다시 배차돼요\n'
                    '· 최초 경고 1년 뒤 경고가 모두 초기화돼요',
                    style: TextStyle(
                        fontSize: 13, height: 1.6, color: AppColors.textChip),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('경고 내용이 사실과 다르면 고객센터로 문의해 주세요.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.sanction, required this.now});

  final DriverSanction sanction;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final suspended = sanction.isSuspended(now);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: suspended ? AppColors.warningBg : AppColors.primarySoft,
        border: Border.all(
            color: suspended ? AppColors.warningBorder : AppColors.primarySoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(suspended ? Icons.block : Icons.verified_user_outlined,
              color: suspended ? AppColors.warning : AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suspended ? sanction.message() : '지금은 오더를 수락할 수 있어요.',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: suspended
                      ? AppColors.warningText
                      : AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}
