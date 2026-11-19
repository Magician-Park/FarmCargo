import 'package:farm_cargo/features/orders/driver_alert.dart';
import 'package:farm_cargo/features/orders/order_policy.dart';
import 'package:farm_cargo/features/orders/order_repository.dart';
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
}
