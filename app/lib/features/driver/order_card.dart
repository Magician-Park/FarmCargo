import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/info_chip.dart';
import '../orders/order.dart';

/// 오더 한 건을 보여주는 카드. 홈의 추천 오더와 ‘오더 찾기’ 탭이 함께 쓴다.
/// 화주 이름과 상·하차지 상세 주소는 목록에서부터 보여 준다(D06, 2026-11-11).
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  static const _muted = TextStyle(color: AppColors.textMuted, fontSize: 12);

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoChip(order.itemLabel,
                      bg: order.isCompost
                          ? AppColors.warningSoft
                          : AppColors.primarySoft,
                      fg: order.isCompost
                          ? AppColors.warningText
                          : AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(order.priceLabel,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const Text('부가세 별도', style: _muted),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('화주 ${order.shipperName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textChip)),
              const SizedBox(height: 6),
              Text(order.origin,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('→ ${order.destination}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('상차 ${order.loading.label}', style: _muted),
              Text('하차 ${order.unloading.label}', style: _muted),
              const SizedBox(height: 2),
              Text(
                '${order.quantity}  |  ${order.vehicleLabel}  |  ${order.distanceLabel}',
                style: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
