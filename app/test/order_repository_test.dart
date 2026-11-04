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

  test('fetchOrder는 id로 찾고 없으면 null', () async {
    expect((await repository.fetchOrder('order-2'))?.isCompost, isTrue);
    expect((await repository.fetchOrder('order-6'))?.category, '사료 원료(주정박)');
    expect(await repository.fetchOrder('nope'), isNull);
  });
}
