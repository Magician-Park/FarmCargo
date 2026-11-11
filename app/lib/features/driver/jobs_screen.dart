import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/location/location_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_value_view.dart';
import '../orders/orders_providers.dart';
import 'order_card.dart';
import 'order_search.dart';

/// ‘오더 찾기’ 탭(2026-11-05 이름 결정). 화주가 올린 오더가 게시글 형식으로 쭉 나열되고,
/// 내 위치 기준 거리 필터와 정렬을 고를 수 있다(2026-11-12).
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  DistanceFilter _filter = DistanceFilter.all;
  OrderSort _sort = OrderSort.fastLoading;

  void _refresh() {
    ref.invalidate(jobPostsProvider);
    ref.invalidate(currentLocationProvider);
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(jobPostsProvider);
    final location = ref.watch(currentLocationProvider).value;
    final today = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(
        title: const Text('오더 찾기',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<DistanceFilter>(
                    segments: [
                      for (final f in DistanceFilter.values)
                        ButtonSegment(value: f, label: Text(f.label)),
                    ],
                    selected: {_filter},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primary,
                      selectedForegroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PopupMenuButton<OrderSort>(
                        tooltip: '정렬 기준',
                        initialValue: _sort,
                        onSelected: (s) => setState(() => _sort = s),
                        itemBuilder: (context) => [
                          for (final s in OrderSort.values)
                            CheckedPopupMenuItem(
                                value: s,
                                checked: s == _sort,
                                child: Text(s.label)),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_vert,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(_sort.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textStrong)),
                              const Icon(Icons.expand_more, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.place_outlined,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          location == null
                              ? '내 위치 확인 불가'
                              : location.isDemo
                                  ? '${location.label} (데모)'
                                  : location.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncValueView(
                value: posts,
                onRetry: _refresh,
                builder: (orders) {
                  final items = arrangeOrders(orders,
                      filter: _filter, sort: _sort, myLocation: location?.point);
                  if (location == null && _filter != DistanceFilter.all) {
                    return const _Empty('내 위치를 알 수 없어 거리 필터를 쓸 수 없어요.');
                  }
                  if (items.isEmpty) {
                    return _Empty(_filter == DistanceFilter.all
                        ? '지금 올라온 오더가 없어요.'
                        : '${_filter.label}에 올라온 오더가 없어요.');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Text('올라온 오더 ${items.length}건',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted));
                      }
                      final item = items[index - 1];
                      return OrderCard(
                        order: item.order,
                        today: today,
                        distanceFromMeKm: item.distanceFromMeKm,
                        onTap: () =>
                            context.push(AppRoutes.driverOrder(item.order.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
}
