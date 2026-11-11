import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/account_role.dart';
import '../signup_controller.dart';
import '../signup_models.dart';

/// 차주 차량번호 입력, 차량 종류와 톤급 선택. 기타를 고르면 직접 입력한다.
class VehicleStep extends ConsumerStatefulWidget {
  const VehicleStep({super.key});

  @override
  ConsumerState<VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends ConsumerState<VehicleStep> {
  static const _role = AccountRole.driver;

  late final VehicleInfo? _saved =
      ref.read(signupControllerProvider(_role)).vehicle;
  late final _plate = TextEditingController(text: _saved?.plateNumber ?? '');
  late final _other = TextEditingController(text: _saved?.otherType ?? '');
  late final _all = Listenable.merge([_plate, _other]);
  late VehicleType? _type = _saved?.type;

  @override
  void dispose() {
    _plate.dispose();
    _other.dispose();
    super.dispose();
  }

  bool get _valid =>
      isValidPlateNumber(_plate.text) &&
      _type != null &&
      (_type != VehicleType.other || _other.text.trim().isNotEmpty);

  void _next() {
    ref.read(signupControllerProvider(_role).notifier).submitVehicle(
          VehicleInfo(
            plateNumber: normalizePlateNumber(_plate.text),
            type: _type!,
            otherType: _type == VehicleType.other ? _other.text.trim() : '',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _all,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledTextField(
                    label: '차량번호',
                    controller: _plate,
                    hint: '예: 경기12가3456 또는 12가3456',
                    validator: (v) => isValidPlateNumber(v)
                        ? null
                        : '차량번호를 다시 확인해 주세요. 예: 경기12가3456',
                  ),
                  const Text('차량 종류와 톤급',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final type in VehicleType.values)
                    _TypeOption(
                      label: type.label,
                      selected: _type == type,
                      onTap: () => setState(() => _type = type),
                    ),
                  if (_type == VehicleType.other) ...[
                    const SizedBox(height: 8),
                    LabeledTextField(
                      label: '차종·톤급 직접 입력',
                      controller: _other,
                      hint: '예: 윙바디(11톤)',
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ],
              ),
            ),
          ),
          BottomActionBar(label: '다음', onPressed: _valid ? _next : null),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected ? AppColors.primarySoft : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? AppColors.primary : AppColors.borderStrong,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
