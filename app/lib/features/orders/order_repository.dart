import '../../core/clock.dart';
import '../../core/location/location_service.dart';
import 'driver_alert.dart';
import 'order.dart';
import 'order_policy.dart';
import 'settlement.dart';
import 'trip.dart';
import 'trip_record.dart';

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

  /// 내가 수락하고 아직 운송이 끝나지 않은 오더(‘내 오더’). 상차가 빠른 순.
  Future<List<Order>> fetchMyOrders();

  /// 운송 종료가 확인된 운행 기록. 최근 순.
  Future<List<TripRecord>> fetchTripRecords();

  /// 내가 수락한 오더의 운행 진행 상태. 내 오더가 아니면 null.
  Future<TripProgress?> fetchTrip(String orderId);

  /// 상차 계근표 사진을 올린다. 화주 확인 없이 사진만 저장한다(D05).
  Future<void> uploadLoadingProof(String orderId, String photoPath);

  /// 하차 계근표(없으면 공장 직원 서명) 사진을 올리고 화주에게 확인을 요청한다(D05).
  /// 화주가 30분 안에 답하지 않으면 다시 알리고, 1시간 10분 무응답이면 고객센터에 알리는 일은 서버가 한다.
  Future<void> uploadUnloadingProof(
      String orderId, String photoPath, UnloadingProofKind kind);

  /// 내 경고·정지 상태(D14). 정지 중이면 오더를 수락할 수 없다.
  Future<DriverSanction> fetchSanction();

  /// 오늘(취소한 날 기준) 이미 취소한 건수. 3건째부터 과도한 취소다(D14).
  Future<int> cancellationsToday();

  /// 배차를 취소한다(D04). 상차 전이고 취소 마감 전이어야 하며 사유가 필요하다.
  /// 취소한 오더는 오더 찾기에 다시 올라간다. 경고 부여는 고객센터·관리자가 판단한다.
  Future<void> cancelOrder(String orderId, String reason);

  /// 화주가 보낸 조건 변경 중 아직 답하지 않은 것. 없으면 null.
  Future<ConditionChange?> fetchPendingChange(String orderId);

  /// 조건 변경에 답한다(D04). 수락하면 바뀐 조건으로 운행하고,
  /// 거절하면 배차가 풀린다. 패널티 없는 거절이 아니면 경고 1회가 되어 오더 수락이 정지된다.
  Future<void> respondToChange(String orderId, {required bool accept});

  /// 내 알림 목록(최근 순).
  Future<List<DriverAlert>> fetchAlerts();

  /// 알림을 모두 읽음으로 바꾼다.
  Future<void> markAlertsRead();

  /// 운송 완료·지급 보류 건의 정산(최근 순). 금액·수수료율 확정은 서버가 한다(D09·D17).
  Future<List<SettlementItem>> fetchSettlements();

  /// 이번 달 별점 랭킹(D17).
  Future<MonthlyRanking> fetchRanking();
}

/// 서버 연동 전까지 쓰는 샘플 데이터. 화주 이름·주소·단가·위치는 모두 가상 값이다.
/// 일정은 앱을 연 날을 기준으로 만들어 배지(당상·익상 등)가 늘 보이게 한다.
/// 수락 내역은 메모리에만 있어 앱을 새로 열면 사라진다.
class MockOrderRepository implements OrderRepository {
  /// [orders]를 주면 샘플 대신 그 목록을 쓴다(테스트용).
  MockOrderRepository({DateTime Function()? now, List<Order>? orders})
      : _now = now ?? DateTime.now,
        _orders = orders ?? _sampleOrders(dateOnly((now ?? DateTime.now)()));

  static const dailyAcceptLimit = 3;

  final List<Order> _orders;
  final DateTime Function() _now;
  final _acceptedIds = <String>[];
  final _trips = <String, TripProgress>{};
  final _records = <TripRecord>[];
  final _cancellations = <DateTime>[];
  final _warnings = <WarningEntry>[];
  final _alerts = <DriverAlert>[];
  var _nextAlertId = 1;
  final _pendingChanges = <String, (ConditionChange, Order)>{};
  final _heldRecords = <TripRecord>[];
  final _shipperPaidOn = <String, DateTime>{};

