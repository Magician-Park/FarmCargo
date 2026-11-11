/// 운행 기록 한 건(사용자 결정 2026-11-12 17차 항목: 운행 날짜, 상차지→하차지, 품목·물량, 운송비, 받은 별점).
/// 운송 증빙까지 마쳐 운송 종료가 확인된 운행만 쌓인다.
class TripRecord {
  final String orderId;
  final DateTime date; // 운행 날짜(하차일)
  final String originRegion;
  final String destinationRegion;
  final String itemLabel; // 예: '소맥피 · 외국산'
  final String quantity;
  final int fare; // 운송비(원, 부가세 별도)
  final int? rating; // 화주가 준 별점 1~5. 아직 평가 전이면 null(D17)

  const TripRecord({
    required this.orderId,
    required this.date,
    required this.originRegion,
    required this.destinationRegion,
    required this.itemLabel,
    required this.quantity,
    required this.fare,
    this.rating,
  });
}
