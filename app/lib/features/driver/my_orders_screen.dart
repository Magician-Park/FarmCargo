import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/period_selector.dart';
import '../orders/orders_providers.dart';
import 'order_card.dart';

/// ‘내 오더’: 오더 내역(내가 수락한 오더) + 운행 기록(기간 조회) 두 탭(사용자 결정 2026-11-12).
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내 오더',
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: '새로고침',
              onPressed: () => ref.invalidate(myOrdersProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primaryDark,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            tabs: [Tab(text: '오더 내역'), Tab(text: '운행 기록')],
          ),
        ),
        body: const TabBarView(children: [_OrderHistory(), _TripRecords()]),
      ),
    );
  }
}

class _OrderHistory extends ConsumerWidget {
  const _OrderHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clockProvider)();
    final mine = ref.watch(myOrdersProvider);
    return AsyncValueView(
      value: mine,
      onRetry: () => ref.invalidate(myOrdersProvider),
      builder: (orders) {
        final todayCount =
            orders.where((o) => daysBetween(today, o.loading.date) == 0).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '오늘(${formatShortDate(today)}) 상차할 운송 건은 $todayCount건이에요',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text('아직 수락한 오더가 없어요.\n오더 찾기에서 원하는 오더를 골라 보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, height: 1.5)),
              )
            else
              for (final o in orders) ...[
                OrderCard(
                  order: o,
                  today: today,
                  onTap: () => context.push(AppRoutes.driverOrder(o.id)),
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

/// 운행 기록. 운송 증빙까지 마친 운행이 쌓이는 곳이다.
/// 운송 완료 처리(증빙)가 아직 없어 지금은 항상 비어 있다.
class _TripRecords extends ConsumerStatefulWidget {
  const _TripRecords();

  @override
  ConsumerState<_TripRecords> createState() => _TripRecordsState();
}

class _TripRecordsState extends ConsumerState<_TripRecords> {
  static final _options = [
    PeriodOption('오늘', (t) => DateRange(t, t)),
    PeriodOption('1개월',
        (t) => DateRange(DateTime(t.year, t.month - 1, t.day), t)),
    PeriodOption('3개월',
        (t) => DateRange(DateTime(t.year, t.month - 3, t.day), t)),
    PeriodOption.directInput,
  ];

  late final DateTime _today = dateOnly(ref.read(clockProvider)());
  late PeriodOption _option = _options.first;
  late DateRange _range = _options.first.range!(_today);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        PeriodSelector(
          options: _options,
          selected: _option,
          range: _range,
          today: _today,
          onChanged: (o, r) => setState(() {
            _option = o;
            _range = r;
          }),
        ),
        const SizedBox(height: 12),
        const Text('검색 결과 0건',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Text('이 기간에 표시할 운행 기록이 없어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
