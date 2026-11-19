import '../../core/clock.dart';
import 'trip_record.dart';

/// 정산 계산 규칙(D09·D17·D18, 사용자 결정 2026-11-05·09·10·11).
/// 실제 금액·랭킹 확정은 서버가 하고, 앱은 같은 규칙으로 보여 주기만 한다.

/// 기본 수수료율 4%를 천분율로(40‰). 상위 5%는 3%(30‰), 상위 10%는 3.5%(35‰).
const baseFeePerMille = 40;
const top5FeePerMille = 30;
const top10FeePerMille = 35;

/// 부가세 10%. 1원 미만 반올림.
int vatOf(int supply) => (supply + 5) ~/ 10;

/// [amount] × [perMille]‰, 1원 미만 반올림.
int feeOf(int amount, int perMille) => (amount * perMille + 500) ~/ 1000;

/// 수수료율 천분율을 '4%', '3.5%'처럼.
String feeRateLabel(int perMille) =>
    perMille % 10 == 0 ? '${perMille ~/ 10}%' : '${perMille ~/ 10}.${perMille % 10}%';

/// [n]명 중 [percent]%에 드는 인원. 올림해 최소 1명(2026-11-09).
int topCount(int n, int percent) => n <= 0 ? 0 : (n * percent + 99) ~/ 100;

/// 공동 순위: 나보다 별이 많은 차주 수 + 1. 별이 같으면 같은 순위.
int competitionRank(int myStars, Iterable<int> othersStars) =>
    1 + othersStars.where((s) => s > myStars).length;

/// 순위에 따른 수수료율. [rank]가 null이면(이번 달 별점 없음) 기본 4%.
int feePerMilleFor(int? rank, int rankedCount) {
  if (rank == null) return baseFeePerMille;
  if (rank <= topCount(rankedCount, 5)) return top5FeePerMille;
  if (rank <= topCount(rankedCount, 10)) return top10FeePerMille;
  return baseFeePerMille;
}

/// 은행 영업일: 토·일과 [holidays](공휴일)를 뺀 날. D14 제재의 영업일(일요일만 뺌)과 다르다.
bool isBankBusinessDay(DateTime d, Set<DateTime> holidays) =>
    d.weekday != DateTime.saturday &&
    d.weekday != DateTime.sunday &&
    !holidays.contains(dateOnly(d));

/// 차주 지급일: 화주 정산일 10일 뒤. 그날이 은행 휴일이면 그 전 은행 영업일(2026-11-09·10).
DateTime payoutDateFor(DateTime shipperPaidOn,
    {Set<DateTime> holidays = const {}}) {
  var d = dateOnly(shipperPaidOn).add(const Duration(days: 10));
  while (!isBankBusinessDay(d, holidays)) {
    d = d.subtract(const Duration(days: 1));
  }
  return d;
}

/// 별 개수가 다시 0이 되는 때: 다음 달 1일 0시(D17).
DateTime nextRankingReset(DateTime now) => DateTime(now.year, now.month + 1);

/// 한 달 별점 랭킹(D17). 화주에게 처음 별점을 받은 차주부터 랭킹에 들어간다.
class MonthlyRanking {
  const MonthlyRanking({
    required this.month,
    required this.myStars,
    required this.othersStars,
  });

  /// 그 달 1일.
  final DateTime month;
  final int myStars;

  /// 그 달 별점을 받은 다른 차주들의 별 개수.
  final List<int> othersStars;

  bool get isRanked => myStars > 0;
  int get rankedCount => othersStars.length + (isRanked ? 1 : 0);
  int? get rank => isRanked ? competitionRank(myStars, othersStars) : null;
  int get feePerMille => feePerMilleFor(rank, rankedCount);
  int get top5Count => topCount(rankedCount, 5);
  int get top10Count => topCount(rankedCount, 10);
}

/// 정산 상태(사용자 결정 2026-11-12 17차).
enum SettlementStatus {
  awaitingShipper('화주 정산 대기'),
  scheduled('지급 예정'),
  paid('지급 완료'),
  held('지급 보류');

  const SettlementStatus(this.label);
  final String label;
}

/// 운송 한 건의 정산.
class SettlementItem {
  const SettlementItem({
    required this.record,
    required this.status,
    required this.feePerMille,
    required this.rateFinal,
    this.shipperPaidOn,
    this.payoutOn,
  });

  final TripRecord record;
  final SettlementStatus status;

  /// 그 달 랭킹에 따른 수수료율(‰). 달이 끝나기 전에는 바뀔 수 있다([rateFinal]이 false).
  final int feePerMille;
  final bool rateFinal;
  final DateTime? shipperPaidOn;
  final DateTime? payoutOn;

  int get supply => record.fare;
  int get vat => vatOf(supply);

  /// 부가세를 포함한 운송비. 수수료 4%는 이 금액에 매긴다(2026-11-09).
  int get total => supply + vat;
  int get fee => feeOf(total, feePerMille);
  int get payout => total - fee;
}
