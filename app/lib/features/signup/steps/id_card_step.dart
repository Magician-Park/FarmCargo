import 'package:flutter/material.dart';
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

/// 화주 본인 확인: 주민등록증 촬영 -> 자동 입력 -> 직접 수정.
class IdCardStep extends ConsumerStatefulWidget {
  const IdCardStep({super.key});

  @override
  ConsumerState<IdCardStep> createState() => _IdCardStepState();
}

class _IdCardStepState extends ConsumerState<IdCardStep> {
  static const _role = AccountRole.shipper;

  final _name = TextEditingController();
  final _resident = TextEditingController();
  final _address = TextEditingController();
  final _issued = TextEditingController();
  late final _all = Listenable.merge([_name, _resident, _address, _issued]);

  bool _captured = false;
  bool _busy = false;
  bool _recognized = true;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(signupControllerProvider(_role)).idCard;
    if (saved != null) {
      _fill(saved);
      _captured = true;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _resident, _address, _issued]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(IdCard v) {
    _name.text = v.name;
    _resident.text = v.residentNumber;
    _address.text = v.address;
    _issued.text = v.issuedDate;
  }

  Future<void> _capture() async {
    final path = await ref.read(photoCaptureProvider).capture();
    if (path == null || !mounted) return;
    setState(() => _busy = true);
    var result = IdCard.empty;
    var recognized = true;
    try {
      result = await ref.read(documentScannerProvider).scanIdCard(path);
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
      isValidResidentNumber(_resident.text) &&
      _address.text.trim().isNotEmpty &&
      isValidDate(_issued.text);

  void _next() {
    ref.read(signupControllerProvider(_role).notifier).submitIdCard(IdCard(
          name: _name.text.trim(),
          residentNumber: _resident.text,
          address: _address.text.trim(),
          issuedDate: _issued.text,
        ));
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
                    title: '주민등록증',
                    icon: Icons.credit_card_outlined,
                    captured: _captured,
                    busy: _busy,
                    onCapture: _capture,
                    hint: '실물 신분증 앞면을 촬영해 주세요',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                        content: Text('모바일 신분증 인증은 준비 중이에요. 실물 신분증을 촬영해 주세요.'),
                      )),
                      icon: const Icon(Icons.smartphone, size: 18),
                      label: const Text('모바일 신분증으로 인증'),
                    ),
                  ),
                  if (_captured) ...[
                    ScanResultBanner(recognized: _recognized),
                    LabeledTextField(label: '이름', controller: _name),
                    LabeledTextField(
                      label: '주민등록번호',
                      controller: _resident,
                      hint: '000000-0000000',
                      keyboardType: TextInputType.number,
                      inputFormatters: const [residentNumberFormatter],
                      validator: (v) => isValidResidentNumber(v)
                          ? null
                          : '주민등록번호를 다시 확인해 주세요.',
                    ),
                    LabeledTextField(label: '주소', controller: _address),
                    LabeledTextField(
                      label: '발급일자',
                      controller: _issued,
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
