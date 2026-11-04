import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order.dart';
import 'order_repository.dart';

final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => const MockOrderRepository());

/// 차주 홈의 추천 맞춤 오더.
final recommendedOrdersProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchRecommendedOrders());

/// 일감 목록 탭의 게시글 목록.
final jobPostsProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchJobPosts());

final orderProvider = FutureProvider.family<Order?, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).fetchOrder(id));
