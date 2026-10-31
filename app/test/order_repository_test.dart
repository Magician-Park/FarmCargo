import 'package:farm_cargo/features/orders/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repository = MockOrderRepository();

  test('추천 오더에는 곡물과 퇴비 오더가 있고 id가 유일하다', () async {
    final orders = await repository.fetchRecommendedOrders();
    expect(orders.map((o) => o.id).toSet().length, orders.length);
    expect(orders.where((o) => o.isCompost).length, 1);
    expect(orders.first.distanceLabel, '215km');
  });

  test('fetchOrder는 id로 찾고 없으면 null', () async {
    expect((await repository.fetchOrder('order-2'))?.isCompost, isTrue);
    expect(await repository.fetchOrder('nope'), isNull);
  });
}
