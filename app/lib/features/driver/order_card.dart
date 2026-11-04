import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/info_chip.dart';
import '../orders/order.dart';

/// 오더 한 건을 보여주는 카드. 홈의 추천 오더와 일감 목록 탭이 함께 쓴다.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InfoChip(order.category,
                      bg: order.isCompost
                          ? AppColors.warningSoft
                          : AppColors.primarySoft,
                      fg: order.isCompost
                          ? AppColors.warningText
                          : AppColors.primary),
                  const Spacer(),
                  Text('${formatWon(order.price)}원',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(order.origin,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('→ ${order.destination}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                '${order.cargoInfo}  |  ${order.vehicleInfo}  |  ${order.distanceLabel}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
