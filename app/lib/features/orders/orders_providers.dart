import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../auth/auth_provider.dart';
import 'order.dart';
import 'order_repository.dart';

/// 로그인한 계정이 바뀌면 새로 만든다. 이전 차주의 수락 내역이 다음 사용자에게 보이지 않게 한다.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  ref.watch(authProvider.select((account) => account?.id));
  return MockOrderRepository(now: ref.watch(clockProvider));
});

/// 차주 홈의 추천 맞춤 오더.
final recommendedOrdersProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchRecommendedOrders());

/// ‘오더 찾기’ 탭의 게시글 목록.
final jobPostsProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchJobPosts());

final orderProvider = FutureProvider.family<Order?, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).fetchOrder(id));

/// ‘내 오더’: 내가 수락한 오더.
final myOrdersProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchMyOrders());

/// 오더를 수락하고 목록들을 새로 불러온다. 실패하면 [OrderAcceptException].
Future<void> acceptOrder(WidgetRef ref, String id) async {
  await ref.read(orderRepositoryProvider).acceptOrder(id);
  ref.invalidate(jobPostsProvider);
  ref.invalidate(recommendedOrdersProvider);
  ref.invalidate(myOrdersProvider);
}
