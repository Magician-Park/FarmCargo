/// 오더 데이터 모델. 곡물/퇴비 카드가 이 하나의 모델로 표현된다.
class Order {
  final String id;
  final String category; // 예: '식용 곡물', '퇴비 벌크'
  final String origin;
  final String destination;
  final int price; // 차주 실수령액(원)
  final String cargoInfo; // '톤백 12개', '톤당 정산'
  final String vehicleInfo; // '5톤 카고·크레인', '25톤 덤프(특수)'
  final int distanceKm;
  final bool isCompost; // true면 상세 화면에 퇴비 이력 경고 표시

  const Order({
    required this.id,
    required this.category,
    required this.origin,
    required this.destination,
    required this.price,
    required this.cargoInfo,
    required this.vehicleInfo,
    required this.distanceKm,
    this.isCompost = false,
  });

  String get distanceLabel => '${distanceKm}km';
}
