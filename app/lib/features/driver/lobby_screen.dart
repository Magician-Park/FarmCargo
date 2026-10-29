import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/info_chip.dart';
import '../auth/auth_provider.dart';
import '../orders/order.dart';
import '../orders/orders_providers.dart';

/// 차주 홈 로비. 오더 카드를 탭하면 상세 화면으로 Push 이동한다.
class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(recommendedOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('차주 홈'),
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
            // 인사 + 차량 상태
            const Text('김기사님,',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('11톤 윙바디 • 서울 88가 1234',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                InfoChip('퇴비 이력 없음 · 식용 곡물 가능',
                    bg: AppColors.successSoft, fg: AppColors.success),
                InfoChip('11톤 · 일반 카고 · 크레인'),
                InfoChip('LMO 승인',
                    bg: AppColors.primarySoft, fg: AppColors.primary),
              ],
            ),
            const SizedBox(height: 20),

            // 오늘의 예상 수입 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight]),
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
            AsyncValueView(
              value: orders,
              onRetry: () => ref.invalidate(recommendedOrdersProvider),
              builder: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('지금 맞는 오더가 없어요.')),
                    )
                  : Column(
                      children: [
                        for (final order in list) ...[
                          _OrderCard(
                            order: order,
                            onTap: () =>
                                context.push(AppRoutes.driverOrder(order.id)),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
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
                  InfoChip(order.category,
                      bg: order.isCompost
                          ? AppColors.warningSoft
                          : AppColors.primarySoft,
                      fg: order.isCompost
                          ? AppColors.warningText
                          : AppColors.primary),
                  const Spacer(),
                  Text('${formatWon(order.price)}원',
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
                '${order.cargoInfo}  |  ${order.vehicleInfo}  |  ${order.distanceLabel}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
