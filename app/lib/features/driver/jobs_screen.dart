import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/widgets/async_value_view.dart';
import '../orders/orders_providers.dart';
import 'order_card.dart';

/// ‘오더 찾기’ 탭(2026-11-05 이름 결정). 화주가 올린 오더가 게시글 형식으로 쭉 나열된다.
class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(jobPostsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('오더 찾기')),
      body: SafeArea(
        child: AsyncValueView(
          value: posts,
          onRetry: () => ref.invalidate(jobPostsProvider),
          builder: (list) => list.isEmpty
              ? const Center(child: Text('지금 올라온 오더가 없어요.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text('올라온 오더 ${list.length}건',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey));
                    }
                    final order = list[index - 1];
                    return OrderCard(
                      order: order,
                      onTap: () =>
                          context.push(AppRoutes.driverOrder(order.id)),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
