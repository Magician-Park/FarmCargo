/// 오더 데이터 모델. 목업의 곡물/퇴비 카드가 이 하나의 모델로 표현된다.
class Order {
  final String category; // 예: '식용 곡물', '퇴비 벌크'
  final String origin;
  final String destination;
  final int price; // 차주 실수령액(원)
  final String cargoInfo; // '톤백 12개', '톤당 정산'
  final String vehicleInfo; // '5톤 카고·크레인', '25톤 덤프(특수)'
  final String distance;
  final bool isCompost; // true면 상세 화면에 퇴비 이력 경고 표시

  const Order({
    required this.category,
    required this.origin,
    required this.destination,
    required this.price,
    required this.cargoInfo,
    required this.vehicleInfo,
    required this.distance,
    this.isCompost = false,
  });
}

/// 목업과 동일한 샘플 데이터. 서버 연동 전까지 로비 리스트의 소스.
const sampleOrders = [
  Order(
    category: '식용 곡물',
    origin: '전북 김제시 죽산면',
    destination: '경기 이천시 ○○ RPC',
    price: 256500,
    cargoInfo: '톤백 12개',
    vehicleInfo: '5톤 카고·크레인',
    distance: '215km',
  ),
  Order(
    category: '퇴비 벌크',
    origin: '충남 홍성군 ○○축산 퇴비사',
    destination: '전북 김제시 죽산면 논',
    price: 279350,
    cargoInfo: '톤당 정산',
    vehicleInfo: '25톤 덤프(특수)',
    distance: '128km',
    isCompost: true,
  ),
];
