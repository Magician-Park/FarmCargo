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
  final String quantity; // 물량. 예: '24톤'
  final List<String> vehicleTypes; // 운반 가능한 차종(여러 개, 표기는 워킹·덤프·카고)
  final Schedule loading;
  final Schedule unloading;
  final PriceUnit priceUnit;

  /// 단가(원, 부가세 별도). kg당이면 소수점 첫째 자리까지.
  final num unitPrice;
  final int distanceKm;
  final bool isCompost; // true면 상세 화면에 퇴비 이력 경고 표시

  const Order({
    required this.id,
    required this.item,
    required this.originCountry,
    required this.shipperName,
    required this.origin,
    required this.destination,
    required this.quantity,
    required this.vehicleTypes,
    required this.loading,
    required this.unloading,
    required this.priceUnit,
    required this.unitPrice,
    required this.distanceKm,
    this.isCompost = false,
  });

  String get distanceLabel => '${distanceKm}km';
  String get itemLabel => '$item · ${originCountry.label}';
  String get vehicleLabel => vehicleTypes.join('·');

  /// 예: '건당 350,000원', 'kg당 12.5원'. 부가세는 별도.
  String get priceLabel => switch (priceUnit) {
        PriceUnit.perTruck => '건당 ${formatWon(unitPrice.toInt())}원',
        PriceUnit.perKg => 'kg당 ${formatKgPrice(unitPrice)}원',
      };
}
