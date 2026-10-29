import 'package:flutter/material.dart';

import 'detail_screen.dart';
import 'order.dart';

/// 차주 홈 로비. 오더 카드를 탭하면 상세 화면으로 Push 이동한다.
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  // 2. 리스트의 오더 클릭 → 상세 화면으로 Push
  void _openDetail(BuildContext context, Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 인사 + 차량 상태
            const Text('김기사님,',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('11톤 윙바디 • 서울 88가 1234',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                _Chip('퇴비 이력 없음 · 식용 곡물 가능',
                    bg: Color(0xFFF0FDF4), fg: Color(0xFF15803D)),
                _Chip('11톤 · 일반 카고 · 크레인'),
                _Chip('LMO 승인', bg: Color(0xFFEFF6FF), fg: Color(0xFF2563EB)),
              ],
            ),
            const SizedBox(height: 20),

            // 오늘의 예상 수입 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘의 예상 수입',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 6),
                  Text('450,000원',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('완료 2건 · 운행 185km · 공차 12km',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('추천 맞춤 오더',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 오더 리스트
            for (final order in sampleOrders) ...[
              _OrderCard(order: order, onTap: () => _openDetail(context, order)),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Chip(order.category,
                      bg: order.isCompost
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFEFF6FF),
                      fg: order.isCompost
                          ? const Color(0xFF92400E)
                          : const Color(0xFF2563EB)),
                  const Spacer(),
                  Text('${_won(order.price)}원',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(order.origin,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('→ ${order.destination}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                '${order.cargoInfo}  |  ${order.vehicleInfo}  |  ${order.distance}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label,
      {this.bg = const Color(0xFFF3F4F6), this.fg = const Color(0xFF4B5563)});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

String _won(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
