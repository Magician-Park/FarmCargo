import 'package:farm_cargo/core/location/location_service.dart';
import 'package:farm_cargo/features/driver/order_search.dart';
import 'package:farm_cargo/features/orders/order.dart';
import 'package:farm_cargo/features/orders/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 12, 9); // 목요일
const _cheonan = GeoPoint(36.8151, 127.1139); // 데모 위치

Order _order(String id, {int loadingOffset = 0}) {
  final day = DateTime(2026, 11, 12).add(Duration(days: loadingOffset));
  return Order(
    id: id,
    item: '소맥피',
    originCountry: OriginCountry.imported,
    shipperName: '가상 화주',
    origin: '가상 상차지',
    destination: '가상 하차지',
    originRegion: '가상',
    destinationRegion: '가상',
    originPoint: _cheonan,
    quantity: '24톤',
    weightKg: 24000,
    vehicleTypes: const ['덤프'],
    loading: Schedule(date: day, startTime: '08:00', endTime: '10:00'),
    unloading: Schedule(date: day, startTime: '13:00', endTime: '15:00'),
    priceUnit: PriceUnit.perTruck,
    unitPrice: 300000,
    distanceKm: 100,
    registeredAt: _now,
  );
}

void main() {
  group('샘플 오더', () {
    final repository = MockOrderRepository(now: () => _now);

    test('추천 맞춤 오더는 오더 찾기 목록의 일부이고 퇴비 오더를 포함한다', () async {
      final recommended = await repository.fetchRecommendedOrders();
      final posts = await repository.fetchJobPosts();
      expect(recommended.length, 2);
      expect(recommended.where((o) => o.isCompost).length, 1);
      expect(posts.map((o) => o.id), containsAll(recommended.map((o) => o.id)));
      expect(posts.map((o) => o.id).toSet().length, posts.length);
    });

    test('모든 오더에 필수 항목이 있고, kg당 단가는 소수점 첫째 자리까지다', () async {
      for (final o in await repository.fetchJobPosts()) {
        expect(o.shipperName, isNotEmpty);
        expect(o.vehicleTypes, isNotEmpty);
        expect(o.loading.startTime.compareTo(o.loading.endTime), lessThan(0));
        expect(o.unloading.date.isBefore(o.loading.date), isFalse);
        if (o.priceUnit == PriceUnit.perKg) {
          expect((o.unitPrice * 10).round() / 10, o.unitPrice);
        }
      }
      final wheat = (await repository.fetchOrder('order-3'))!;
      expect(wheat.itemLabel, '소맥피 · 외국산');
      expect(wheat.priceLabel, 'kg당 12.5원');
      expect(wheat.estimatedFare, 300000); // 12.5원 × 24,000kg
      expect((await repository.fetchOrder('order-4'))!.priceLabel, '건당 350,000원');
      expect(await repository.fetchOrder('nope'), isNull);
    });

    test('배지: 오늘 상차는 당상, 내일 상차는 익상 / 오늘 하차는 당착, 내일 하차는 내착', () async {
      final wheat = (await repository.fetchOrder('order-3'))!; // 오늘 상차·오늘 하차
      final corn = (await repository.fetchOrder('order-5'))!; // 오늘 상차·내일 하차
      final soy = (await repository.fetchOrder('order-1'))!; // 내일 상차
      final palm = (await repository.fetchOrder('order-6'))!; // 3일 뒤 상차
      expect(wheat.loadingBadge(_now), '당상');
      expect(wheat.unloadingBadge(_now), '당착');
      expect(corn.unloadingBadge(_now), '내착');
      expect(soy.loadingBadge(_now), '익상');
      expect(soy.unloadingBadge(_now), '내착'); // 내일 싣고 내일 내림
      expect(palm.unloadingBadge(_now), isNull); // 3일 뒤 하차
      expect(palm.loadingBadge(_now), isNull);
    });
  });

  group('수락(D02·D03)', () {
    test('수락하면 내 오더로 옮겨지고 오더 찾기에서 빠지며, 같은 오더는 다시 수락할 수 없다', () async {
      final repository = MockOrderRepository(now: () => _now);
      await repository.acceptOrder('order-3');
      expect((await repository.fetchMyOrders()).map((o) => o.id), ['order-3']);
      expect((await repository.fetchJobPosts()).map((o) => o.id),
          isNot(contains('order-3')));
      expect(() => repository.acceptOrder('order-3'),
          throwsA(isA<OrderAcceptException>()));
      expect(() => repository.acceptOrder('nope'),
          throwsA(isA<OrderAcceptException>()));
    });

    test('같은 상차일에는 하루 3건까지만 수락할 수 있다', () async {
      final repository = MockOrderRepository(orders: [
        for (var i = 1; i <= 4; i++) _order('a$i'),
        _order('b1', loadingOffset: 1),
      ]);
      for (var i = 1; i <= 3; i++) {
        await repository.acceptOrder('a$i');
      }
      await expectLater(
          repository.acceptOrder('a4'),
          throwsA(isA<OrderAcceptException>().having(
              (e) => e.message, 'message', contains('하루 최대 3건'))));
      await repository.acceptOrder('b1'); // 다른 상차일은 따로 센다
      expect((await repository.fetchMyOrders()).length, 4);
    });
  });

  group('오더 찾기 거리 필터·정렬', () {
    late List<Order> orders;
    setUp(() async {
      orders = await MockOrderRepository(now: () => _now).fetchJobPosts();
    });

    List<String> ids(List<OrderListItem> items) =>
        [for (final i in items) i.order.id];

    test('거리 필터는 내 위치에서 상차지까지 직선거리로 거른다', () {
      List<OrderListItem> run(DistanceFilter f) => arrangeOrders(orders,
          filter: f, sort: OrderSort.nearest, myLocation: _cheonan);
      expect(run(DistanceFilter.all).length, 6);
      expect(ids(run(DistanceFilter.within30)), ['order-4', 'order-5']);
      expect(run(DistanceFilter.within50).length, 4);
      for (final item in run(DistanceFilter.within50)) {
        expect(item.distanceFromMeKm, lessThanOrEqualTo(50));
      }
    });

    test('위치를 모르면 거리 필터는 적용하지 않고 가까운 거리순은 빠른 상차순이 된다', () {
      final items = arrangeOrders(orders,
          filter: DistanceFilter.within30, sort: OrderSort.nearest);
      expect(items.length, 6);
      expect(items.first.distanceFromMeKm, isNull);
      expect(ids(items).take(2), ['order-3', 'order-5']);
    });

    test('정렬: 빠른 상차순·오더 등록순·높은 운송비순(kg당은 예상 운송비)', () {
      List<String> sorted(OrderSort s) => ids(arrangeOrders(orders,
          filter: DistanceFilter.all, sort: s, myLocation: _cheonan));
      expect(sorted(OrderSort.fastLoading).take(3),
          ['order-3', 'order-5', 'order-1']);
      expect(sorted(OrderSort.latest).first, 'order-3'); // 가장 최근에 올림
      expect(sorted(OrderSort.highestFare).take(3),
          ['order-5', 'order-4', 'order-3']); // 43만, 35만, 30만(kg당 예상)
    });
  });
}
