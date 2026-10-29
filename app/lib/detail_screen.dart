import 'package:flutter/material.dart';

import 'order.dart';

/// 오더 상세. 상단 뒤로 가기 버튼으로 로비로 Pop 복귀한다.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 3. 뒤로 가기 → 이전 화면(로비)으로 Pop
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('오더 상세',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 퇴비 오더면 이력 경고
          if (order.isCompost)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFCD34D)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '⚠️ 수락 시 내 차량에 퇴비 이력이 기록됩니다.\n'
                '세척 인증 전까지 식용 곡물 오더가 제한돼요.',
                style: TextStyle(color: Color(0xFF92400E), fontSize: 13),
              ),
            ),

          // 경로 카드
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.origin,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.south, size: 16, color: Colors.grey),
                ),
                Text(order.destination,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  '${order.cargoInfo}  |  ${order.vehicleInfo}  |  ${order.distance}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 운임 카드
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('내가 받는 금액',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${_won(order.price)}원',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('⚡ 운송 완료 다음 날 지급 · 수수료 정찰 5% 반영',
                    style: TextStyle(color: Color(0xFF16A34A), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: order.isCompost
                  ? const Color(0xFFB45309)
                  : const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context), // 수락 후 로비 복귀
            child: Text(
              order.isCompost ? '이력 기록 동의하고 수락하기' : '이 오더 수락하기',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: child,
    );
  }
}

String _won(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
