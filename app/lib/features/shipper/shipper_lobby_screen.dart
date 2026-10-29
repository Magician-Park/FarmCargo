import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_value_view.dart';
import '../auth/auth_provider.dart';
import '../orders/shipment.dart';
import '../orders/orders_providers.dart';

/// 화주 로그인 후 표시하는 목업 기반 홈. 운송 현황은 샘플 데이터다.
class ShipperLobbyScreen extends ConsumerWidget {
  const ShipperLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipments = ref.watch(shipperShipmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('화주 홈'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
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
            const Text('전북 김제시 죽산면 ○○농장', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.agriculture_rounded,
                      color: Colors.white, size: 36),
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
            AsyncValueView(
              value: shipments,
              onRetry: () => ref.invalidate(shipperShipmentsProvider),
              builder: (list) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('지금 운송 중이에요',
                      list.where((s) => s.status == ShipmentStatus.inTransit)),
                  _section(
                      '예정된 운송',
                      list.where(
                          (s) => s.status == ShipmentStatus.waitingDispatch)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('운송 요청·연락·정산 기능은 추후 연결 예정이에요.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Iterable<Shipment> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        for (final shipment in items) _TransportCard(shipment: shipment),
      ],
    );
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final order = shipment.order;
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
                Chip(label: Text(shipment.status.label)),
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
            Text(shipment.description, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
