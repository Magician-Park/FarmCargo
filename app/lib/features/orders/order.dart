import '../../core/clock.dart';
import '../../core/location/location_service.dart';
import '../../core/utils/format.dart';

/// 원산지. 오더 작성 때 반드시 고른다(D13).
enum OriginCountry {
  domestic('국산'),
  imported('외국산');

  const OriginCountry(this.label);
  final String label;
}

/// 단가 방식. 화주가 차 1대 건당 금액 또는 kg당 금액 중 골라 올린다(D01).
enum PriceUnit { perTruck, perKg }

/// 상차·하차 일정. 날짜와 시간대(몇 시~몇 시).
class Schedule {
  final DateTime date;
  final String startTime; // 'HH:mm'
  final String endTime; // 'HH:mm'

  const Schedule(
      {required this.date, required this.startTime, required this.endTime});

  String get label => '${formatShortDate(date)} $startTime~$endTime';
}

/// 오더 데이터 모델. 화주가 입력한 필수 항목(D01)과 차주에게 보이는 화주 정보(D06)를 담는다.
class Order {
  final String id;
  final String item; // 품목. 목록(소맥피 등)에서 고르거나 직접 입력(D13)
  final OriginCountry originCountry;
  final String shipperName; // 차주에게 목록에서부터 보이는 화주 이름(D06)
  final String origin; // 상차지 상세 주소
  final String destination; // 하차지 상세 주소
  final String originRegion; // 카드 제목용 짧은 지역명. 예: '인천 서구'
  final String destinationRegion;
  final GeoPoint originPoint; // 상차지 위치(내 위치에서의 거리 계산용)
  final String quantity; // 물량. 예: '24톤'
  final int weightKg; // 물량(kg). kg당 단가의 예상 운송비 계산용
  final List<String> vehicleTypes; // 운반 가능한 차종(여러 개, 표기는 워킹·덤프·카고)
  final Schedule loading;
  final Schedule unloading;
  final PriceUnit priceUnit;

  /// 단가(원, 부가세 별도). kg당이면 소수점 첫째 자리까지.
  final num unitPrice;
  final int distanceKm; // 상차지→하차지 운행 거리
  final DateTime registeredAt; // 화주가 오더를 올린 시각
  final bool isCompost; // true면 상세 화면에 퇴비 이력 경고 표시

  const Order({
    required this.id,
    required this.item,
    required this.originCountry,
    required this.shipperName,
    required this.origin,
    required this.destination,
    required this.originRegion,
    required this.destinationRegion,
    required this.originPoint,
    required this.quantity,
    required this.weightKg,
    required this.vehicleTypes,
    required this.loading,
    required this.unloading,
    required this.priceUnit,
    required this.unitPrice,
    required this.distanceKm,
    required this.registeredAt,
    this.isCompost = false,
  });

  String get distanceLabel => '${distanceKm}km';
  String get itemLabel => '$item · ${originCountry.label}';
  String get vehicleLabel => vehicleTypes.join('·');

  /// 예상 운송비(원, 부가세 별도). kg당이면 단가 × 물량(kg)으로 계산한 값이다.
  int get estimatedFare => switch (priceUnit) {
        PriceUnit.perTruck => unitPrice.toInt(),
        PriceUnit.perKg => (unitPrice * weightKg).round(),
      };

  /// 상차 배지(사용자 정의 2026-11-12): 당상=당일 상차(오늘 싣기), 익상=익일 상차(내일 싣기).
  /// 그 밖의 날짜는 배지 없이 날짜를 보여 준다.
  String? loadingBadge(DateTime today) =>
      switch (daysBetween(today, loading.date)) {
        0 => '당상',
        1 => '익상',
        _ => null,
      };

  /// 하차 배지(사용자 정의 2026-11-12): 당착=당일 도착(오늘 내리기), 내착=내일 도착(내일 내리기).
  /// 상차일이 아니라 오늘을 기준으로 센다.
  String? unloadingBadge(DateTime today) =>
      switch (daysBetween(today, unloading.date)) {
        0 => '당착',
        1 => '내착',
        _ => null,
      };

  /// 예: '건당 350,000원', 'kg당 12.5원'. 부가세는 별도.
  String get priceLabel => switch (priceUnit) {
        PriceUnit.perTruck => '건당 ${formatWon(unitPrice.toInt())}원',
        PriceUnit.perKg => 'kg당 ${formatKgPrice(unitPrice)}원',
      };
}
