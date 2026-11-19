import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/period_selector.dart';
import '../orders/orders_providers.dart';
import '../orders/settlement.dart';

/// 정산 화면. 운송 완료·지급 보류 건을 기간·상태로 골라 보고, 누르면 정산 상세로 간다.
/// 서버가 없어 샘플 저장소에서 계산한 값이다(실제 확정은 서버).
/// 상태 이름은 사용자 결정(2026-11-12 17차): 화주 정산 대기·지급 예정·지급 완료·지급 보류(책임 확인 중).
class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  static final _options = [
    PeriodOption('당월', (t) => DateRange(DateTime(t.year, t.month), t)),
    PeriodOption('지난 3개월',
        (t) => DateRange(DateTime(t.year, t.month - 3, t.day), t)),
    PeriodOption('지난 6개월',
        (t) => DateRange(DateTime(t.year, t.month - 6, t.day), t)),
    PeriodOption.directInput,
  ];
  static const _statuses = ['전체', '화주 정산 대기', '지급 예정', '지급 완료', '지급 보류'];

  late final DateTime _today = dateOnly(ref.read(clockProvider)());
  late PeriodOption _option = _options.first;
  late DateRange _range = _options.first.range!(_today);
  String _status = _statuses.first;

  @override
  Widget build(BuildContext context) {
    final settlements = ref.watch(settlementsProvider);
    final all = settlements.value ?? const <SettlementItem>[];
    final inRange = [for (final s in all) if (_range.contains(s.record.date)) s];
    int sum(SettlementStatus st) => inRange
        .where((s) => s.status == st)
        .fold<int>(0, (a, s) => a + s.payout);
    int count(SettlementStatus st) =>
        inRange.where((s) => s.status == st).length;
    final shown = [
      for (final s in inRange)
        if (_status == _statuses.first || s.status.label == _status) s
    ];
    return Scaffold(
      appBar: AppBar(
          title: const Text('정산', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          PeriodSelector(
            options: _options,
            selected: _option,
            range: _range,
            today: _today,
            onChanged: (o, r) => setState(() {
              _option = o;
              _range = r;
            }),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _AmountRow(
                    label: '지급 완료 운송비',
                    amount: '${formatWon(sum(SettlementStatus.paid))}원'),
                const SizedBox(height: 10),
                _AmountRow(
                    label: '지급 예정 운송비',
                    amount: '${formatWon(sum(SettlementStatus.scheduled))}원'),
                if (count(SettlementStatus.awaitingShipper) +
                        count(SettlementStatus.held) >
                    0) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                        '화주 정산 대기 ${count(SettlementStatus.awaitingShipper)}건 · '
                        '지급 보류 ${count(SettlementStatus.held)}건',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const _RankingCard(),
          const SizedBox(height: 10),
          const Text(
            '부가세를 포함한 운송비에서 수수료 4%를 뗀 금액이 화주 정산일 10일 뒤(은행 영업일)에 지급돼요. '
            '별점 랭킹 상위 차주는 수수료가 낮아져요.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in _statuses)
                ChoiceChip(
                  label: Text(s),
                  selected: s == _status,
                  onSelected: (_) => setState(() => _status = s),
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: s == _status
                          ? AppColors.primaryDark
                          : AppColors.textChip),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AsyncValueView(
            value: settlements,
            onRetry: () => ref.invalidate(settlementsProvider),
            builder: (_) => shown.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text('이 기간에 표시할 정산 내역이 없어요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted)),
                  )
                : Column(
                    children: [
                      for (final s in shown) ...[
                        SettlementCard(
                          item: s,
                          onTap: () => context.push(
                              AppRoutes.driverSettlementDetail(s.record.orderId)),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          const Text('지급 보류는 사고 책임을 고객센터가 확인하는 동안이에요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount});
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.accentMint)),
        const Spacer(),
        Text(amount,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// 이번 달 별점·예상 수수료율 요약. 누르면 별점·랭킹 화면.
class _RankingCard extends ConsumerWidget {
  const _RankingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(rankingProvider).value;
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRoutes.driverRanking),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ranking == null
                      ? '별점·랭킹'
                      : '이번 달 별 ${ranking.myStars}개 · 예상 수수료율 ${feeRateLabel(ranking.feePerMille)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// 정산 목록의 한 건.
class SettlementCard extends StatelessWidget {
  const SettlementCard({super.key, required this.item, required this.onTap});

  final SettlementItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = item.record;
    final payoutOn = item.payoutOn;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.primarySoft),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(formatShortDate(r.date),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const Spacer(),
                  SettlementStatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: 6),
              Text('${r.originRegion} → ${r.destinationRegion}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payoutOn == null
                          ? r.itemLabel
                          : '${r.itemLabel} · ${formatShortDate(payoutOn)} 지급',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textChip),
                    ),
                  ),
                  Text('${formatWon(item.payout)}원',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 정산 상태 칩. 지급 보류는 주의 색.
class SettlementStatusChip extends StatelessWidget {
  const SettlementStatusChip({super.key, required this.status});
  final SettlementStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      SettlementStatus.held => (AppColors.warningBg, AppColors.warningText),
      SettlementStatus.paid => (AppColors.primary, Colors.white),
      _ => (AppColors.primarySoft, AppColors.primaryDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
