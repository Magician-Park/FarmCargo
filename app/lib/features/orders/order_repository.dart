import '../../core/clock.dart';
import '../../core/location/location_service.dart';
import 'order.dart';

/// 오더를 수락할 수 없을 때. [message]는 화면에 그대로 보여 준다.
class OrderAcceptException implements Exception {
  const OrderAcceptException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 오더 데이터 소스. 서버 연동 시 이 인터페이스의 구현만 교체한다.
/// 수락의 최종 판단(선착순·하루 3건)은 서버가 하며, 화면은 그 결과만 보여 준다.
abstract interface class OrderRepository {
  /// 차주 홈의 추천 맞춤 오더. 추천 기준은 미정이며 샘플은 고정 목록이다.
  Future<List<Order>> fetchRecommendedOrders();

  /// ‘오더 찾기’ 탭의 게시글들. 이미 선택된 오더는 빠진다(D02).
  Future<List<Order>> fetchJobPosts();

  Future<Order?> fetchOrder(String id);

  /// 오더를 수락한다. 수락하면 바로 확정된다(D02).
  /// 이미 선택된 오더이거나 상차일 기준 하루 3건을 넘으면 [OrderAcceptException](D03).
  Future<void> acceptOrder(String id);

  /// 내가 수락한 오더(‘내 오더’). 상차가 빠른 순.
  Future<List<Order>> fetchMyOrders();
}

/// 서버 연동 전까지 쓰는 샘플 데이터. 화주 이름·주소·단가·위치는 모두 가상 값이다.
/// 일정은 앱을 연 날을 기준으로 만들어 배지(당상·익상 등)가 늘 보이게 한다.
/// 수락 내역은 메모리에만 있어 앱을 새로 열면 사라진다.
class MockOrderRepository implements OrderRepository {
  /// [orders]를 주면 샘플 대신 그 목록을 쓴다(테스트용).
  MockOrderRepository({DateTime Function()? now, List<Order>? orders})
      : _orders = orders ?? _sampleOrders(dateOnly((now ?? DateTime.now)()));

  static const dailyAcceptLimit = 3;

  final List<Order> _orders;
  final _acceptedIds = <String>[];

  List<Order> get _available =>
      [for (final o in _orders) if (!_acceptedIds.contains(o.id)) o];

  @override
  Future<List<Order>> fetchRecommendedOrders() async =>
      _available.take(2).toList();

  @override
  Future<List<Order>> fetchJobPosts() async => _available;

