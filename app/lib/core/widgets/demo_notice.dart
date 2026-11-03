import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 서버가 없는 데모/베타 화면에서 실제 개인정보를 넣지 않도록 안내한다.
/// 실제 서버와 연결되면 이 안내는 제거한다.
class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 18, color: AppColors.warningText),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '테스트 버전이에요. 입력한 내용은 서버에 저장되지 않으니 실제 개인정보·서류는 입력하지 마세요.',
              style: TextStyle(
                  fontSize: 12, height: 1.4, color: AppColors.warningText),
            ),
          ),
        ],
      ),
    );
  }
}
