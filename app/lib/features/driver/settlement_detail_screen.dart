import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/demo_notice.dart';
import '../orders/orders_providers.dart';
import '../orders/settlement.dart';
import 'settlement_screen.dart';

/// 정산 상세(D09): 운송비(부가세 포함)·수수료·지급액·화주 정산일·지급일.
class SettlementDetailScreen extends ConsumerWidget {
  const SettlementDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlements = ref.watch(settlementsProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('정산 상세',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: AsyncValueView(
        value: settlements,
        onRetry: () => ref.invalidate(settlementsProvider),
        builder: (list) {
          final item =
              list.where((s) => s.record.orderId == orderId).firstOrNull;
          if (item == null) {
            return const Center(child: Text('정산 내역을 찾을 수 없어요.'));
          }
          return _Body(item: item);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.item});
  final SettlementItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = item.record;
    final demo = ref.watch(isDemoRepositoryProvider);
    final rate = feeRateLabel(item.feePerMille);
    final held = item.status == SettlementStatus.held;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Text(formatShortDate(r.date),
                style: const TextStyle(color: AppColors.textMuted)),
            const Spacer(),
            SettlementStatusChip(status: item.status),
          ],
        ),
        const SizedBox(height: 6),
        Text('${r.originRegion} → ${r.destinationRegion}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${r.itemLabel} · ${r.quantity}',
            style: const TextStyle(color: AppColors.textChip)),
        const SizedBox(height: 16),
        _Section(children: [
          _Row('운송비(부가세 별도)', '${formatWon(item.supply)}원'),
          _Row('부가세(10%)', '${formatWon(item.vat)}원'),
          _Row('운송비 합계(부가세 포함)', '${formatWon(item.total)}원', bold: true),
          _Row(item.rateFinal ? '수수료($rate)' : '수수료(예상 $rate)',
              '- ${formatWon(item.fee)}원'),
          const Divider(height: 20),
          _Row(held ? '지급액(보류 중)' : '받을 금액', '${formatWon(item.payout)}원',
              bold: true, highlight: true),
        ]),
        const SizedBox(height: 12),
        _Section(children: [
          _Row('화주 정산일',
              item.shipperPaidOn == null ? '아직 정산 전' : formatShortDate(item.shipperPaidOn!)),
          _Row('지급일',
              item.payoutOn == null ? '화주 정산 뒤 정해져요' : formatShortDate(item.payoutOn!)),
        ]),
        const SizedBox(height: 12),
        Text(
          [
            '수수료는 부가세를 포함한 운송비에 매기고, 1원 미만은 반올림해요.',
            '수수료율은 그 달 별점 랭킹으로 정해져요(기본 4%, 상위 10% 3.5%, 상위 5% 3%).'
                '${item.rateFinal ? '' : ' 달이 끝나기 전이라 바뀔 수 있어요.'}',
            '지급일은 화주 정산일 10일 뒤예요. 그날이 주말·공휴일이면 그 전 은행 영업일에 지급해요.',
            if (held) '사고 책임을 고객센터가 확인하는 동안 지급을 보류해요. 결과는 고객센터가 안내해요.',
          ].join('\n'),
          style: const TextStyle(
              fontSize: 12, height: 1.6, color: AppColors.textMuted),
        ),
        if (demo && item.status == SettlementStatus.awaitingShipper) ...[
          const SizedBox(height: 16),
          const DemoNotice(),
          const SizedBox(height: 6),
          const Text('시연용: 화주 앱이 아직 없어 화주의 운송비 정산(입금)을 대신 누를 수 있어요. 오늘이 화주 정산일이 돼요.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () => simulateShipperPayment(ref, r.orderId),
            child: const Text('화주: 운송비 정산'),
          ),
        ],
        if (demo) ...[
          const SizedBox(height: 8),
          const Text('주말·공휴일 계산: 시연판은 주말만 빼요. 공휴일은 서버 연결 때 반영해요.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primarySoft),
        ),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false, this.highlight = false});
  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.textChip,
                      fontWeight: bold ? FontWeight.bold : null)),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: highlight ? 18 : 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                    color: highlight ? AppColors.primaryDark : null)),
          ],
        ),
      );
}
