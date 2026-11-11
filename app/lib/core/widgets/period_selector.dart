import 'package:flutter/material.dart';

import '../clock.dart';
import '../theme/app_theme.dart';

/// 조회 기간. [start]~[end] 날짜(둘 다 포함).
class DateRange {
  const DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  String get label {
    String f(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '${f(start)} ~ ${f(end)}';
  }

  bool contains(DateTime d) =>
      !dateOnly(d).isBefore(dateOnly(start)) && !dateOnly(d).isAfter(dateOnly(end));
}

/// 기간 고르기 선택지. [range]는 오늘 날짜로 기간을 만든다(직접입력은 null).
class PeriodOption {
  const PeriodOption(this.label, this.range);
  final String label;
  final DateRange Function(DateTime today)? range;

  static const directInput = PeriodOption('직접입력', null);
}

/// 기간 칩 한 줄 + 고른 기간 표시. 직접입력을 고르면 날짜 범위 선택 창을 연다.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.range,
    required this.today,
    required this.onChanged,
  });

  final List<PeriodOption> options;
  final PeriodOption selected;
  final DateRange range;
  final DateTime today;
  final void Function(PeriodOption option, DateRange range) onChanged;

  Future<void> _pick(BuildContext context, PeriodOption option) async {
    final fn = option.range;
    if (fn != null) {
      onChanged(option, fn(today));
      return;
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 3),
      lastDate: today,
      initialDateRange: DateTimeRange(start: range.start, end: range.end),
      helpText: '조회 기간 선택',
      saveText: '확인',
    );
    if (picked != null) {
      onChanged(option, DateRange(picked.start, picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final o in options) ...[
              Expanded(
                child: _PeriodChip(
                  label: o.label,
                  selected: o == selected,
                  onTap: () => _pick(context, o),
                ),
              ),
              if (o != options.last) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 15, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(range.label,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textChip)),
          ],
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.textChip)),
          ),
        ),
      ),
    );
  }
}
