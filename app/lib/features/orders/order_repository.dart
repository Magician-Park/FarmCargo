import 'order.dart';

/// 오더 데이터 소스. 서버 연동 시 이 인터페이스의 구현만 교체한다.
abstract interface class OrderRepository {
  /// 차주 홈의 추천 맞춤 오더. 추천 기준은 미정이며 샘플은 고정 목록이다.
  Future<List<Order>> fetchRecommendedOrders();

  /// 일감 목록 탭의 게시글들. 가용 목록에서 선택된 건은 빠진다.
  Future<List<Order>> fetchJobPosts();

  Future<Order?> fetchOrder(String id);
}

const _grainOrder = Order(
  id: 'order-1',
  category: '식용 곡물',
  origin: '전북 김제시 죽산면',
  destination: '경기 이천시 ○○ RPC',
  price: 256500,
  cargoInfo: '톤백 12개',
  vehicleInfo: '5톤 카고·크레인',
  distanceKm: 215,
);

const _compostOrder = Order(
  id: 'order-2',
  category: '퇴비 벌크',
  origin: '충남 홍성군 ○○축산 퇴비사',
  destination: '전북 김제시 죽산면 논',
  price: 279350,
  cargoInfo: '톤당 정산',
  vehicleInfo: '25톤 덤프(특수)',
  distanceKm: 128,
  isCompost: true,
);

const _jobPosts = [
  _grainOrder,
  _compostOrder,
  Order(
    id: 'order-3',
    category: '사료 원료(소맥피)',
    origin: '인천 서구 ○○항 창고',
    destination: '충남 당진시 ○○사료공장',
    price: 310000,
    cargoInfo: '벌크 24톤',
    vehicleInfo: '25톤 덤프',
    distanceKm: 112,
  ),
  Order(
    id: 'order-4',
    category: '사료 원료(대두박)',
    origin: '전남 광양시 ○○항',
    destination: '전북 익산시 ○○사료',
    price: 340000,
    cargoInfo: '톤백 20개',
    vehicleInfo: '11톤 카고',
    distanceKm: 164,
  ),
  Order(
    id: 'order-5',
    category: '사료 원료(옥수수)',
    origin: '부산 남구 ○○부두',
    destination: '경북 경주시 ○○사료공장',
    price: 420000,
    cargoInfo: '벌크 25톤',
    vehicleInfo: '25톤 워킹',
    distanceKm: 95,
  ),
  Order(
    id: 'order-6',
    category: '사료 원료(주정박)',
    origin: '충북 청주시 ○○주정공장',
    destination: '충남 천안시 ○○목장',
    price: 198000,
    cargoInfo: '포대 600포',
    vehicleInfo: '5톤 카고',
    distanceKm: 76,
  ),
];

/// 목업과 동일한 샘플 데이터. 서버 연동 전까지 사용한다.
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
