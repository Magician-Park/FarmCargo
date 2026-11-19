import '../../core/clock.dart';
import 'order.dart';

/// 배차 취소 마감(D04).
/// - 당일 배차(수락한 날 바로 상차): 상차일 오전 9시
/// - 그 밖: 상차일 전날 오후 3시
/// 이 시각이 지나면 화주·차주 모두 취소할 수 없다.
DateTime cancelDeadline(Order order, DateTime acceptedAt) {
  final loadingDay = dateOnly(order.loading.date);
  if (daysBetween(acceptedAt, loadingDay) == 0) {
    return loadingDay.add(const Duration(hours: 9));
  }
  return loadingDay.subtract(const Duration(days: 1)).add(const Duration(hours: 15));
}

/// 예: 2026-11-18 15:00 -> '11월 18일(수) 15:00'
String formatDeadline(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${d.month}월 ${d.day}일(${weekdays[d.weekday - 1]}) $hh:$mm';
}

/// 과도한 취소: 취소한 날 기준 하루 3건째부터(하루 2건까지는 괜찮음, D14).
const excessiveCancelFrom = 3;

/// 영업일은 월~토(일요일만 빼고, 공휴일은 영업일에 넣음, D14).
bool isBusinessDay(DateTime d) => d.weekday != DateTime.sunday;

/// [from] 시각에서 영업일 [days]일 뒤 같은 시각. 일요일은 세지 않는다.
DateTime addBusinessDays(DateTime from, int days) {
  var d = from;
  var left = days;
  while (left > 0) {
    d = d.add(const Duration(days: 1));
    if (isBusinessDay(d)) left--;
  }
  return d;
}

/// 경고 횟수에 따른 정지 끝 시각(D14, 13~15차 결정).
/// 1회: 정지 시각부터 24시간(일요일에 걸쳐도 24시간), 2회: 7영업일, 3회: 30영업일(정지 시각 기준).
/// 4회 이상은 영구 정지 대상이라 null(대표이사 승인으로 블랙리스트 확정).
DateTime? suspensionEnd(int warningCount, DateTime suspendedAt) =>
    switch (warningCount) {
      <= 0 => suspendedAt,
      1 => suspendedAt.add(const Duration(hours: 24)),
      2 => addBusinessDays(suspendedAt, 7),
      3 => addBusinessDays(suspendedAt, 30),
      _ => null,
    };

/// 차주 제재 상태.
class DriverSanction {
  const DriverSanction({
    this.warningCount = 0,
    this.suspendedUntil,
    this.permanentReview = false,
  });

  /// 지금 유효한 경고 수(최초 경고 1년 뒤 전체 초기화).
  final int warningCount;

  /// 오더 수락이 막히는 끝 시각. 정지 중이 아니면 null.
  final DateTime? suspendedUntil;

  /// 경고가 4회 이상 쌓여 영구 정지 심사 중.
  final bool permanentReview;

  bool isSuspended(DateTime now) =>
      permanentReview || (suspendedUntil != null && now.isBefore(suspendedUntil!));

  /// 화면에 보여 줄 정지 안내.
  String message() => permanentReview
      ? '경고가 4회 쌓여 영구 정지 심사 중이에요. 오더를 수락할 수 없어요. 고객센터로 문의해 주세요.'
      : '경고 $warningCount회로 ${formatDeadline(suspendedUntil!)}까지 오더를 수락할 수 없어요.';
}
