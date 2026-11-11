import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/demo_notice.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/account_role.dart';
import '../document_capture_card.dart';
import '../document_scanner.dart';
import '../photo_preview.dart';
import '../signup_controller.dart';
import '../signup_models.dart';

/// 차주 서류 제출. 사업자등록증·통장 사본·운전면허증을 사진으로 찍고(항목 입력·자동 입력 없음),
/// 같은 화면 아래에서 전자세금계산서 전용 이메일과 세금계산서 위수탁 동의를 받는다.
class DocumentsStep extends ConsumerStatefulWidget {
  const DocumentsStep({super.key});

  @override
  ConsumerState<DocumentsStep> createState() => _DocumentsStepState();
}

class _DocumentsStepState extends ConsumerState<DocumentsStep> {
  static const _role = AccountRole.driver;

  late final DriverDocuments? _saved =
      ref.read(signupControllerProvider(_role)).driverDocuments;
  late final Map<DriverDocument, String> _photos = {...?_saved?.photoPaths};
  late final _email =
      TextEditingController(text: _saved?.taxInvoiceEmail ?? '');
  late bool _agreed = _saved?.consignmentAgreed ?? false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _capture(DriverDocument document) async {
    final path = await ref.read(photoCaptureProvider).capture();
    if (path == null || !mounted) return;
    setState(() => _photos[document] = path);
  }

  bool get _valid =>
      DriverDocument.values.every(_photos.containsKey) &&
      isValidEmail(_email.text) &&
      _agreed;

  void _submit() {
    ref.read(signupControllerProvider(_role).notifier).submitDriverDocuments(
          DriverDocuments(
            photoPaths: Map.of(_photos),
            taxInvoiceEmail: _email.text.trim(),
            consignmentAgreed: _agreed,
          ),
        );
  }

  void _showConsignment() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('세금계산서 위수탁 동의'),
        content: const Text(
          '운송비 세금계산서를 차주님 대신 팜카고(앱)가 발행할 수 있도록 맡기는 데 동의하는 절차예요.\n\n'
          '정식 동의서 양식은 세무사가 작성하고 있어요. 양식이 준비되면 다시 안내해 드려요.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(signupControllerProvider(_role)).submitting;
    final preview = ref.watch(photoPreviewProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 실제 서류를 넣을 위험이 커서 이 단계에서 따로 안내한다.
                const DemoNotice(margin: EdgeInsets.only(bottom: 12)),
                const Text('서류는 사진만 제출해요. 따로 입력할 항목은 없어요.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                for (final document in DriverDocument.values) ...[
                  DocumentCaptureCard(
                    title: document.label,
                    icon: switch (document) {
                      DriverDocument.businessRegistration =>
                        Icons.description_outlined,
                      DriverDocument.bankbook => Icons.account_balance_outlined,
                      DriverDocument.driverLicense => Icons.badge_outlined,
                    },
                    captured: _photos.containsKey(document),
                    busy: false,
                    onCapture: () => _capture(document),
                    hint: '${document.label} 사진을 촬영해 주세요',
                    capturedText: '승인 대기',
                    capturedColor: AppColors.warning,
                    preview: _photos.containsKey(document)
                        ? preview(_photos[document]!)
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                LabeledTextField(
                  label: '전자세금계산서 전용 이메일',
                  controller: _email,
                  hint: '세금계산서를 받을 이메일 주소',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      isValidEmail(v) ? null : '이메일 형식이 올바르지 않아요.',
                  onChanged: (_) => setState(() {}),
                ),
                _ConsignmentRow(
                  checked: _agreed,
                  onChanged: (v) => setState(() => _agreed = v),
                  onDetail: _showConsignment,
                ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          label: '가입 신청',
          loading: submitting,
          onPressed: _valid ? _submit : null,
        ),
      ],
    );
  }
}

class _ConsignmentRow extends StatelessWidget {
  const _ConsignmentRow(
      {required this.checked, required this.onChanged, required this.onDetail});

  static const _label = '(필수) 세금계산서 발행 위수탁에 동의합니다';

  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            checked: checked,
            label: _label,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onChanged(!checked),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_box : Icons.check_box_outline_blank,
                      color:
                          checked ? AppColors.primary : AppColors.borderStrong,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text(_label, style: TextStyle(fontSize: 15))),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: '위수탁 동의 내용 보기',
          onPressed: onDetail,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
