import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../auth/account_role.dart';
import '../signup_controller.dart';
import '../signup_models.dart';

/// 약관 동의. 필수 항목을 모두 체크해야 다음으로 넘어갈 수 있다.
class TermsStep extends ConsumerStatefulWidget {
  const TermsStep({super.key, required this.role});

  final AccountRole role;

  @override
  ConsumerState<TermsStep> createState() => _TermsStepState();
}

class _TermsStepState extends ConsumerState<TermsStep> {
  late final Set<TermsItem> _agreed = {
    ...ref.read(signupControllerProvider(widget.role)).agreedTerms,
  };

  bool get _all => _agreed.length == TermsItem.values.length;
  bool get _groupAll => TermsItem.serviceGroup.every(_agreed.contains);
  bool get _requiredDone => _agreed.containsAll(TermsItem.requiredItems);

  void _toggle(Iterable<TermsItem> items, bool on) => setState(() {
        on ? _agreed.addAll(items) : _agreed.removeAll(items);
      });

  void _showDocument(String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('약관 전문은 서비스 오픈 전 법무 검토를 거쳐 게재될 예정이에요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckRow(
                  label: '약관 전체동의',
                  bold: true,
                  checked: _all,
                  onChanged: (v) => _toggle(TermsItem.values, v),
                ),
                const Divider(height: 24),
                _CheckRow(
                  label: '(필수) ${TermsItem.age14.label}',
                  checked: _agreed.contains(TermsItem.age14),
                  onChanged: (v) => _toggle([TermsItem.age14], v),
                ),
                _CheckRow(
                  label: '(필수) 팜카고 이용약관 및 동의사항',
                  checked: _groupAll,
                  onChanged: (v) => _toggle(TermsItem.serviceGroup, v),
                ),
                for (final item in TermsItem.serviceGroup)
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: InkWell(
                      onTap: () => _showDocument(item.label),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('(필수) ${item.label}',
                            style: const TextStyle(
                                decoration: TextDecoration.underline,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                for (final item in const [
                  TermsItem.location,
                  TermsItem.privacyOptional,
                  TermsItem.marketing,
                ])
                  _CheckRow(
                    label: '(선택) ${item.label}',
                    checked: _agreed.contains(item),
                    onChanged: (v) => _toggle([item], v),
                    onDetail: item == TermsItem.marketing
                        ? null
                        : () => _showDocument(item.label),
                  ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          label: '다음',
          onPressed: _requiredDone
              ? () => ref
                  .read(signupControllerProvider(widget.role).notifier)
                  .submitTerms(Set.of(_agreed))
              : null,
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    this.bold = false,
    this.onDetail,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final bool bold;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: label,
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  color: checked ? AppColors.primary : AppColors.borderStrong,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: bold ? 17 : 15,
                        fontWeight:
                            bold ? FontWeight.bold : FontWeight.normal)),
              ),
              if (onDetail != null)
                IconButton(
                  tooltip: '$label 보기',
                  onPressed: onDetail,
                  icon: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
