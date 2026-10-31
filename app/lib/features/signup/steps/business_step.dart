import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/account_role.dart';
import '../document_capture_card.dart';
import '../document_scanner.dart';
import '../signup_controller.dart';
import '../signup_models.dart';

/// 사업자등록증: 촬영 -> 자동 입력 -> 직접 수정. 차주만 관할 세무서를 받는다.
class BusinessStep extends ConsumerStatefulWidget {
  const BusinessStep({super.key, required this.role});

  final AccountRole role;

  @override
  ConsumerState<BusinessStep> createState() => _BusinessStepState();
}

class _BusinessStepState extends ConsumerState<BusinessStep> {
  final _number = TextEditingController();
  final _company = TextEditingController();
  final _rep = TextEditingController();
  final _birth = TextEditingController();
  final _opened = TextEditingController();
  final _address = TextEditingController();
  final _type = TextEditingController();
  final _reason = TextEditingController();
  final _coRep = TextEditingController();
  final _taxEmail = TextEditingController();
  final _issued = TextEditingController();
  final _taxOffice = TextEditingController();

  late final _controllers = [
    _number, _company, _rep, _birth, _opened, _address, //
    _type, _reason, _coRep, _taxEmail, _issued, _taxOffice,
  ];
  late final _all = Listenable.merge(_controllers);

  bool get _isDriver => widget.role == AccountRole.driver;

  bool _captured = false;
  bool _busy = false;
  bool _recognized = true;
  bool? _consolidated; // 사업자 단위 과세 적용사업자 여부: true=여, false=부

  @override
  void initState() {
    super.initState();
    final saved = ref.read(signupControllerProvider(widget.role)).business;
    if (saved != null) {
      _fill(saved);
      _captured = true;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(BusinessRegistration v) {
    _number.text = v.registrationNumber;
    _company.text = v.companyName;
    _rep.text = v.representativeName;
    _birth.text = v.birthDate;
    _opened.text = v.openedDate;
    _address.text = v.address;
    _type.text = v.businessType;
    _reason.text = v.issueReason;
    _coRep.text = v.coRepresentative;
    _taxEmail.text = v.taxInvoiceEmail;
    _issued.text = v.issuedDate;
    _taxOffice.text = v.taxOffice;
    _consolidated = v.isConsolidatedTax;
  }

  Future<void> _capture() async {
    final path = await ref.read(photoCaptureProvider).capture();
    if (path == null || !mounted) return;
    setState(() => _busy = true);
    var result = BusinessRegistration.empty;
    var recognized = true;
    try {
      result = await ref
          .read(documentScannerProvider)
          .scanBusinessRegistration(path, includeTaxOffice: _isDriver);
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

  bool _filled(TextEditingController c) => c.text.trim().isNotEmpty;

  /// 발급사유와 공동사업자는 해당 없을 수 있어 선택 입력이다.
  bool get _valid =>
      isValidBusinessNumber(_number.text) &&
      _filled(_company) &&
      _filled(_rep) &&
      isValidDate(_birth.text) &&
      isValidDate(_opened.text) &&
      _filled(_address) &&
      _filled(_type) &&
      _consolidated != null &&
      isValidEmail(_taxEmail.text) &&
      isValidDate(_issued.text) &&
      (!_isDriver || _filled(_taxOffice));

  void _submit() {
    ref
        .read(signupControllerProvider(widget.role).notifier)
        .submitBusiness(BusinessRegistration(
          registrationNumber: _number.text,
          companyName: _company.text.trim(),
          representativeName: _rep.text.trim(),
          birthDate: _birth.text,
          openedDate: _opened.text,
          address: _address.text.trim(),
          businessType: _type.text.trim(),
          issueReason: _reason.text.trim(),
          coRepresentative: _coRep.text.trim(),
          isConsolidatedTax: _consolidated,
          taxInvoiceEmail: _taxEmail.text.trim(),
          issuedDate: _issued.text,
          taxOffice: _isDriver ? _taxOffice.text.trim() : '',
        ));
  }

  String? _dateError(String v) =>
      isValidDate(v) ? null : '날짜를 YYYY-MM-DD 형식으로 입력해 주세요.';

  @override
  Widget build(BuildContext context) {
    final submitting =
        ref.watch(signupControllerProvider(widget.role)).submitting;

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
                    title: '사업자등록증',
                    icon: Icons.description_outlined,
                    captured: _captured,
                    busy: _busy,
                    onCapture: _capture,
                    hint: '사업자등록증을 촬영해 주세요',
                  ),
                  if (_captured) ...[
                    ScanResultBanner(recognized: _recognized),
                    LabeledTextField(
                      label: '등록번호',
                      controller: _number,
                      hint: '000-00-00000',
                      keyboardType: TextInputType.number,
                      inputFormatters: const [businessNumberFormatter],
                      validator: (v) => isValidBusinessNumber(v)
                          ? null
                          : '사업자등록번호를 다시 확인해 주세요.',
                    ),
                    LabeledTextField(label: '상호명', controller: _company),
                    LabeledTextField(label: '성명', controller: _rep),
                    LabeledTextField(
                      label: '생년월일',
                      controller: _birth,
                      hint: 'YYYY-MM-DD',
                      keyboardType: TextInputType.number,
                      inputFormatters: const [dateFormatter],
                      validator: _dateError,
                    ),
                    LabeledTextField(
                      label: '개업 연월일',
                      controller: _opened,
                      hint: 'YYYY-MM-DD',
                      keyboardType: TextInputType.number,
                      inputFormatters: const [dateFormatter],
                      validator: _dateError,
                    ),
                    LabeledTextField(label: '사업장 소재지', controller: _address),
                    LabeledTextField(
                        label: '사업의 종류', controller: _type, hint: '업태 / 종목'),
                    LabeledTextField(
                        label: '발급사유', controller: _reason, optional: true),
                    LabeledTextField(
                        label: '공동사업자', controller: _coRep, optional: true),
                    _ConsolidatedTaxField(
                      value: _consolidated,
                      onChanged: (v) => setState(() => _consolidated = v),
                    ),
                    LabeledTextField(
                      label: '전자세금계산서 전용 전자우편주소',
                      controller: _taxEmail,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          isValidEmail(v) ? null : '이메일 형식이 올바르지 않아요.',
                    ),
                    LabeledTextField(
                      label: '발급일자',
                      controller: _issued,
                      hint: 'YYYY-MM-DD',
                      keyboardType: TextInputType.number,
                      textInputAction: _isDriver
                          ? TextInputAction.next
                          : TextInputAction.done,
                      inputFormatters: const [dateFormatter],
                      validator: _dateError,
                    ),
                    if (_isDriver)
                      LabeledTextField(
                        label: '관할 세무서',
                        controller: _taxOffice,
                        hint: '예: 강서세무서',
                        textInputAction: TextInputAction.done,
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
            label: '가입 완료',
            loading: submitting,
            onPressed: _captured && _valid ? _submit : null,
          ),
        ),
      ],
    );
  }
}

/// 사업자 단위 과세 적용사업자 여부: 여/부 중 하나만 선택.
class _ConsolidatedTaxField extends StatelessWidget {
  const _ConsolidatedTaxField({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('사업자 단위 과세 적용사업자 여부',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              _option('여', true),
              const SizedBox(width: 24),
              _option('부', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(String label, bool optionValue) {
    final selected = value == optionValue;
    return Semantics(
      checked: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(optionValue),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
                color: selected ? AppColors.primary : AppColors.borderStrong,
              ),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