  @override
  Future<Order?> fetchOrder(String id) async {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  Future<void> acceptOrder(String id) async {
    final order = await fetchOrder(id);
    if (order == null || _acceptedIds.contains(id)) {
      throw const OrderAcceptException('이미 다른 차주가 선택했거나 없는 오더예요.');
    }
    final mine = await fetchMyOrders();
    final sameDay = mine
        .where((o) => daysBetween(o.loading.date, order.loading.date) == 0)
        .length;
    if (sameDay >= dailyAcceptLimit) {
      throw const OrderAcceptException(
          '같은 상차일에는 하루 최대 $dailyAcceptLimit건까지 수락할 수 있어요.');
    }
    _acceptedIds.add(id);
  }

  @override
  Future<List<Order>> fetchMyOrders() async {
    final mine = [
      for (final o in _orders) if (_acceptedIds.contains(o.id)) o,
    ];
    mine.sort((a, b) => a.loading.date.compareTo(b.loading.date));
    return mine;
  }
}

List<Order> _sampleOrders(DateTime today) {
  DateTime day(int offset) => today.add(Duration(days: offset));
  Schedule at(int offset, String start, String end) =>
      Schedule(date: day(offset), startTime: start, endTime: end);
  DateTime posted(int hoursAgo) =>
      today.add(const Duration(hours: 9)).subtract(Duration(hours: hoursAgo));

  return [
    Order(
      id: 'order-1',
      item: '대두',
      originCountry: OriginCountry.domestic,
      shipperName: '한들영농조합',
      origin: '전북 김제시 죽산면 한들로 12 한들영농조합 창고',
      destination: '경기 이천시 부발읍 한들로 45 들빛식품 공장',
      originRegion: '전북 김제',
      destinationRegion: '경기 이천',
      originPoint: const GeoPoint(35.8036, 126.8809),
      quantity: '톤백 12개(12톤)',
      weightKg: 12000,
      vehicleTypes: const ['카고'],
      loading: at(1, '07:00', '09:00'),
      unloading: at(1, '13:00', '15:00'),
      priceUnit: PriceUnit.perTruck,
      unitPrice: 270000,
      distanceKm: 215,
      registeredAt: posted(20),
    ),
    Order(
      id: 'order-2',
      item: '퇴비',
      originCountry: OriginCountry.domestic,
      shipperName: '푸른축산',
      origin: '충남 홍성군 홍북읍 푸른로 7 푸른축산 퇴비사',
      destination: '전북 김제시 죽산면 한들리 123 논',
      originRegion: '충남 홍성',
      destinationRegion: '전북 김제',
      originPoint: const GeoPoint(36.6012, 126.6608),
      quantity: '벌크 25톤',
      weightKg: 25000,
      vehicleTypes: const ['덤프', '워킹'],
      loading: at(2, '08:00', '10:00'),
      unloading: at(3, '07:00', '09:00'),
      priceUnit: PriceUnit.perKg,
      unitPrice: 11.5,
      distanceKm: 128,
      registeredAt: posted(3),
      isCompost: true,
    ),
    Order(
      id: 'order-3',
      item: '소맥피',
      originCountry: OriginCountry.imported,
      shipperName: '바다사료',
      origin: '인천 서구 북항로 21 바다항 창고',
      destination: '충남 당진시 송악읍 바다로 88 바다사료 공장',
      originRegion: '인천 서구',
      destinationRegion: '충남 당진',
      originPoint: const GeoPoint(37.5459, 126.6760),
      quantity: '벌크 24톤',
      weightKg: 24000,
      vehicleTypes: const ['덤프', '워킹'],
      loading: at(0, '13:00', '15:00'),
      unloading: at(0, '17:00', '19:00'),
      priceUnit: PriceUnit.perKg,
      unitPrice: 12.5,
      distanceKm: 112,
      registeredAt: posted(1),
    ),
    Order(
      id: 'order-4',
      item: '대두박',
      originCountry: OriginCountry.imported,
      shipperName: '별빛사료',
      origin: '충남 천안시 동남구 별빛로 3 별빛물류센터',
      destination: '전북 익산시 왕궁면 별빛로 21 별빛사료',
      originRegion: '충남 천안',
      destinationRegion: '전북 익산',
      originPoint: const GeoPoint(36.7840, 127.1700),
      quantity: '톤백 20개(20톤)',
      weightKg: 20000,
      vehicleTypes: const ['카고'],
      loading: at(1, '07:00', '09:00'),
      unloading: at(2, '08:00', '10:00'),
      priceUnit: PriceUnit.perTruck,
      unitPrice: 350000,
      distanceKm: 164,
      registeredAt: posted(8),
    ),
    Order(
      id: 'order-5',
      item: '옥수수',
      originCountry: OriginCountry.imported,
      shipperName: '누리사료',
      origin: '충남 아산시 인주면 누리로 5 누리항 창고',
      destination: '경북 경주시 안강읍 누리로 5 누리사료 공장',
      originRegion: '충남 아산',
      destinationRegion: '경북 경주',
      originPoint: const GeoPoint(36.8720, 126.8360),
      quantity: '벌크 25톤',
      weightKg: 25000,
      vehicleTypes: const ['워킹'],
      loading: at(0, '16:00', '18:00'),
      unloading: at(1, '08:00', '10:00'),
      priceUnit: PriceUnit.perTruck,
      unitPrice: 430000,
      distanceKm: 245,
      registeredAt: posted(5),
    ),
    Order(
      id: 'order-6',
      item: '팜박',
      originCountry: OriginCountry.imported,
      shipperName: '들녘목장',
      origin: '충북 청주시 흥덕구 들녘로 30 들녘물류 창고',
      destination: '충남 천안시 동남구 성남면 들녘길 9 들녘목장',
      originRegion: '충북 청주',
      destinationRegion: '충남 천안',
      originPoint: const GeoPoint(36.6424, 127.4890),
      quantity: '포대 600포(12톤)',
      weightKg: 12000,
      vehicleTypes: const ['카고'],
      loading: at(3, '09:00', '11:00'),
      unloading: at(3, '13:00', '15:00'),
      priceUnit: PriceUnit.perKg,
      unitPrice: 16,
      distanceKm: 76,
      registeredAt: posted(30),
    ),
  ];
}
