import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/period_selector.dart';

/// 정산 화면 틀. 정산 서버가 없어 금액은 늘 0원이고 내역은 비어 있다.
/// 상태 이름(지급 예정·지급 완료)은 확정 전 샘플이다.
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
  static const _statuses = ['전체', '지급 예정', '지급 완료'];

  late final DateTime _today = dateOnly(ref.read(clockProvider)());
  late PeriodOption _option = _options.first;
  late DateRange _range = _options.first.range!(_today);
  String _status = _statuses.first;

  @override
  Widget build(BuildContext context) {
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
            child: const Column(
              children: [
                _AmountRow(label: '지급 완료 운송비', amount: '0원'),
                SizedBox(height: 10),
                _AmountRow(label: '지급 예정 운송비', amount: '0원'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '운송비에서 수수료 4%를 뗀 금액이 화주 정산일 10일 뒤(은행 영업일)에 지급돼요. '
            '별점 랭킹 상위 차주는 수수료가 낮아져요.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Text('이 기간에 표시할 정산 내역이 없어요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
          ),
          const Text('정산 기능은 준비 중이에요. 상태 이름은 확정 전 예시예요.',
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
