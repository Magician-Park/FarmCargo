import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/account_role.dart';
import '../document_capture_card.dart';
import '../document_scanner.dart';
import '../signup_controller.dart';
import '../signup_models.dart';

/// 화물운송종사자격증: 촬영 -> 자동 입력 -> 직접 수정.
class LicenseStep extends ConsumerStatefulWidget {
  const LicenseStep({super.key});

  @override
  ConsumerState<LicenseStep> createState() => _LicenseStepState();
}

class _LicenseStepState extends ConsumerState<LicenseStep> {
  static const _role = AccountRole.driver;

  final _name = TextEditingController();
  final _birth = TextEditingController();
  final _number = TextEditingController();
  final _acquired = TextEditingController();
  late final _all = Listenable.merge([_name, _birth, _number, _acquired]);

  bool _captured = false;
  bool _busy = false;
  bool _recognized = true;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(signupControllerProvider(_role)).license;
    if (saved != null) {
      _fill(saved);
      _captured = true;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _birth, _number, _acquired]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(FreightLicense v) {
    _name.text = v.name;
    _birth.text = v.birthDate;
    _number.text = v.licenseNumber;
    _acquired.text = v.acquiredDate;
  }

  Future<void> _capture() async {
    final path = await ref.read(photoCaptureProvider).capture();
    if (path == null || !mounted) return;
    setState(() => _busy = true);
    var result = FreightLicense.empty;
    var recognized = true;
    try {
      result = await ref.read(documentScannerProvider).scanFreightLicense(path);
    } catch (_) {
      recognized = false;
    }
    if (!mounted) return;
    setState(() {
      _fill(result);
      _captured = true;
      _recognized = recognized;
      _busy = false;
    });
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      isValidDate(_birth.text) &&
      _number.text.trim().isNotEmpty &&
      isValidDate(_acquired.text);

  void _next() {
    ref.read(signupControllerProvider(_role).notifier).submitLicense(
          FreightLicense(
            name: _name.text.trim(),
            birthDate: _birth.text,
            licenseNumber: _number.text.trim(),
            acquiredDate: _acquired.text,
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ListenableBuilder(
              listenable: _all,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DocumentCaptureCard(
                    title: '화물운송종사자격증',
                    icon: Icons.badge_outlined,
                    captured: _captured,
                    busy: _busy,
                    onCapture: _capture,
                    hint: '자격증 앞면을 촬영해 주세요',
                  ),
                  if (_captured) ...[
                    ScanResultBanner(recognized: _recognized),
                    LabeledTextField(label: '성명', controller: _name),
                    LabeledTextField(
                      label: '생년월일',
                      controller: _birth,
                      hint: 'YYYY-MM-DD',
                      keyboardType: TextInputType.number,
                      inputFormatters: const [dateFormatter],
                      validator: (v) => isValidDate(v)
                          ? null
                          : '날짜를 YYYY-MM-DD 형식으로 입력해 주세요.',
                    ),
                    LabeledTextField(
                      label: '자격증번호',
                      controller: _number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9A-Za-z-]')),
                      ],
                    ),
                    LabeledTextField(
                      label: '자격취득일',
                      controller: _acquired,
                      hint: 'YYYY-MM-DD',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: const [dateFormatter],
                      validator: (v) => isValidDate(v)
                          ? null
                          : '날짜를 YYYY-MM-DD 형식으로 입력해 주세요.',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: _all,
          builder: (context, _) => BottomActionBar(
              label: '다음', onPressed: _captured && _valid ? _next : null),
        ),
      ],
    );
  }
}
