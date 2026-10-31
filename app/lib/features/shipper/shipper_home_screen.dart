import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../auth/auth_provider.dart';

/// 농가·화주 홈. 운송 요청 진입과 진행 중인 오더를 보여준다.
class ShipperHomeScreen extends ConsumerWidget {
  const ShipperHomeScreen({super.key});

  void _openRequest(BuildContext context) =>
      context.push(AppRoutes.grainRequest);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로그아웃 직후 라우터가 이동시키기 전까지 계정이 null일 수 있다.
    final name = ref.watch(authProvider)?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('화주 홈'),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('로그아웃'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('$name님, 안녕하세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('전북 김제시 죽산면 · 농업경영체 인증 완료',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 22),
          Material(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () => _openRequest(context),
              borderRadius: BorderRadius.circular(22),
              child: const Padding(
                padding: EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('운송 요청하기',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('곡물·퇴비·비료를 조건에 맞는 차량으로',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.local_shipping_outlined,
                          color: Colors.white, size: 27),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text('진행 중인 운송',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusChip('배차 대기', Color(0xFFFFF7ED), Color(0xFFC2410C)),
                    Spacer(),
                    Text('비료 · 파렛트 8개',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 13),
                Text('전주 ○○비료 → 우리 농장',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('내일 오전 상차 · 5톤 윙바디 추천',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: foreground, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
