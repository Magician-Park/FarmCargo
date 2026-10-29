import 'package:flutter/material.dart';

import 'order.dart';

/// 화주 로그인 후 표시하는 목업 기반 홈. 운송 현황은 샘플 데이터다.
class ShipperLobbyScreen extends StatelessWidget {
  const ShipperLobbyScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('화주 홈'),
        actions: [
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('로그아웃'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('박농부님,',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('전북 김제시 죽산면 ○○농장',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.agriculture_rounded, color: Colors.white, size: 36),
                  SizedBox(height: 12),
                  Text('우리 농장 운송을 한눈에',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('화주 홈 데모 · 아래 운송 현황은 예시입니다.',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('지금 운송 중이에요',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _TransportCard(
              order: sampleOrders[0],
              status: '운송 중',
              description: '김기사님 · 도착 예정 17:30',
            ),
            const SizedBox(height: 24),
            const Text('예정된 운송',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _TransportCard(
              order: sampleOrders[1],
              status: '배차 대기',
              description: '내일 07:00 상차',
            ),
            const SizedBox(height: 20),
            const Text('운송 요청·연락·정산 기능은 추후 연결 예정이에요.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({
    required this.order,
    required this.status,
    required this.description,
  });

  final Order order;
  final String status;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(order.category)),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 12),
            Text(order.origin,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('→ ${order.destination}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('${order.cargoInfo} · ${order.vehicleInfo}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
