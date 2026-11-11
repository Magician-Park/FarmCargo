import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_view.dart';
import '../auth/auth_provider.dart';
import '../orders/orders_providers.dart';
import 'order_card.dart';

/// 차주 홈. 인사·오늘 일정 요약과 추천 맞춤 오더를 보여 준다.
/// 추천 기준은 미정이라 샘플은 오더 찾기 목록의 앞쪽 오더다.
class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(recommendedOrdersProvider);
    final mine = ref.watch(myOrdersProvider).value ?? const [];
    final today = ref.watch(clockProvider)();
    final todayCount =
        mine.where((o) => daysBetween(today, o.loading.date) == 0).length;

    // 로그아웃 직후 라우터가 이동시키기 전까지 계정이 null일 수 있다.
    final account = ref.watch(authProvider);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 머리 영역
          Container(
            color: AppColors.primaryDeep,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.paddingOf(context).top + 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('차주 홈',
                    style: TextStyle(
                        color: AppColors.accentMint,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('${account?.name ?? ''}님,',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('오늘도 안전 운행하세요.',
                    style: TextStyle(color: Colors.white70)),
                if (account?.vehicleLabel != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(account!.vehicleLabel!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 18),
                // 오늘 일정 요약
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.go(AppRoutes.driverMyOrders),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available,
                              color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '오늘(${formatShortDate(today)}) 상차할 내 오더 $todayCount건',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.borderStrong),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('추천 맞춤 오더',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.driverJobs),
                      child: const Text('전체 보기'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                              OrderCard(
                                order: order,
                                today: today,
                                onTap: () => context
                                    .push(AppRoutes.driverOrder(order.id)),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
