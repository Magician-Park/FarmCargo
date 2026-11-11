import 'order.dart';

/// 오더 데이터 소스. 서버 연동 시 이 인터페이스의 구현만 교체한다.
abstract interface class OrderRepository {
  /// 차주 홈의 추천 맞춤 오더. 추천 기준은 미정이며 샘플은 고정 목록이다.
  Future<List<Order>> fetchRecommendedOrders();

  /// ‘오더 찾기’ 탭의 게시글들. 가용 목록에서 선택된 건은 빠진다.
  Future<List<Order>> fetchJobPosts();

  Future<Order?> fetchOrder(String id);
}

// 아래 화주 이름·주소·단가·일정은 모두 시연용 가상 값이다.
final _soybeanOrder = Order(
  id: 'order-1',
  item: '대두',
  originCountry: OriginCountry.domestic,
  shipperName: '○○영농조합',
  origin: '전북 김제시 죽산면 ○○로 12 ○○영농조합 창고',
  destination: '경기 이천시 부발읍 ○○로 45 ○○식품 공장',
  quantity: '톤백 12개(12톤)',
  vehicleTypes: const ['카고'],
  loading: Schedule(
      date: DateTime(2026, 11, 13), startTime: '07:00', endTime: '09:00'),
  unloading: Schedule(
      date: DateTime(2026, 11, 13), startTime: '13:00', endTime: '15:00'),
  priceUnit: PriceUnit.perTruck,
  unitPrice: 270000,
  distanceKm: 215,
);

final _compostOrder = Order(
  id: 'order-2',
  item: '퇴비',
  originCountry: OriginCountry.domestic,
  shipperName: '△△축산',
  origin: '충남 홍성군 홍북읍 △△로 7 △△축산 퇴비사',
  destination: '전북 김제시 죽산면 ○○리 123 논',
  quantity: '벌크 25톤',
  vehicleTypes: const ['덤프', '워킹'],
  loading: Schedule(
      date: DateTime(2026, 11, 14), startTime: '08:00', endTime: '10:00'),
  unloading: Schedule(
      date: DateTime(2026, 11, 14), startTime: '13:00', endTime: '16:00'),
  priceUnit: PriceUnit.perKg,
  unitPrice: 11.5,
  distanceKm: 128,
  isCompost: true,
);

final _jobPosts = [
  _soybeanOrder,
  _compostOrder,
  Order(
    id: 'order-3',
    item: '소맥피',
    originCountry: OriginCountry.imported,
    shipperName: '□□사료',
    origin: '인천 서구 북항로 ○○ □□항 창고',
    destination: '충남 당진시 송악읍 □□로 88 □□사료 공장',
    quantity: '벌크 24톤',
    vehicleTypes: const ['덤프', '워킹'],
    loading: Schedule(
        date: DateTime(2026, 11, 13), startTime: '06:00', endTime: '08:00'),
    unloading: Schedule(
        date: DateTime(2026, 11, 13), startTime: '10:00', endTime: '12:00'),
    priceUnit: PriceUnit.perKg,
    unitPrice: 12.5,
    distanceKm: 112,
  ),
  Order(
    id: 'order-4',
    item: '대두박',
    originCountry: OriginCountry.imported,
    shipperName: '☆☆사료',
    origin: '전남 광양시 항만로 ○○ ☆☆항 부두',
    destination: '전북 익산시 왕궁면 ☆☆로 21 ☆☆사료',
    quantity: '톤백 20개(20톤)',
    vehicleTypes: const ['카고'],
    loading: Schedule(
        date: DateTime(2026, 11, 16), startTime: '07:00', endTime: '09:00'),
    unloading: Schedule(
        date: DateTime(2026, 11, 16), startTime: '12:00', endTime: '14:00'),
    priceUnit: PriceUnit.perTruck,
    unitPrice: 350000,
    distanceKm: 164,
  ),
  Order(
    id: 'order-5',
    item: '옥수수',
    originCountry: OriginCountry.imported,
    shipperName: '◇◇사료',
    origin: '부산 남구 감만동 ◇◇부두 창고',
    destination: '경북 경주시 안강읍 ◇◇로 5 ◇◇사료 공장',
    quantity: '벌크 25톤',
    vehicleTypes: const ['워킹'],
    loading: Schedule(
        date: DateTime(2026, 11, 17), startTime: '08:00', endTime: '10:00'),
    unloading: Schedule(
        date: DateTime(2026, 11, 17), startTime: '11:00', endTime: '13:00'),
    priceUnit: PriceUnit.perTruck,
    unitPrice: 430000,
    distanceKm: 95,
  ),
  Order(
    id: 'order-6',
    item: '팜박',
    originCountry: OriginCountry.imported,
    shipperName: '▽▽목장',
    origin: '충북 청주시 흥덕구 ▽▽로 30 ▽▽물류 창고',
    destination: '충남 천안시 동남구 성남면 ▽▽길 9 ▽▽목장',
    quantity: '포대 600포(12톤)',
    vehicleTypes: const ['카고'],
    loading: Schedule(
        date: DateTime(2026, 11, 18), startTime: '09:00', endTime: '11:00'),
    unloading: Schedule(
        date: DateTime(2026, 11, 18), startTime: '13:00', endTime: '15:00'),
    priceUnit: PriceUnit.perKg,
    unitPrice: 16,
    distanceKm: 76,
  ),
];

/// 서버 연동 전까지 쓰는 샘플 데이터.
class MockOrderRepository implements OrderRepository {
  const MockOrderRepository();

  @override
  Future<List<Order>> fetchRecommendedOrders() async => _jobPosts.sublist(0, 2);

  @override
  Future<List<Order>> fetchJobPosts() async => _jobPosts;

  @override
  Future<Order?> fetchOrder(String id) async {
    for (final order in _jobPosts) {
      if (order.id == id) return order;
    }
    return null;
  }
}
