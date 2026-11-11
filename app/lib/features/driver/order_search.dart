import '../../core/location/location_service.dart';
import '../orders/order.dart';

/// ‘오더 찾기’ 거리 필터(사용자 결정 2026-11-12). 내 위치에서 상차지까지 직선거리 기준.
enum DistanceFilter {
  all('전체', null),
  within50('50km 주변', 50),
  within30('30km 주변', 30);

  const DistanceFilter(this.label, this.maxKm);
  final String label;
  final int? maxKm;
}

/// ‘오더 찾기’ 정렬 기준(사용자 결정 2026-11-12).
enum OrderSort {
  fastLoading('빠른 상차순'),
  nearest('가까운 거리순'),
  latest('오더 등록순'),
  highestFare('높은 운송비순');

  const OrderSort(this.label);
  final String label;
}

/// 목록 한 줄: 오더와 내 위치에서 상차지까지 거리(위치를 모르면 null).
class OrderListItem {
  const OrderListItem(this.order, this.distanceFromMeKm);
  final Order order;
  final double? distanceFromMeKm;
}

DateTime _loadingStart(Order o) {
  final parts = o.loading.startTime.split(':');
  return o.loading.date
      .add(Duration(hours: int.parse(parts[0]), minutes: int.parse(parts[1])));
}

/// 거리 필터와 정렬을 적용한다. 위치가 없으면 거리 필터는 ‘전체’처럼,
/// 가까운 거리순은 빠른 상차순처럼 동작한다. 높은 운송비순은 kg당 오더를 예상 운송비로 비교한다.
List<OrderListItem> arrangeOrders(
  List<Order> orders, {
  required DistanceFilter filter,
  required OrderSort sort,
  GeoPoint? myLocation,
}) {
  final items = [
    for (final o in orders)
      OrderListItem(o, myLocation?.distanceKmTo(o.originPoint)),
  ];
  final maxKm = filter.maxKm;
  final filtered = maxKm == null || myLocation == null
      ? items
      : items.where((i) => i.distanceFromMeKm! <= maxKm).toList();

  int byLoading(OrderListItem a, OrderListItem b) =>
      _loadingStart(a.order).compareTo(_loadingStart(b.order));

  final compare = switch (sort) {
    OrderSort.fastLoading => byLoading,
    OrderSort.nearest => myLocation == null
        ? byLoading
        : (OrderListItem a, OrderListItem b) =>
            a.distanceFromMeKm!.compareTo(b.distanceFromMeKm!),
    OrderSort.latest => (OrderListItem a, OrderListItem b) =>
        b.order.registeredAt.compareTo(a.order.registeredAt),
    OrderSort.highestFare => (OrderListItem a, OrderListItem b) =>
        b.order.estimatedFare.compareTo(a.order.estimatedFare),
  };
  // Dart의 sort는 같은 값의 순서를 보장하지 않으므로 오더 id로 순서를 고정한다.
  return filtered
    ..sort((a, b) {
      final c = compare(a, b);
      return c != 0 ? c : a.order.id.compareTo(b.order.id);
    });
}
