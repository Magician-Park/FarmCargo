import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/demo_notice.dart';
import '../orders/order.dart';
import '../orders/order_policy.dart';
import '../orders/orders_providers.dart';
import '../orders/trip.dart';

/// 화주의 조건 변경 알림과 수락/거절(D04). 답하지 않은 변경이 없으면 아무것도 그리지 않는다.
class ConditionChangeCard extends ConsumerWidget {
  const ConditionChangeCard({super.key, required this.orderId});

  final String orderId;

  Future<void> _reject(BuildContext context, WidgetRef ref,
      ConditionChange change) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('조건 변경을 거절할까요?'),
        content: Text(change.refusableWithoutPenalty
            ? '화주가 상/하차지나 차종을 바꾼 경우라 패널티 없이 거절할 수 있어요. 거절하면 배차가 풀려요.'
            : '이 변경은 거절하면 경고 1회로 기록되고 일정 기간 오더를 수락할 수 없어요'
                '(1회 24시간, 2회 7영업일, 3회 30영업일). 거절하면 배차도 풀려요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('돌아가기')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('거절하기')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await respondToChange(ref, orderId, false);
      messenger.showSnackBar(SnackBar(
          content: Text(change.refusableWithoutPenalty
              ? '조건 변경을 거절했어요. 배차가 풀렸어요.'
              : '조건 변경을 거절했어요. 경고 1회로 기록됐어요.')));
      router.go(AppRoutes.driverMyOrders);
    } on TripActionException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final change = ref.watch(pendingChangeProvider(orderId)).value;
    if (change == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.warningText),
              SizedBox(width: 6),
              Text('화주가 조건을 바꿨어요',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warningText)),
            ],
          ),
          const SizedBox(height: 10),
          for (final c in change.changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  Text(c.before,
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted)),
                  Text('→ ${c.after}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          if (change.message != null) ...[
            const SizedBox(height: 4),
            Text('화주 메시지: ${change.message}',
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textChip)),
          ],
          const SizedBox(height: 8),
          Text(
            change.refusableWithoutPenalty
                ? '상/하차지·차종이 바뀐 경우라 거절해도 패널티가 없어요.'
                : '이 변경을 거절하면 경고 1회로 기록돼요.',
            style: const TextStyle(fontSize: 12, color: AppColors.warningText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context, ref, change),
                  child: const Text('거절'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => respondToChange(ref, orderId, true),
                  child: const Text('바뀐 조건으로 운행'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 배차 취소(D04). 상차 전에만 보인다.
class CancelSection extends ConsumerWidget {
  const CancelSection({super.key, required this.order, required this.trip});

  final Order order;
  final TripProgress trip;

  Future<void> _cancel(BuildContext context, WidgetRef ref, DateTime deadline,
      int cancelledToday) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelDialog(
          deadline: deadline, cancelledToday: cancelledToday),
    );
    if (reason == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await cancelOrder(ref, order.id, reason);
      messenger.showSnackBar(const SnackBar(
          content: Text('배차를 취소했어요. 화주에게 알리고 오더는 다시 오더 찾기에 올라가요.')));
      router.go(AppRoutes.driverMyOrders);
    } on TripActionException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final deadline = cancelDeadline(order, trip.acceptedAt);
    final open = now.isBefore(deadline);
    final cancelledToday = ref.watch(cancellationsTodayProvider).value ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Text(
          open
              ? '취소 마감: ${formatDeadline(deadline)}까지'
              : '취소 마감(${formatDeadline(deadline)})이 지나 취소할 수 없어요. 꼭 필요하면 고객센터로 문의해 주세요.',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: open
              ? () => _cancel(context, ref, deadline, cancelledToday)
              : null,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('배차 취소'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.deadline, required this.cancelledToday});

  final DateTime deadline;
  final int cancelledToday;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final excessive = widget.cancelledToday + 1 >= excessiveCancelFrom;
    return AlertDialog(
      title: const Text('배차를 취소할까요?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${formatDeadline(widget.deadline)}까지 취소할 수 있어요. '
                '취소하면 화주에게 알리고 오더는 다시 오더 찾기에 올라가요.'),
            const SizedBox(height: 8),
            const Text('사유가 분명하지 않은 취소는 경고를 받을 수 있어요.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            if (excessive) ...[
              const SizedBox(height: 8),
              Text(
                '오늘 ${widget.cancelledToday + 1}번째 취소예요. 하루 3건째부터는 과도한 취소로 경고를 받을 수 있어요.',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warningText),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '취소 사유(필수)',
                hintText: '예: 차량 고장으로 상차가 어려워요',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('돌아가기')),
        TextButton(
          onPressed: _reason.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _reason.text.trim()),
          child: const Text('취소하기'),
        ),
      ],
    );
  }
}

/// 시연용: 화주 앱이 없어 화주의 조건 변경을 대신 만드는 버튼.
class ConditionChangeDemo extends ConsumerWidget {
  const ConditionChangeDemo({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isDemoRepositoryProvider)) return const SizedBox.shrink();
    if (ref.watch(pendingChangeProvider(orderId)).value != null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const DemoNotice(),
        const SizedBox(height: 6),
        const Text('시연용: 화주 앱이 아직 없어 화주의 조건 변경을 대신 일으킬 수 있어요.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => simulateConditionChange(ref, orderId, true),
                child: const Text('화주: 하차지 변경'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => simulateConditionChange(ref, orderId, false),
                child: const Text('화주: 물량 변경'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
