import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/demo_notice.dart';
import '../orders/orders_providers.dart';
import '../orders/settlement.dart';
import '../orders/trip.dart';
import '../orders/trip_record.dart';

/// 별점·랭킹(D17): 이번 달 받은 별, 내 순위, 예상 수수료율, 받은 별점 목록.
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(rankingProvider);
    final records = ref.watch(tripRecordsProvider).value ?? const <TripRecord>[];
    final now = ref.watch(clockProvider)();
    final demo = ref.watch(isDemoRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('별점·랭킹',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: AsyncValueView(
        value: ranking,
        onRetry: () => ref.invalidate(rankingProvider),
        builder: (rk) {
          final rated = [
            for (final r in records)
              if (r.ratedAt != null &&
                  r.ratedAt!.year == rk.month.year &&
                  r.ratedAt!.month == rk.month.month)
                r
          ];
          final unrated = [for (final r in records) if (r.rating == null) r];
          final reset = nextRankingReset(now);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Summary(ranking: rk),
              const SizedBox(height: 12),
              _Criteria(ranking: rk),
              const SizedBox(height: 8),
              Text(
                '별 개수는 ${reset.month}월 1일 0시에 모두 0개로 초기화돼요. '
                '그 달 랭킹은 그 달 정산의 수수료율에 적용돼요.',
                style: const TextStyle(
                    fontSize: 12, height: 1.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Text('${rk.month.month}월에 받은 별점',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (rated.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('이번 달에 받은 별점이 없어요.\n화주가 운송 완료를 확인한 뒤 별점을 줄 수 있어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, height: 1.5)),
                )
              else
                for (final r in rated) _RatedTile(record: r),
              if (demo) ...[
                const SizedBox(height: 20),
                const DemoNotice(),
                const SizedBox(height: 6),
                const Text(
                    '시연용: 다른 차주 별점은 가상 값이에요. 화주 앱이 아직 없어 별점 대기 중인 운행에 화주 별점을 대신 줄 수 있어요.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                for (final r in unrated) _DemoRate(record: r),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.ranking});
  final MonthlyRanking ranking;

  @override
  Widget build(BuildContext context) {
    final rank = ranking.rank;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${ranking.month.month}월 받은 별',
              style: const TextStyle(color: AppColors.accentMint)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.star, color: AppColors.accentMint, size: 30),
              const SizedBox(width: 6),
              Text('${ranking.myStars}개',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rank == null
                ? '아직 이번 달 별점을 받지 않아 랭킹에 들지 않았어요.'
                : '랭킹 차주 ${ranking.rankedCount}명 중 $rank위',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text('예상 수수료율 ${feeRateLabel(ranking.feePerMille)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Criteria extends StatelessWidget {
  const _Criteria({required this.ranking});
  final MonthlyRanking ranking;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String rate, bool mine) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: mine ? AppColors.primary : AppColors.primarySoft),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text('수수료 $rate',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (mine) ...[
                const SizedBox(width: 6),
                const Text('내 구간',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        );
    final fee = ranking.feePerMille;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row('상위 5% (${ranking.top5Count}위까지)', '3%', fee == top5FeePerMille),
        row('상위 10% (${ranking.top10Count}위까지)', '3.5%', fee == top10FeePerMille),
        row('그 밖', '4%', fee == baseFeePerMille),
        const Text('별이 같으면 같은 순위예요. 5%·10% 인원은 올림해 최소 1명은 낮아져요.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '별점 $count점',
        excludeSemantics: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 1; i <= 5; i++)
            Icon(i <= count ? Icons.star : Icons.star_border,
                size: 18, color: AppColors.primaryLight),
        ]),
      );
}

class _RatedTile extends StatelessWidget {
  const _RatedTile({required this.record});
  final TripRecord record;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('${record.originRegion} → ${record.destinationRegion}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${formatShortDate(record.date)} · ${record.itemLabel}'),
        trailing: _Stars(record.rating!),
      );
}

class _DemoRate extends ConsumerWidget {
  const _DemoRate({required this.record});
  final TripRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> rate(int stars) async {
      try {
        await simulateShipperRating(ref, record.orderId, stars);
      } on TripActionException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text('${record.originRegion} → ${record.destinationRegion}',
                style: const TextStyle(fontSize: 13)),
          ),
          for (var i = 1; i <= 5; i++)
            IconButton(
              tooltip: '화주: 별 $i개',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.star_border, color: AppColors.primary),
              onPressed: () => rate(i),
            ),
        ],
      ),
    );
  }
}
