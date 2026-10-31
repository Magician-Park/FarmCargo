import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 서류 촬영 시작/재촬영 카드와 자동 입력 결과 안내.
class DocumentCaptureCard extends StatelessWidget {
  const DocumentCaptureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.captured,
    required this.busy,
    required this.onCapture,
    this.hint,
  });

  final String title;
  final IconData icon;
  final bool captured;
  final bool busy;
  final VoidCallback onCapture;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: captured ? AppColors.successText : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: captured ? AppColors.successSoft : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(icon, color: captured ? AppColors.success : Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  captured ? '촬영 완료 · 아래 내용을 확인해 주세요' : (hint ?? '사진을 촬영해 주세요'),
                  style: TextStyle(
                    fontSize: 12,
                    color: captured ? AppColors.successText : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: busy ? null : onCapture,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.photo_camera_outlined, size: 16),
            label: Text(captured ? '다시 촬영' : '촬영',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// 자동 입력 결과 안내 배너.
class ScanResultBanner extends StatelessWidget {
  const ScanResultBanner({super.key, required this.recognized});

  final bool recognized;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recognized ? AppColors.primarySoft : AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        recognized
            ? '자동으로 입력했어요. 틀린 곳이 있으면 직접 고쳐 주세요.'
            : '자동 인식에 실패했어요. 직접 입력해 주세요.',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: recognized ? AppColors.primaryDark : AppColors.warningText,
        ),
      ),
    );
  }
}
