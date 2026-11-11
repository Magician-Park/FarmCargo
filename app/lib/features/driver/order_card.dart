import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../orders/order.dart';

/// 오더 한 건을 보여주는 카드. 홈의 추천 오더와 ‘오더 찾기’ 탭이 함께 쓴다.
/// 화주 이름과 상·하차지 상세 주소는 목록에서부터 보여 준다(D06, 2026-11-11).
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.today,
    required this.onTap,
    this.distanceFromMeKm,
  });

  final Order order;
  final DateTime today;
  final VoidCallback onTap;

  /// 내 위치에서 상차지까지 직선거리. 위치를 모르면 null.
  final double? distanceFromMeKm;

  static const _small = TextStyle(color: AppColors.textMuted, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: order.isCompost
                    ? AppColors.warningBorder
                    : AppColors.primarySoft),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상·하차 시간과 배지
              Row(
                children: [
                  _TimeTag(
                    badge: order.loadingBadge(today),
                    fallback: formatShortDate(order.loading.date),
                    time: order.loading.startTime,
                    label: '상차',
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  _TimeTag(
                    badge: order.unloadingBadge(today),
                    fallback: formatShortDate(order.unloading.date),
                    time: order.unloading.startTime,
                    label: '하차',
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 지역 → 지역
              Row(
                children: [
                  Expanded(
                    child: Text(order.originRegion,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        const Icon(Icons.arrow_forward_rounded,
                            size: 20, color: AppColors.primaryLight),
                        Text(order.distanceLabel, style: _small),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(order.destinationRegion,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('화주 ${order.shipperName}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong)),
              const SizedBox(height: 2),
              Text('상차 ${order.origin}', style: _small),
              Text('하차 ${order.destination}', style: _small),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Chip(order.itemLabel, strong: true, warn: order.isCompost),
                  _Chip(order.quantity),
                  _Chip(order.vehicleLabel),
                ],
              ),
              const Divider(height: 22, color: AppColors.surfaceMuted),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      distanceFromMeKm == null
                          ? ''
                          : '내 위치에서 직선 약 ${distanceFromMeKm!.round()}km',
                      style: _small,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(order.priceLabel,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark)),
                      Text(
                        order.priceUnit == PriceUnit.perKg
                            ? '예상 ${formatWon(order.estimatedFare)}원 · 부가세 별도'
                            : '부가세 별도',
                        style: _small,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeTag extends StatelessWidget {
  const _TimeTag({
    required this.badge,
    required this.fallback,
    required this.time,
    required this.label,
    required this.color,
  });

  final String? badge;
  final String fallback;
  final String time;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: badge == null ? Colors.white : color,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(badge ?? fallback,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badge == null ? color : Colors.white)),
        ),
        const SizedBox(width: 6),
        Text('$time $label',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.strong = false, this.warn = false});

  final String label;
  final bool strong;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final bg = warn
        ? AppColors.warningSoft
        : strong
            ? AppColors.primarySoft
            : AppColors.surfaceMuted;
    final fg = warn
        ? AppColors.warningText
        : strong
            ? AppColors.primaryDark
            : AppColors.textChip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
