import 'package:farm_cargo/features/orders/order.dart';
import 'package:farm_cargo/features/orders/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repository = MockOrderRepository();

  test('추천 맞춤 오더는 일감 목록의 일부이고 곡물과 퇴비 오더를 포함한다', () async {
    final recommended = await repository.fetchRecommendedOrders();
    final posts = await repository.fetchJobPosts();
    expect(recommended.length, 2);
    expect(recommended.where((o) => o.isCompost).length, 1);
    expect(recommended.first.distanceLabel, '215km');
    expect(posts.map((o) => o.id), containsAll(recommended.map((o) => o.id)));
  });

  test('일감 목록은 여러 건이고 id가 유일하다', () async {
    final posts = await repository.fetchJobPosts();
    expect(posts.length, greaterThanOrEqualTo(6));
    expect(posts.map((o) => o.id).toSet().length, posts.length);
  });

  test('모든 오더에 화주 이름·원산지·차종·상하차 일정이 있고, kg당 단가는 소수점 첫째 자리까지다', () async {
    for (final o in await repository.fetchJobPosts()) {
      expect(o.shipperName, isNotEmpty);
      expect(o.vehicleTypes, isNotEmpty);
      expect(o.loading.startTime.compareTo(o.loading.endTime), lessThan(0));
      expect(o.unloading.date.isBefore(o.loading.date), isFalse);
      if (o.priceUnit == PriceUnit.perKg) {
        expect((o.unitPrice * 10).round() / 10, o.unitPrice);
      }
    }
    final soybean = (await repository.fetchOrder('order-3'))!;
    expect(soybean.itemLabel, '소맥피 · 외국산');
    expect(soybean.priceLabel, 'kg당 12.5원');
    expect((await repository.fetchOrder('order-4'))!.priceLabel, '건당 350,000원');
  });

  test('fetchOrder는 id로 찾고 없으면 null', () async {
    expect((await repository.fetchOrder('order-2'))?.isCompost, isTrue);
    expect((await repository.fetchOrder('order-6'))?.item, '팜박');
    expect(await repository.fetchOrder('nope'), isNull);
  });
}
