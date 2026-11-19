import 'package:farm_cargo/features/orders/driver_alert.dart';
import 'package:farm_cargo/features/orders/order_policy.dart';
import 'package:farm_cargo/features/orders/order_repository.dart';
import 'package:farm_cargo/features/orders/settlement.dart';
import 'package:farm_cargo/features/orders/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final thursday9 = DateTime(2026, 11, 12, 9); // 목요일 오전 9시

  group('취소 마감(D04)', () {
    test('다음 날 이후 상차면 상차일 전날 15시', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      final soy = (await repo.fetchOrder('order-1'))!; // 내일(금) 상차
      expect(cancelDeadline(soy, thursday9), DateTime(2026, 11, 12, 15));
      final palm = (await repo.fetchOrder('order-6'))!; // 일요일 상차
      expect(cancelDeadline(palm, thursday9), DateTime(2026, 11, 14, 15));
    });

    test('당일 배차(수락한 날 바로 상차)는 상차일 오전 9시', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      final wheat = (await repo.fetchOrder('order-3'))!; // 오늘 상차
      expect(cancelDeadline(wheat, DateTime(2026, 11, 12, 7)),
          DateTime(2026, 11, 12, 9));
    });

    test('마감 시각 표시', () {
      expect(formatDeadline(DateTime(2026, 11, 12, 15)), '11월 12일(목) 15:00');
    });
  });

  group('정지 기간(D14)', () {
    test('영업일은 일요일만 빼고 센다', () {
      final saturday14 = DateTime(2026, 11, 14, 14);
      expect(addBusinessDays(saturday14, 1), DateTime(2026, 11, 16, 14)); // 일요일 건너뜀
      final monday14 = DateTime(2026, 11, 16, 14);
      expect(addBusinessDays(monday14, 7), DateTime(2026, 11, 24, 14));
    });

    test('1회 24시간(일요일 포함), 2회 7영업일, 3회 30영업일, 4회부터 영구 정지 심사', () {
      final saturday14 = DateTime(2026, 11, 14, 14);
      expect(suspensionEnd(1, saturday14), DateTime(2026, 11, 15, 14));
      expect(suspensionEnd(2, saturday14), addBusinessDays(saturday14, 7));
      expect(suspensionEnd(3, saturday14), addBusinessDays(saturday14, 30));
      expect(suspensionEnd(4, saturday14), isNull);
    });
  });

  group('취소', () {
    test('마감 전이고 사유가 있으면 취소되어 오더 찾기로 돌아간다', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      await repo.acceptOrder('order-1');
      await expectLater(
          repo.cancelOrder('order-1', '  '), throwsA(isA<TripActionException>()));
      await repo.cancelOrder('order-1', '차량 고장');
      expect(await repo.fetchMyOrders(), isEmpty);
      expect((await repo.fetchJobPosts()).map((o) => o.id), contains('order-1'));
      expect(await repo.cancellationsToday(), 1);
      expect((await repo.fetchSanction()).warningCount, 0); // 경고는 관리자가 판단
    });

    test('마감이 지났거나 상차를 시작했으면 취소할 수 없다', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      await repo.acceptOrder('order-3'); // 당일 배차: 마감 9시 = 지금
      await expectLater(repo.cancelOrder('order-3', '사유'),
          throwsA(isA<TripActionException>()));

      await repo.acceptOrder('order-1');
      await repo.uploadLoadingProof('order-1', '/l.jpg');
      await expectLater(repo.cancelOrder('order-1', '사유'),
          throwsA(isA<TripActionException>()));
    });
  });

  group('조건 변경(D04)', () {
    test('수락하면 바뀐 조건으로 운행한다', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      await repo.acceptOrder('order-1');
      await repo.simulateConditionChange('order-1', location: false);
      final change = (await repo.fetchPendingChange('order-1'))!;
      expect(change.refusableWithoutPenalty, isFalse);
      await repo.respondToChange('order-1', accept: true);
      expect((await repo.fetchOrder('order-1'))!.quantity, '벌크 20톤');
      expect(await repo.fetchPendingChange('order-1'), isNull);
      expect((await repo.fetchMyOrders()).single.id, 'order-1');
    });

    test('하차지 변경은 패널티 없이 거절할 수 있고 배차가 풀린다', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      await repo.acceptOrder('order-1');
      await repo.simulateConditionChange('order-1', location: true);
      expect((await repo.fetchPendingChange('order-1'))!.refusableWithoutPenalty,
          isTrue);
      await repo.respondToChange('order-1', accept: false);
      expect(await repo.fetchMyOrders(), isEmpty);
      expect((await repo.fetchSanction()).warningCount, 0);
      // 거절해도 화주가 바꾼 하차지는 남는다
      expect((await repo.fetchOrder('order-1'))!.destinationRegion, '경기 평택');
    });

    test('그 밖의 거절은 경고 1회: 24시간 수락 정지, 상차 전 배차는 확정 해제', () async {
      var now = thursday9;
      final repo = MockOrderRepository(now: () => now);
      await repo.acceptOrder('order-1');
      await repo.acceptOrder('order-4'); // 상차 전 배차
      await repo.acceptOrder('order-5');
      await repo.uploadLoadingProof('order-5', '/l.jpg'); // 운송 중
      await repo.simulateConditionChange('order-1', location: false);
      await repo.respondToChange('order-1', accept: false);

      final sanction = await repo.fetchSanction();
      expect(sanction.warningCount, 1);
      expect(sanction.suspendedUntil, DateTime(2026, 11, 13, 9));
      expect(sanction.isSuspended(now), isTrue);
      // 상차 전이던 order-4는 풀리고, 운송 중인 order-5는 남는다
      expect((await repo.fetchMyOrders()).map((o) => o.id), ['order-5']);
      await expectLater(
          repo.acceptOrder('order-6'),
          throwsA(isA<OrderAcceptException>()
              .having((e) => e.message, 'message', contains('수락할 수 없어요'))));

      now = DateTime(2026, 11, 13, 9); // 24시간 뒤
      expect((await repo.fetchSanction()).isSuspended(now), isFalse);
      await repo.acceptOrder('order-6');
    });
  });

  group('알림·경고 내역', () {
    test('조건 변경·경고·배차 해제·증빙 결과가 알림으로 쌓이고 모두 읽음으로 바꿀 수 있다', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      await repo.acceptOrder('order-1');
      await repo.acceptOrder('order-4'); // 상차 전 → 경고로 풀릴 배차
      await repo.acceptOrder('order-5');
      await repo.uploadLoadingProof('order-5', '/l.jpg');
      await repo.uploadUnloadingProof(
          'order-5', '/u.jpg', UnloadingProofKind.weighTicket);
      await repo.simulateShipperResponse('order-5', confirmed: true);
      await repo.simulateConditionChange('order-1', location: false);
      await repo.respondToChange('order-1', accept: false);

      final alerts = await repo.fetchAlerts();
      final types = alerts.map((a) => a.type).toSet();
      expect(types, {
        DriverAlertType.proofConfirmed,
        DriverAlertType.conditionChanged,
        DriverAlertType.warning,
        DriverAlertType.released,
      });
      expect(alerts.where((a) => a.type == DriverAlertType.released).single.orderId,
          'order-4');
      expect(alerts.every((a) => !a.read), isTrue);
      await repo.markAlertsRead();
      expect((await repo.fetchAlerts()).every((a) => a.read), isTrue);

      final sanction = await repo.fetchSanction();
      expect(sanction.warnings.single.reason, contains('물량'));
      expect(sanction.resetAt, DateTime(2027, 11, 12, 9));
    });

    test('증빙 아니오도 알림으로 온다', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      await repo.acceptOrder('order-1');
      await repo.uploadLoadingProof('order-1', '/l.jpg');
      await repo.uploadUnloadingProof(
          'order-1', '/u.jpg', UnloadingProofKind.weighTicket);
      await repo.simulateShipperResponse('order-1', confirmed: false);
      expect((await repo.fetchAlerts()).single.type, DriverAlertType.proofRejected);
    });
  });

  group('정산·별점 랭킹(D09·D17)', () {
    test('지급일은 화주 정산일 10일 뒤, 은행 휴일이면 그 전 은행 영업일', () {
      expect(payoutDateFor(DateTime(2026, 11, 2)), DateTime(2026, 11, 12));
      // 11월 15일은 일요일 → 13일(금)
      expect(payoutDateFor(DateTime(2026, 11, 5)), DateTime(2026, 11, 13));
      expect(
          payoutDateFor(DateTime(2026, 11, 2), holidays: {DateTime(2026, 11, 12)}),
          DateTime(2026, 11, 11));
    });

    test('수수료는 부가세 포함 운송비에 매기고 1원 미만 반올림', () {
      expect(vatOf(350000), 35000);
      expect(feeOf(385000, baseFeePerMille), 15400);
      expect(feeOf(385000, top10FeePerMille), 13475);
      expect(feeOf(100, top10FeePerMille), 4); // 3.5원 → 4원
      expect(feeOf(12345, top10FeePerMille), 432); // 432.075원
      expect(feeRateLabel(35), '3.5%');
      expect(feeRateLabel(40), '4%');
    });

    test('5%·10% 인원은 올림, 별이 같으면 공동 순위', () {
      expect(topCount(20, 5), 1);
      expect(topCount(20, 10), 2);
      expect(topCount(21, 5), 2);
      expect(topCount(1, 10), 1);
      expect(topCount(0, 5), 0);
      expect(competitionRank(10, [12, 10, 9]), 2);
      expect(feePerMilleFor(null, 20), baseFeePerMille);
      expect(feePerMilleFor(1, 20), top5FeePerMille);
      expect(feePerMilleFor(2, 20), top10FeePerMille);
      expect(feePerMilleFor(3, 20), baseFeePerMille);
      // 4명이면 5%·10% 모두 올림해 1명 → 공동 2위는 감면 밖
      final r = MonthlyRanking(
          month: DateTime(2026, 11), myStars: 10, othersStars: [12, 10, 9]);
      expect(r.rank, 2);
      expect(r.rankedCount, 4);
      expect(r.feePerMille, baseFeePerMille);
    });

    test('운송 완료 → 화주 정산 대기 → 지급 예정 → 지급 완료, 별점은 한 번만', () async {
      var now = thursday9;
      final repo = MockOrderRepository(now: () => now);
      await repo.acceptOrder('order-5');
      await repo.uploadLoadingProof('order-5', '/l.jpg');
      await repo.uploadUnloadingProof(
          'order-5', '/u.jpg', UnloadingProofKind.weighTicket);
      await repo.simulateShipperResponse('order-5', confirmed: true);

      var item = (await repo.fetchSettlements()).single;
      expect(item.status, SettlementStatus.awaitingShipper);
      expect(item.feePerMille, baseFeePerMille);
      expect(item.rateFinal, isFalse);
      expect(item.total, item.supply + vatOf(item.supply));
      expect(item.payout, item.total - feeOf(item.total, 40));
      expect((await repo.fetchRanking()).isRanked, isFalse);

      await repo.simulateShipperRating('order-5', 5);
      expect(() => repo.simulateShipperRating('order-5', 3),
          throwsA(isA<TripActionException>()));
      final ranking = await repo.fetchRanking();
      expect(ranking.myStars, 5);
      expect(ranking.rankedCount, 20);
      expect(ranking.rank, 8);
      expect((await repo.fetchTripRecords()).single.rating, 5);

      await repo.simulateShipperPayment('order-5');
      item = (await repo.fetchSettlements()).single;
      expect(item.status, SettlementStatus.scheduled);
      expect(item.shipperPaidOn, DateTime(2026, 11, 12));
      expect(item.payoutOn, DateTime(2026, 11, 20)); // 22일(일) → 20일(금)

      now = DateTime(2026, 11, 20, 8);
      expect((await repo.fetchSettlements()).single.status, SettlementStatus.paid);
      now = DateTime(2026, 12, 1);
      final next = await repo.fetchSettlements();
      expect(next.single.rateFinal, isTrue);
      expect((await repo.fetchRanking()).myStars, 0); // 매월 1일 0시 초기화
    });

    test('별점이 많으면 그 달 정산 수수료율이 낮아지고, 화주 아니오는 지급 보류', () async {
      final repo = MockOrderRepository(now: () => thursday9);
      for (final id in ['order-1', 'order-5', 'order-3']) {
        await repo.acceptOrder(id);
        await repo.uploadLoadingProof(id, '/l.jpg');
        await repo.uploadUnloadingProof(id, '/u.jpg', UnloadingProofKind.weighTicket);
      }
      await repo.simulateShipperResponse('order-1', confirmed: true);
      await repo.simulateShipperResponse('order-5', confirmed: true);
      await repo.simulateShipperResponse('order-3', confirmed: false);
      await repo.simulateShipperRating('order-1', 5);
      await repo.simulateShipperRating('order-5', 5); // 10개 → 2위(공동)
      expect((await repo.fetchRanking()).feePerMille, top10FeePerMille);
      final items = await repo.fetchSettlements();
      expect(items.where((s) => s.status == SettlementStatus.held).single.record.orderId,
          'order-3');
      expect(items.every((s) => s.feePerMille == top10FeePerMille), isTrue);
    });
  });
}
