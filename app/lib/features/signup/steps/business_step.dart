import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/demo_notice.dart';
import '../../auth/account_role.dart';
import '../document_capture_card.dart';
import '../document_scanner.dart';
import '../signup_controller.dart';

/// 화주 사업자등록증. 사진만 받고 입력은 시키지 않는다(사용자 결정 2026-11-04).
class BusinessStep extends ConsumerStatefulWidget {
  const BusinessStep({super.key});

  @override
  ConsumerState<BusinessStep> createState() => _BusinessStepState();
}

class _BusinessStepState extends ConsumerState<BusinessStep> {
  static const _role = AccountRole.shipper;

  late String? _photoPath =
      ref.read(signupControllerProvider(_role)).businessPhotoPath;

  Future<void> _capture() async {
    final path = await ref.read(photoCaptureProvider).capture();
    if (path == null || !mounted) return;
    setState(() => _photoPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(signupControllerProvider(_role)).submitting;
    final captured = _photoPath != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 실제 서류를 넣을 위험이 커서 이 단계에서 따로 안내한다.
                const DemoNotice(margin: EdgeInsets.only(bottom: 12)),
                DocumentCaptureCard(
                  title: '사업자등록증',
                  icon: Icons.description_outlined,
                  captured: captured,
                  busy: false,
                  onCapture: _capture,
                  hint: '사업자등록증 사진을 촬영해 주세요',
                  capturedText: '촬영 완료',
                ),
                if (captured)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '사업자등록증 사진은 팜카고가 직접 확인해요. 따로 입력할 내용은 없어요.',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.primaryDark),
                    ),
                  ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          label: '가입 완료',
          loading: submitting,
          onPressed: captured
              ? () => ref
                  .read(signupControllerProvider(_role).notifier)
                  .submitBusinessPhoto(_photoPath!)
              : null,
        ),
      ],
    );
  }
}
