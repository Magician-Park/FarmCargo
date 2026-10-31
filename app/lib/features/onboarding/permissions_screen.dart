import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bottom_action_bar.dart';

/// 최초 실행 시 앱이 사용하는 접근 권한을 안내한다.
/// 현재는 안내만 하며, 실제 권한 요청은 해당 기능을 처음 쓸 때 연결한다.
class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  static const _items = [
    (Icons.photo_camera_outlined, '카메라', '자격증, 사업자등록증, 신분증 촬영'),
    (Icons.photo_library_outlined, '사진', '촬영한 서류 사진 첨부'),
    (Icons.location_on_outlined, '위치', '내 주변 오더 찾기, 운행 경로 안내'),
    (Icons.notifications_none, '알림', '배차, 운송 상태, 정산 소식 알림'),
    (Icons.call_outlined, '전화', '화주·차주 간 연락'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('팜카고 이용을 위해\n접근 권한을 허용해 주세요',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.35)),
                    const SizedBox(height: 32),
                    const Text('선택 접근 권한',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(height: 24, thickness: 1.5),
                    for (final (icon, name, reason) in _items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(reason,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      '선택 권한은 허용하지 않아도 앱을 이용할 수 있지만, 해당 기능은 사용할 수 없어요. '
                      '권한은 기능을 처음 사용할 때 다시 안내해 드려요.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            BottomActionBar(
              label: '확인',
              onPressed: () => context.go(AppRoutes.welcome),
            ),
          ],
        ),
      ),
    );
  }
}