  /// 시연용: 같은 달에 별점을 받은 다른 차주들의 별 개수(가상 값).
  static const sampleOthersStars = [
    12, 10, 9, 8, 7, 6, 6, 5, 5, 4, 4, 3, 3, 3, 2, 2, 1, 1, 1, //
  ];

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
    final sanction = await fetchSanction();
    if (sanction.isSuspended(_now())) {
      throw OrderAcceptException(sanction.message());
    }
    final order = await fetchOrder(id);
    if (order == null || _acceptedIds.contains(id)) {
      throw const OrderAcceptException('이미 다른 차주가 선택했거나 없는 오더예요.');
    }
    // 운송이 끝난 오더도 그날 수락한 건수에 들어간다.
    final sameDay = _orders
        .where((o) =>
            _acceptedIds.contains(o.id) &&
            daysBetween(o.loading.date, order.loading.date) == 0)
        .length;
    if (sameDay >= dailyAcceptLimit) {
      throw const OrderAcceptException(
          '같은 상차일에는 하루 최대 $dailyAcceptLimit건까지 수락할 수 있어요.');
    }
    _acceptedIds.add(id);
    _trips[id] = TripProgress(orderId: id, acceptedAt: _now());
  }

  @override
  Future<DriverSanction> fetchSanction() async {
    final now = _now();
    // 최초 경고 뒤 1년이 지나면 경고 전체를 초기화한다(D14).
    final resetAt = DriverSanction(warnings: _warnings).resetAt;
    if (resetAt != null && !now.isBefore(resetAt)) _warnings.clear();
    final count = _warnings.length;
    if (count == 0) return const DriverSanction();
    final end = suspensionEnd(count, _warnings.last.at);
    return DriverSanction(
        warnings: List.unmodifiable(_warnings),
        suspendedUntil: end,
        permanentReview: end == null);
  }

  void _notify(DriverAlertType type, String title, String body,
      {String? orderId}) {
    _alerts.add(DriverAlert(
      id: 'alert-${_nextAlertId++}',
      type: type,
      title: title,
      body: body,
      createdAt: _now(),
      orderId: orderId,
    ));
  }

  @override
  Future<List<DriverAlert>> fetchAlerts() async =>
      [..._alerts]..sort((a, b) => b.createdAt.compareTo(a.createdAt) != 0
          ? b.createdAt.compareTo(a.createdAt)
          : b.id.compareTo(a.id));

  @override
  Future<void> markAlertsRead() async {
    for (var i = 0; i < _alerts.length; i++) {
      _alerts[i] = _alerts[i].markRead();
    }
  }

  /// 경고 1회를 기록한다. 정지되면 아직 상차하지 않은 배차는 확정을 해제한다(D14).
  Future<void> _addWarning(String reason) async {
    _warnings.add(WarningEntry(at: _now(), reason: reason));
    final sanction = await fetchSanction();
    _notify(DriverAlertType.warning, '경고 ${sanction.warningCount}회가 기록됐어요',
        '$reason. ${sanction.message()}');
    for (final id in [..._acceptedIds]) {
      if (_trips[id]?.status == TripStatus.assigned) {
        final order = (await fetchOrder(id))!;
        _release(id);
        _notify(DriverAlertType.released, '배차 확정이 해제됐어요',
            '오더 수락 정지로 ${order.originRegion} → ${order.destinationRegion} 배차가 풀려 다른 차주에게 다시 배차돼요.',
            orderId: id);
      }
    }
  }

  /// 배차를 풀어 오더 찾기에 다시 올린다.
  void _release(String id) {
    _acceptedIds.remove(id);
    _trips.remove(id);
    _pendingChanges.remove(id);
  }

  @override
  Future<int> cancellationsToday() async =>
      _cancellations.where((c) => daysBetween(c, _now()) == 0).length;

  @override
  Future<void> cancelOrder(String orderId, String reason) async {
    final trip = _tripOrThrow(orderId);
    if (trip.status != TripStatus.assigned) {
      throw const TripActionException('상차를 시작한 뒤에는 취소할 수 없어요. 고객센터로 문의해 주세요.');
    }
    final deadline = cancelDeadline((await fetchOrder(orderId))!, trip.acceptedAt);
    if (!_now().isBefore(deadline)) {
      throw TripActionException(
          '취소 마감(${formatDeadline(deadline)})이 지나 취소할 수 없어요. 고객센터로 문의해 주세요.');
    }
    if (reason.trim().isEmpty) {
      throw const TripActionException('취소 사유를 적어 주세요.');
    }
    _release(orderId);
    _cancellations.add(_now());
  }

  @override
  Future<ConditionChange?> fetchPendingChange(String orderId) async =>
      _pendingChanges[orderId]?.$1;

  @override
  Future<void> respondToChange(String orderId, {required bool accept}) async {
    final pending = _pendingChanges.remove(orderId);
    if (pending == null) {
      throw const TripActionException('답할 조건 변경이 없어요.');
    }
    final (change, updated) = pending;
    // 화주가 바꾼 조건은 거절해도 그대로 남는다(거절하면 배차만 풀린다).
    _orders[_orders.indexWhere((o) => o.id == orderId)] = updated;
    if (accept) return;
    _release(orderId);
    if (!change.refusableWithoutPenalty) {
      await _addWarning('화주의 조건 변경(${change.changes.map((c) => c.label).join('·')})을 거절함');
    }
  }

  /// 시연용: 화주 앱이 없어 화주의 조건 변경을 대신 만든다.
  /// [location]이 true면 하차지를 바꾸고(거절해도 패널티 없음), false면 물량을 바꾼다(거절하면 경고).
  Future<void> simulateConditionChange(String orderId,
      {required bool location}) async {
    final trip = _tripOrThrow(orderId);
    if (trip.status != TripStatus.assigned &&
        trip.status != TripStatus.inTransit) {
      throw const TripActionException('하차 증빙을 보낸 뒤에는 조건을 바꿀 수 없어요.');
    }
    if (_pendingChanges.containsKey(orderId)) {
      throw const TripActionException('이미 답하지 않은 조건 변경이 있어요.');
    }
    final order = (await fetchOrder(orderId))!;
    final (ConditionChange change, Order updated) = location
        ? (
            ConditionChange(
              orderId: orderId,
              changes: [
                FieldChange('하차지', order.destination,
                    '경기 평택시 포승읍 한들로 7 한들사료 창고'),
              ],
              locationChanged: true,
              vehicleTypeChanged: false,
              requestedAt: _now(),
              message: '하차지가 바뀌어 죄송합니다. 운송비는 그대로예요.',
            ),
            order.copyWith(
                destination: '경기 평택시 포승읍 한들로 7 한들사료 창고',
                destinationRegion: '경기 평택'),
          )
        : (
            ConditionChange(
              orderId: orderId,
              changes: [FieldChange('물량', order.quantity, '벌크 20톤')],
              locationChanged: false,
              vehicleTypeChanged: false,
              requestedAt: _now(),
            ),
            order.copyWith(quantity: '벌크 20톤', weightKg: 20000),
          );
    _pendingChanges[orderId] = (change, updated);
    _notify(
        DriverAlertType.conditionChanged,
        '화주가 조건을 바꿨어요',
        '${order.originRegion} → ${order.destinationRegion}: '
            '${change.changes.map((c) => '${c.label} ${c.after}').join(', ')}. 운행 화면에서 수락하거나 거절해 주세요.',
        orderId: orderId);
  }

  @override
  Future<List<TripRecord>> fetchTripRecords() async =>
      [..._records]..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<TripProgress?> fetchTrip(String orderId) async => _trips[orderId];

  TripProgress _tripOrThrow(String orderId) {
    final trip = _trips[orderId];
    if (trip == null) {
      throw const TripActionException('내가 수락한 오더가 아니에요.');
    }
    return trip;
  }

  @override
  Future<void> uploadLoadingProof(String orderId, String photoPath) async {
    final trip = _tripOrThrow(orderId);
    if (trip.status != TripStatus.assigned) {
      throw const TripActionException('이미 상차 계근표를 올렸어요.');
    }
    _trips[orderId] = trip.copyWith(
        status: TripStatus.inTransit,
        loadingProofPath: photoPath,
        loadedAt: _now());
  }

  @override
  Future<void> uploadUnloadingProof(
      String orderId, String photoPath, UnloadingProofKind kind) async {
    final trip = _tripOrThrow(orderId);
    if (trip.status == TripStatus.assigned) {
      throw const TripActionException('상차 계근표를 먼저 올려 주세요.');
    }
    if (trip.status != TripStatus.inTransit) {
      throw const TripActionException('이미 하차 증빙을 보냈어요.');
    }
    _trips[orderId] = trip.copyWith(
        status: TripStatus.awaitingConfirmation,
        unloadingProofPath: photoPath,
        unloadingProofKind: kind,
        unloadingSubmittedAt: _now());
  }

  /// 시연용: 화주 앱이 없어 화주의 예/아니오 응답을 대신한다. 실제 서버 연결 뒤에는 쓰지 않는다.
  /// ‘예’면 운송 완료로 바꾸고 운행 기록을 만든다(별점은 화주가 나중에 줌). ‘아니오’면 고객센터 확인 중.
  Future<void> simulateShipperResponse(String orderId,
      {required bool confirmed}) async {
    final trip = _tripOrThrow(orderId);
    if (trip.status != TripStatus.awaitingConfirmation) {
      throw const TripActionException('화주 확인을 기다리는 운행이 아니에요.');
    }
    _trips[orderId] = trip.copyWith(
        status: confirmed ? TripStatus.completed : TripStatus.disputed,
        confirmedAt: _now());
    final order = (await fetchOrder(orderId))!;
    final route = '${order.originRegion} → ${order.destinationRegion}';
    if (!confirmed) {
      _heldRecords.add(_recordOf(order));
      _notify(DriverAlertType.proofRejected, '화주가 하차 증빙에 ‘아니오’라고 답했어요',
          '$route: 고객센터가 확인하고 있어요. 안내를 기다려 주세요.',
          orderId: orderId);
      return;
    }
    _notify(DriverAlertType.proofConfirmed, '화주가 하차 증빙을 확인했어요',
        '$route 운송이 끝났어요. 운행 기록에서 볼 수 있어요.',
        orderId: orderId);
    _records.add(_recordOf(order));
  }

  TripRecord _recordOf(Order order) => TripRecord(
        orderId: order.id,
        date: dateOnly(_now()),
        originRegion: order.originRegion,
        destinationRegion: order.destinationRegion,
        itemLabel: order.itemLabel,
        quantity: order.quantity,
        fare: order.estimatedFare,
      );

  MonthlyRanking _rankingOf(DateTime month) {
    final stars = _records
        .where((r) =>
            r.ratedAt != null &&
            r.ratedAt!.year == month.year &&
            r.ratedAt!.month == month.month)
        .fold<int>(0, (sum, r) => sum + r.rating!);
    return MonthlyRanking(
        month: DateTime(month.year, month.month),
        myStars: stars,
        othersStars: sampleOthersStars);
  }

  @override
  Future<MonthlyRanking> fetchRanking() async => _rankingOf(_now());

  @override
  Future<List<SettlementItem>> fetchSettlements() async {
    final now = _now();
    final today = dateOnly(now);
    SettlementItem item(TripRecord r, {bool held = false}) {
      final ranking = _rankingOf(r.date);
      final paidOn = _shipperPaidOn[r.orderId];
      final payoutOn = paidOn == null ? null : payoutDateFor(paidOn);
      return SettlementItem(
        record: r,
        status: held
            ? SettlementStatus.held
            : payoutOn == null
                ? SettlementStatus.awaitingShipper
                : today.isBefore(payoutOn)
                    ? SettlementStatus.scheduled
                    : SettlementStatus.paid,
        feePerMille: ranking.feePerMille,
        rateFinal: !now.isBefore(nextRankingReset(ranking.month)),
        shipperPaidOn: held ? null : paidOn,
        payoutOn: held ? null : payoutOn,
      );
    }

    return [
      for (final r in _records) item(r),
      for (final r in _heldRecords) item(r, held: true),
    ]..sort((a, b) => b.record.date.compareTo(a.record.date));
  }

  /// 시연용: 화주 앱이 없어 화주의 별점(1~5개)을 대신 준다. 운송 완료 건에 한 번만.
  Future<void> simulateShipperRating(String orderId, int stars) async {
    if (stars < 1 || stars > 5) {
      throw const TripActionException('별점은 1~5개예요.');
    }
    final i = _records.indexWhere((r) => r.orderId == orderId);
    if (i < 0) throw const TripActionException('운송이 끝난 오더에만 별점을 줄 수 있어요.');
    if (_records[i].rating != null) {
      throw const TripActionException('이미 별점을 받은 오더예요.');
    }
    _records[i] = _records[i].rated(stars, _now());
  }

  /// 시연용: 화주가 운송비를 정산(입금)한 것으로 한다. 오늘이 화주 정산일이 된다.
  Future<void> simulateShipperPayment(String orderId) async {
    if (!_records.any((r) => r.orderId == orderId)) {
      throw const TripActionException('운송이 끝난 오더만 정산할 수 있어요.');
    }
    _shipperPaidOn.putIfAbsent(orderId, () => dateOnly(_now()));
  }

  @override
  Future<List<Order>> fetchMyOrders() async {
    final mine = [
      for (final o in _orders)
        if (_acceptedIds.contains(o.id) &&
            _trips[o.id]?.status != TripStatus.completed)
          o,
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
