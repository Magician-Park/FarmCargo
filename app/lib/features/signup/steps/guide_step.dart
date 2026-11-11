import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/account_role.dart';
import '../signup_controller.dart';
import '../signup_models.dart';

/// 차주 가입 조건 안내(요구사항 3절 ‘차주 회원가입 흐름’ 1번).
class GuideStep extends ConsumerWidget {
  const GuideStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              const Text('가입 전에 확인해 주세요',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('아래 조건을 모두 갖춘 분만 차주로 가입할 수 있어요.',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              _Condition(
                number: 1,
                title: '개별화물 자동차 운송사업자',
                lines: [for (final t in VehicleType.values) t.label],
              ),
              const SizedBox(height: 12),
              const _Condition(
                number: 2,
                title: '전자세금계산서를 발행할 수 있는 사업자',
                lines: ['일반과세자', '간이과세자(세금계산서 발행이 가능한 사업자)'],
              ),
              const SizedBox(height: 12),
              _Condition(
                number: 3,
                title: '필수 제출 서류',
                lines: [for (final d in DriverDocument.values) d.label],
              ),
              const SizedBox(height: 16),
              const Text(
                '서류는 사진으로 찍어 제출하고, 팜카고가 확인한 뒤 가입을 승인해요.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        BottomActionBar(
          label: '확인했어요',
          onPressed: () => ref
              .read(signupControllerProvider(AccountRole.driver).notifier)
              .confirmGuide(),
        ),
      ],
    );
  }
}

class _Condition extends StatelessWidget {
  const _Condition(
      {required this.number, required this.title, required this.lines});

  final int number;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. $title',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('· $line',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textStrong)),
            ),
        ],
      ),
    );
  }
}
