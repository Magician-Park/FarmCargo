import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order.dart';
import 'order_repository.dart';

final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => const MockOrderRepository());

final recommendedOrdersProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchRecommendedOrders());

final orderProvider = FutureProvider.family<Order?, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).fetchOrder(id));
