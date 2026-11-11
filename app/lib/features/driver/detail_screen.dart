import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/section_card.dart';
import '../orders/order.dart';
import '../orders/order_repository.dart';
import '../orders/orders_providers.dart';

/// 오더 상세. 상단 뒤로 가기 버튼으로 로비로 Pop 복귀한다.
class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _accepting = false;

  String get orderId => widget.orderId;

  /// 수락하면 바로 확정된다(D02). 결과는 저장소(서버)가 판단한다.
  Future<void> _accept() async {
    setState(() => _accepting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await acceptOrder(ref, orderId);
      if (!mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('오더를 수락했어요. 내 오더에서 확인할 수 있어요.')));
      context.go(AppRoutes.driverMyOrders);
    } on OrderAcceptException catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // 딥링크로 바로 들어와 쌓인 화면이 없으면 차주 홈으로 이동한다.
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.driverHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(orderId));
    final mine = ref.watch(myOrdersProvider).value ?? const [];
    final accepted = mine.any((o) => o.id == orderId);

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
                  onPressed: accepted || _accepting ? null : _accept,
                  child: Text(
                    accepted
                        ? '내가 수락한 오더예요'
                        : order.value!.isCompost
                            ? '이력 기록 동의하고 수락하기'
                            : '이 오더 수락하기',
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

        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.itemLabel,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('화주 ${order.shipperName}',
                  style: const TextStyle(color: AppColors.textChip)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 경로: 상·하차지 상세 주소와 일정
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Labeled('상차', order.origin, order.loading.label),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Icon(Icons.south, size: 16, color: Colors.grey),
              ),
              _Labeled('하차', order.destination, order.unloading.label),
              const SizedBox(height: 10),
              Text('거리 ${order.distanceLabel}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 화물과 차종
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Row('물량', order.quantity),
              const SizedBox(height: 8),
              _Row('운반 가능 차종', order.vehicleLabel),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 운송비
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('운송비 단가',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(order.priceLabel,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('부가세 별도',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              const Text(
                  '운송비에서 수수료 4%를 떼고, 화주 정산일 10일 뒤(은행 영업일)에 지급돼요.',
                  style: TextStyle(color: AppColors.successText, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.address, this.schedule);

  final String label;
  final String address;
  final String schedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  $schedule',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 2),
        Text(address, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }
}
