import 'order.dart';
import 'shipment.dart';

/// 오더 데이터 소스. 서버 연동 시 이 인터페이스의 구현만 교체한다.
abstract interface class OrderRepository {
  Future<List<Order>> fetchRecommendedOrders();
  Future<Order?> fetchOrder(String id);
  Future<List<Shipment>> fetchShipperShipments();
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

/// 목업과 동일한 샘플 데이터. 서버 연동 전까지 사용한다.
class MockOrderRepository implements OrderRepository {
  const MockOrderRepository();

  static const _orders = [_grainOrder, _compostOrder];

  @override
  Future<List<Order>> fetchRecommendedOrders() async => _orders;

  @override
  Future<Order?> fetchOrder(String id) async {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  Future<List<Shipment>> fetchShipperShipments() async => const [
        Shipment(
          order: _grainOrder,
          status: ShipmentStatus.inTransit,
          description: '김기사님 · 도착 예정 17:30',
        ),
        Shipment(
          order: _compostOrder,
          status: ShipmentStatus.waitingDispatch,
          description: '내일 07:00 상차',
        ),
      ];
}
