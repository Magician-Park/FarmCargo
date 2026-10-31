import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 상단 단계 표시. [current] 앞 단계는 완료, [current]는 진행 중.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.labels, required this.current});

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Container(
                  height: 2,
                  color: i <= current ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          _Dot(label: labels[i], index: i, current: current),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.index, required this.current});

  final String label;
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    return Semantics(
      label: '${index + 1}단계 $label ${done ? '완료' : active ? '진행 중' : ''}',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.primary
                  : active
                      ? AppColors.primarySoft
                      : AppColors.surfaceMuted,
              border: active
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.primary : Colors.grey,
                    )),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? AppColors.primary : Colors.grey,
              )),
        ],
      ),
    );
  }
}
