import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/section_card.dart';
import '../orders/order.dart';
import '../orders/orders_providers.dart';

/// 오더 상세. 상단 뒤로 가기 버튼으로 로비로 Pop 복귀한다.
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.orderId});

  final String orderId;

  // 딥링크로 바로 들어와 쌓인 화면이 없으면 차주 홈으로 이동한다.
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.driverHome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _back(context),
        ),
        title: const Text('오더 상세',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: AsyncValueView(
        value: order,
        onRetry: () => ref.invalidate(orderProvider(orderId)),
        builder: (order) => order == null
            ? const Center(child: Text('오더를 찾을 수 없어요.'))
            : _OrderDetail(order: order),
      ),
      bottomNavigationBar: order.value == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: order.value!.isCompost
                        ? AppColors.warning
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _back(context), // 수락 후 로비 복귀
                  child: Text(
                    order.value!.isCompost ? '이력 기록 동의하고 수락하기' : '이 오더 수락하기',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }
}

class _OrderDetail extends StatelessWidget {
  const _OrderDetail({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 퇴비 오더면 이력 경고
        if (order.isCompost)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              border: Border.all(color: AppColors.warningBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '⚠️ 수락 시 내 차량에 퇴비 이력이 기록됩니다.\n'
              '세척 인증 전까지 식용 곡물 오더가 제한돼요.',
              style: TextStyle(color: AppColors.warningText, fontSize: 13),
            ),
          ),

        // 경로 카드
        SectionCard(
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
                '${order.cargoInfo}  |  ${order.vehicleInfo}  |  ${order.distanceLabel}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 운임 카드
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('내가 받는 금액',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text('${formatWon(order.price)}원',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('⚡ 운송 완료 다음 날 지급 · 수수료 정찰 5% 반영',
                  style: TextStyle(color: AppColors.successText, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
