import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_value_view.dart';
import '../orders/driver_alert.dart';
import '../orders/order_policy.dart';
import '../orders/orders_providers.dart';

/// 알림 목록(D02). 조건 변경·증빙 확인 결과·경고·배차 해제를 모아 본다.
/// 같은 알림은 앱 푸시·카카오 알림톡으로도 보낸다(서버 연결 뒤).
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  /// 화면을 열 때 안 읽었던 알림. 열자마자 모두 읽음으로 바꾸되, 이번에 볼 때는 강조해 둔다.
  Set<String>? _unreadOnOpen;

  @override
  void initState() {
    super.initState();
    ref.read(alertsProvider.future).then((list) {
      if (!mounted) return;
      setState(() => _unreadOnOpen = {
            for (final a in list)
              if (!a.read) a.id,
          });
      markAlertsRead(ref);
    });
  }

  Future<void> _open(DriverAlert alert) async {
    final id = alert.orderId;
    if (alert.type == DriverAlertType.warning) {
      context.go(AppRoutes.driverSanctions);
      return;
    }
    if (id == null) return;
    final trip = await ref.read(tripProvider(id).future);
    if (!mounted) return;
    context.push(
        trip != null ? AppRoutes.driverTrip(id) : AppRoutes.driverOrder(id));
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
        ],
      ),
      body: AsyncValueView(
        value: alerts,
        onRetry: () => ref.invalidate(alertsProvider),
        builder: (list) => list.isEmpty
            ? const Center(
                child: Text('아직 받은 알림이 없어요.',
                    style: TextStyle(color: AppColors.textMuted)))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.surfaceMuted),
                itemBuilder: (context, index) => _AlertTile(
                  alert: list[index],
                  highlight: _unreadOnOpen?.contains(list[index].id) ??
                      !list[index].read,
                  onTap: () => _open(list[index]),
                ),
              ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile(
      {required this.alert, required this.highlight, required this.onTap});

  final DriverAlert alert;
  final bool highlight; // 이번에 새로 온(안 읽었던) 알림
  final VoidCallback onTap;

  IconData get _icon => switch (alert.type) {
        DriverAlertType.conditionChanged => Icons.edit_note,
        DriverAlertType.proofConfirmed => Icons.verified_outlined,
        DriverAlertType.proofRejected => Icons.report_gmailerrorred_outlined,
        DriverAlertType.warning => Icons.warning_amber_rounded,
        DriverAlertType.released => Icons.link_off,
      };

  bool get _warn =>
      alert.type == DriverAlertType.warning ||
      alert.type == DriverAlertType.proofRejected ||
      alert.type == DriverAlertType.released;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? AppColors.primarySoft : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon,
                  color: _warn ? AppColors.warning : AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(alert.title,
                              style: TextStyle(
                                  fontWeight: highlight
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                        if (highlight)
                          Semantics(
                            label: '새 알림',
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(alert.body,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textChip,
                            height: 1.4)),
                    const SizedBox(height: 4),
                    Text(formatDeadline(alert.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 홈 등에 두는 종 아이콘. 안 읽은 알림 수를 빨간 점 숫자로 보여 준다.
class AlertBell extends ConsumerWidget {
  const AlertBell({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadAlertCountProvider);
    return IconButton(
      tooltip: unread == 0 ? '알림' : '알림, 안 읽은 알림 $unread개',
      onPressed: () => context.push(AppRoutes.driverAlerts),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: Icon(Icons.notifications_none, color: color),
      ),
    );
  }
}
