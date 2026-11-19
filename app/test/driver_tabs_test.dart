import 'package:farm_cargo/core/router/app_router.dart';
import 'package:farm_cargo/features/auth/auth_provider.dart';
import 'package:farm_cargo/features/driver/my_orders_screen.dart';
import 'package:farm_cargo/features/driver/settlement_screen.dart';
import 'package:farm_cargo/features/orders/order_repository.dart';
import 'package:farm_cargo/features/orders/orders_providers.dart';
import 'package:farm_cargo/features/orders/trip.dart';
import 'package:farm_cargo/features/orders/trip_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<ProviderContainer> loginDriver(WidgetTester tester) async {
  final container = await pumpApp(tester);
  await container
      .read(authProvider.notifier)
      .signIn(phone: '01011112222', password: 'Passw0rd!');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('차주 하단 메뉴는 홈·오더 찾기·내 오더·정산·설정 5칸이다', (tester) async {
    await loginDriver(tester);
    final nav = find.byType(NavigationBar);
    for (final label in ['홈', '오더 찾기', '내 오더', '정산', '설정']) {
      expect(find.descendant(of: nav, matching: find.text(label)), findsOneWidget);
    }
  });

  testWidgets('오더 찾기: 거리 필터와 정렬, 배지가 보인다', (tester) async {
    await loginDriver(tester);
    await openDriverTab(tester, '오더 찾기');

    expect(find.text('올라온 오더 6건'), findsOneWidget);
    expect(find.text('충남 천안시 (데모)'), findsOneWidget);
    expect(find.text('당상'), findsWidgets); // 오늘 상차
    expect(find.text('빠른 상차순'), findsOneWidget);

    await tester.tap(find.text('30km 주변'));
    await tester.pumpAndSettle();
    expect(find.text('올라온 오더 2건'), findsOneWidget);
    await tester.tap(find.text('50km 주변'));
    await tester.pumpAndSettle();
    expect(find.text('올라온 오더 4건'), findsOneWidget);
    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();

    // 정렬을 높은 운송비순으로 바꾸면 가장 비싼 오더(옥수수 43만 원)가 맨 위
    await tester.tap(find.text('빠른 상차순'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('높은 운송비순').last);
    await tester.pumpAndSettle();
    final firstItem = tester.getTopLeft(find.text('옥수수 · 외국산')).dy;
    final secondItem = tester.getTopLeft(find.text('대두박 · 외국산')).dy;
    expect(firstItem, lessThan(secondItem));
  });

  testWidgets('오더를 수락하면 내 오더로 가고, 오더 찾기에서는 빠진다', (tester) async {
    await loginDriver(tester);
    await openDriverTab(tester, '내 오더');
    expect(find.textContaining('아직 수락한 오더가 없어요'), findsOneWidget);
    expect(find.text('오늘(11월 12일(목)) 상차할 운송 건은 0건이에요'), findsOneWidget);

    await openDriverTab(tester, '오더 찾기');
    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();
    await tapText(tester, '이 오더 수락하기');

    expect(find.text('오더 내역'), findsOneWidget); // 내 오더 화면
    expect(find.text('소맥피 · 외국산'), findsOneWidget);
    expect(find.text('오늘(11월 12일(목)) 상차할 운송 건은 1건이에요'), findsOneWidget);

    // 내 오더의 오더를 누르면 운행 화면으로 간다
    expect(find.text('상차 전'), findsOneWidget);
    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();
    expect(find.text('상차 계근표 올리기'), findsWidgets);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await openDriverTab(tester, '오더 찾기');
    expect(find.text('올라온 오더 5건'), findsOneWidget);
    expect(find.text('소맥피 · 외국산'), findsNothing);

    // 운행 기록 탭은 기간을 고를 수 있고 지금은 비어 있다
    await openDriverTab(tester, '내 오더');
    await tester.tap(find.text('운행 기록'));
    await tester.pumpAndSettle();
    expect(find.text('2026.11.12 ~ 2026.11.12'), findsOneWidget);
    await tester.tap(find.text('1개월'));
    await tester.pumpAndSettle();
    expect(find.text('2026.10.12 ~ 2026.11.12'), findsOneWidget);
    expect(find.text('이 기간에 표시할 운행 기록이 없어요.'), findsOneWidget);
  });

  testWidgets('정산과 설정 화면', (tester) async {
    await loginDriver(tester);
    await openDriverTab(tester, '정산');
    expect(find.text('지급 완료 운송비'), findsOneWidget);
    expect(find.text('0원'), findsNWidgets(2));
    expect(find.text('2026.11.01 ~ 2026.11.12'), findsOneWidget); // 당월
    expect(find.textContaining('수수료 4%'), findsOneWidget);

    await openDriverTab(tester, '설정');
    expect(find.text('김기사님'), findsOneWidget);
    expect(find.text('일반 카고(25톤)'), findsOneWidget);
    for (final item in [
      '회원 가입 서류 변경',
      '알림 설정',
      '비밀번호 재설정',
      '고객센터 전화',
      '약관 및 정책',
      '앱 버전',
      '로그아웃',
    ]) {
      await tester.scrollUntilVisible(find.text(item), 100);
      expect(find.text(item), findsOneWidget, reason: item);
    }
    await tester.scrollUntilVisible(find.text('고객센터 전화'), -100);
    await tapText(tester, '고객센터 전화');
    expect(find.textContaining('24시간'), findsOneWidget);
    await tapText(tester, '확인');
  });

  testWidgets('로그아웃 후 다른 차주가 로그인하면 이전 차주의 수락 내역이 보이지 않는다', (tester) async {
    final container = await loginDriver(tester);
    await openDriverTab(tester, '오더 찾기');
    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();
    await tapText(tester, '이 오더 수락하기');
    expect(find.text('소맥피 · 외국산'), findsOneWidget);

    container.read(authProvider.notifier).logout();
    await tester.pumpAndSettle();
    await container
        .read(authProvider.notifier)
        .signIn(phone: '01011112222', password: 'Passw0rd!');
    await tester.pumpAndSettle();
    await openDriverTab(tester, '내 오더');
    expect(find.textContaining('아직 수락한 오더가 없어요'), findsOneWidget);
  });

  testWidgets('설정에서 선호 구간을 등록하면 오더 찾기에서 그 구간 오더만 볼 수 있다', (tester) async {
    await loginDriver(tester);
    await openDriverTab(tester, '오더 찾기');
    await tester.tap(find.text('선호 구간만'));
    await tester.pumpAndSettle();
    expect(find.textContaining('등록한 선호 구간이 없어요'), findsOneWidget);

    await openDriverTab(tester, '설정');
    await tester.scrollUntilVisible(find.text('선호 구간 설정'), 100);
    await tester.tap(find.text('선호 구간 설정'));
    await tester.pumpAndSettle();
    expect(bottomButtonEnabled(tester, '구간 추가'), isFalse);
    await tester.tap(find.text('상차 지역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('인천').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('하차 지역'));
    await tester.pumpAndSettle();
    // 드롭다운 목록 아래쪽에 있어 스크롤해서 고른다.
    await tester.scrollUntilVisible(find.text('충남'), 48,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('충남').last);
    await tester.pumpAndSettle();
    await tapText(tester, '구간 추가');
    expect(find.text('인천 → 충남'), findsOneWidget);
    expect(find.text('등록한 구간 1개'), findsOneWidget);

    await openDriverTab(tester, '오더 찾기');
    expect(find.text('올라온 오더 1건'), findsOneWidget); // 인천 서구 → 충남 당진
    expect(find.text('소맥피 · 외국산'), findsOneWidget);
    await tester.tap(find.text('선호 구간만'));
    await tester.pumpAndSettle();
    expect(find.text('올라온 오더 6건'), findsOneWidget);
  });

  testWidgets('정산 상태는 화주 정산 대기·지급 예정·지급 완료·지급 보류다', (tester) async {
    await loginDriver(tester);
    await openDriverTab(tester, '정산');
    for (final s in ['전체', '화주 정산 대기', '지급 예정', '지급 완료', '지급 보류']) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
  });

  testWidgets('운행 기록 카드: 날짜·구간·품목·물량·운송비·별점', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          TripRecordCard(
            record: TripRecord(
              orderId: 'x',
              date: DateTime(2026, 11, 10),
              originRegion: '인천 서구',
              destinationRegion: '충남 당진',
              itemLabel: '소맥피 · 외국산',
              quantity: '벌크 24톤',
              fare: 300000,
              rating: 4,
            ),
          ),
          TripRecordCard(
            record: TripRecord(
              orderId: 'y',
              date: DateTime(2026, 11, 11),
              originRegion: '충남 천안',
              destinationRegion: '전북 익산',
              itemLabel: '대두박 · 외국산',
              quantity: '20톤',
              fare: 350000,
            ),
          ),
        ]),
      ),
    ));
    expect(find.text('11월 10일(화)'), findsOneWidget);
    expect(find.text('인천 서구 → 충남 당진'), findsOneWidget);
    expect(find.text('소맥피 · 외국산 · 벌크 24톤'), findsOneWidget);
    expect(find.text('300,000원'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.text('별점 대기'), findsOneWidget);
  });

  // 아래 두 테스트는 화주 화면 보관(2026-11-19) 때 shipper_request_test.dart에서 옮겨 왔다.
  testWidgets('차주 홈의 추천 맞춤 오더를 열고 상세 화면으로 이동한다', (tester) async {
    final container = await pumpApp(tester);
    await container
        .read(authProvider.notifier)
        .signIn(phone: '01011112222', password: 'Passw0rd!');
    await tester.pumpAndSettle();

    expect(find.text('추천 맞춤 오더'), findsOneWidget);
    expect(find.text('오더 상세'), findsNothing);
    // 목록에서부터 화주 이름과 상세 주소가 보인다(D06)
    expect(find.text('화주 한들영농조합'), findsOneWidget);
    await tester.tap(find.text('상차 전북 김제시 죽산면 한들로 12 한들영농조합 창고'));
    await tester.pumpAndSettle();

    expect(find.text('오더 상세'), findsOneWidget);
    expect(find.text('운송비 단가'), findsOneWidget);
    expect(find.text('건당 270,000원'), findsOneWidget);
    expect(find.text('부가세 별도'), findsOneWidget);
    expect(find.text('상차  11월 13일(금) 07:00~09:00'), findsOneWidget);
    expect(find.textContaining('수수료 4%'), findsOneWidget);
    expect(find.textContaining('5%'), findsNothing); // 이전 샘플 문구가 남지 않음
  });

  testWidgets('오더 찾기 탭에는 게시글 형식으로 오더가 나열되고 상세에서 돌아오면 같은 탭이다', (tester) async {
    final container = await pumpApp(tester);
    await container
        .read(authProvider.notifier)
        .signIn(phone: '01011112222', password: 'Passw0rd!');
    await tester.pumpAndSettle();

    final tab = find.descendant(
        of: find.byType(NavigationBar), matching: find.text('오더 찾기'));
    await tester.tap(tab);
    await tester.pumpAndSettle();
    expect(find.text('올라온 오더 6건'), findsOneWidget);
    expect(find.text('추천 맞춤 오더'), findsNothing);
    expect(find.text('소맥피 · 외국산'), findsOneWidget); // 빠른 상차순 첫 오더

    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();
    expect(find.text('오더 상세'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('올라온 오더 6건'), findsOneWidget);

    // 목록 아래쪽의 게시글도 상세로 열린다
    await tester.scrollUntilVisible(find.text('팜박 · 외국산'), 300);
    await tester.ensureVisible(find.text('팜박 · 외국산'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('팜박 · 외국산'));
    await tester.pumpAndSettle();
    expect(find.text('오더 상세'), findsOneWidget);
    expect(find.text('kg당 16원'), findsOneWidget);
    expect(find.text('카고'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 홈 탭으로 돌아가면 추천 맞춤 오더가 보인다
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('홈')));
    await tester.pumpAndSettle();
    expect(find.text('추천 맞춤 오더'), findsOneWidget);
  });

  testWidgets('운행: 상차 계근표 → 하차 증빙 → 화주 확인(시연) → 운송 완료 → 운행 기록', (tester) async {
    await loginDriver(tester);
    await openDriverTab(tester, '오더 찾기');
    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();
    await tapText(tester, '이 오더 수락하기');
    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();

    // 2단계: 상차 계근표. 사진을 찍기 전에는 올릴 수 없다
    expect(bottomButtonEnabled(tester, '상차 계근표 올리기'), isFalse);
    await tapText(tester, '촬영');
    expect(find.byKey(const ValueKey('preview:/fake/photo.jpg')), findsOneWidget);
    await tapText(tester, '상차 계근표 올리기');
    await tester.scrollUntilVisible(find.text('운송 중'), -100);
    expect(find.text('운송 중'), findsOneWidget);
    expect(find.text('상차 계근표 올림'), findsOneWidget);

    // 3단계: 하차 증빙. 계근표가 없으면 공장 직원 서명으로 바꿀 수 있다
    await tester.tap(find.text('공장 직원 서명'));
    await tester.pumpAndSettle();
    expect(find.text('직원이 서명한 종이를 촬영해 주세요'), findsOneWidget);
    await tapText(tester, '촬영');
    await tapText(tester, '하차 증빙 보내기');
    expect(find.textContaining('화주가 하차 증빙을 확인하고 있어요'), findsOneWidget);
    expect(find.text('공장 직원 서명 올림'), findsOneWidget);
    expect(find.textContaining('1시간 10분'), findsOneWidget);

    // 시연용 화주 응답: 예 → 운송 완료
    await tester.scrollUntilVisible(find.text('화주: 예'), 100);
    await tapText(tester, '화주: 예');
    expect(find.text('운송 완료'), findsWidgets);
    expect(find.text('화주: 예'), findsNothing);

    // 내 오더에서는 빠지고 운행 기록에 생긴다
    await tester.scrollUntilVisible(find.text('내 오더로 가기'), 100);
    await tapText(tester, '내 오더로 가기');
    expect(find.textContaining('아직 수락한 오더가 없어요'), findsOneWidget);
    await tester.tap(find.text('운행 기록'));
    await tester.pumpAndSettle();
    expect(find.text('검색 결과 1건'), findsOneWidget);
    expect(find.text('인천 서구 → 충남 당진'), findsOneWidget);
    expect(find.text('300,000원'), findsOneWidget);
    expect(find.text('별점 대기'), findsOneWidget);
  });

  testWidgets('운행: 화주가 아니오라고 하면 고객센터 확인 중이 된다', (tester) async {
    await loginDriver(tester);
    await openDriverTab(tester, '오더 찾기');
    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();
    await tapText(tester, '이 오더 수락하기');
    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();
    await tapText(tester, '촬영');
    await tapText(tester, '상차 계근표 올리기');
    await tapText(tester, '촬영');
    await tapText(tester, '하차 증빙 보내기');
    await tester.scrollUntilVisible(find.text('화주: 아니오'), 100);
    await tester.tap(find.text('화주: 아니오'));
    await tester.pumpAndSettle();
    expect(find.text('고객센터 확인 중'), findsOneWidget);
    expect(find.textContaining('고객센터가 확인하고 있어요'), findsOneWidget);
    expect(find.text('화주: 예'), findsNothing);
  });

  /// 오더 상세로 바로 가서 수락한 뒤, 내 오더에서 운행 화면을 연다.
  Future<void> openAcceptedTrip(WidgetTester tester, ProviderContainer container,
      String orderId, String itemLabel) async {
    container.read(routerProvider).push(AppRoutes.driverOrder(orderId));
    await tester.pumpAndSettle();
    await tapText(tester, '이 오더 수락하기');
    await tester.tap(find.text(itemLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('배차 취소: 마감 안내, 사유 필수, 취소하면 오더 찾기로 돌아간다', (tester) async {
    final container = await loginDriver(tester);
    await openAcceptedTrip(tester, container, 'order-1', '대두 · 국산'); // 내일 상차 → 오늘 15시 마감

    await tester.scrollUntilVisible(find.text('배차 취소'), 100);
    expect(find.text('취소 마감: 11월 12일(목) 15:00까지'), findsOneWidget);
    await tapText(tester, '배차 취소');
    expect(find.text('배차를 취소할까요?'), findsOneWidget);
    final cancelButton = find.widgetWithText(TextButton, '취소하기');
    expect(tester.widget<TextButton>(cancelButton).onPressed, isNull); // 사유 전
    await tester.enterText(find.byType(TextField), '차량 고장');
    await tester.pump();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('오더 내역'), findsOneWidget);
    expect(find.textContaining('아직 수락한 오더가 없어요'), findsOneWidget);
    await openDriverTab(tester, '오더 찾기');
    expect(find.text('올라온 오더 6건'), findsOneWidget);
  });

  testWidgets('당일 배차는 오전 9시가 지나면 취소할 수 없다', (tester) async {
    final container = await loginDriver(tester); // 지금 = 목요일 오전 9시
    await openAcceptedTrip(tester, container, 'order-3', '소맥피 · 외국산'); // 오늘 상차
    await tester.scrollUntilVisible(find.text('배차 취소'), 100);
    expect(find.textContaining('이 지나 취소할 수 없어요'), findsOneWidget);
    final button = find.ancestor(
        of: find.text('배차 취소'), matching: find.byType(OutlinedButton));
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
  });

  testWidgets('조건 변경: 물량 변경을 거절하면 경고 1회와 수락 정지 안내가 보인다', (tester) async {
    final container = await loginDriver(tester);
    await openAcceptedTrip(tester, container, 'order-1', '대두 · 국산');
    await tester.scrollUntilVisible(find.text('화주: 물량 변경'), 100);
    await tapText(tester, '화주: 물량 변경');
    await tester.scrollUntilVisible(find.text('화주가 조건을 바꿨어요'), -100);
    expect(find.text('→ 벌크 20톤'), findsOneWidget);
    expect(find.text('이 변경을 거절하면 경고 1회로 기록돼요.'), findsOneWidget);

    await tapText(tester, '거절');
    expect(find.textContaining('경고 1회로 기록되고'), findsOneWidget);
    await tapText(tester, '거절하기');
    expect(find.text('오더 내역'), findsOneWidget);

    await openDriverTab(tester, '오더 찾기');
    expect(find.textContaining('경고 1회로 11월 13일(금) 09:00까지 오더를 수락할 수 없어요.'),
        findsOneWidget);
  });

  testWidgets('조건 변경: 하차지 변경은 수락하면 바뀐 하차지로 운행한다', (tester) async {
    final container = await loginDriver(tester);
    await openAcceptedTrip(tester, container, 'order-1', '대두 · 국산');
    await tester.scrollUntilVisible(find.text('화주: 하차지 변경'), 100);
    await tapText(tester, '화주: 하차지 변경');
    await tester.scrollUntilVisible(find.text('화주가 조건을 바꿨어요'), -100);
    expect(find.text('상/하차지·차종이 바뀐 경우라 거절해도 패널티가 없어요.'), findsOneWidget);
    expect(find.textContaining('화주 메시지:'), findsOneWidget);
    await tapText(tester, '바뀐 조건으로 운행');
    expect(find.text('화주가 조건을 바꿨어요'), findsNothing);
    await tester.scrollUntilVisible(find.text('전북 김제 → 경기 평택'), -100);
    expect(find.text('전북 김제 → 경기 평택'), findsOneWidget);
  });

  testWidgets('알림: 홈 종 아이콘에 안 읽은 수가 보이고, 열면 읽음 처리되며 경고 알림은 경고 내역으로 간다', (tester) async {
    final container = await loginDriver(tester);
    expect(find.byTooltip('알림'), findsOneWidget); // 아직 알림 없음

    await openAcceptedTrip(tester, container, 'order-1', '대두 · 국산');
    await tester.scrollUntilVisible(find.text('화주: 물량 변경'), 100);
    await tapText(tester, '화주: 물량 변경');
    await tester.scrollUntilVisible(find.text('화주가 조건을 바꿨어요'), -100);
    await tapText(tester, '거절');
    await tapText(tester, '거절하기');

    await openDriverTab(tester, '홈');
    expect(find.byTooltip('알림, 안 읽은 알림 2개'), findsOneWidget);
    await tester.tap(find.byTooltip('알림, 안 읽은 알림 2개'));
    await tester.pumpAndSettle();
    expect(find.text('화주가 조건을 바꿨어요'), findsOneWidget);
    expect(find.text('경고 1회가 기록됐어요'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == '새 알림'),
        findsNWidgets(2)); // 이번에 새로 온 알림 표시

    await tester.tap(find.text('경고 1회가 기록됐어요'));
    await tester.pumpAndSettle();
    expect(find.text('경고·정지 내역'), findsOneWidget);
    expect(find.textContaining('물량'), findsWidgets);
    expect(find.textContaining('11월 13일(금) 09:00까지'), findsOneWidget);

    await openDriverTab(tester, '홈');
    expect(find.byTooltip('알림'), findsOneWidget); // 모두 읽음
  });

  testWidgets('설정 > 경고·정지 내역: 경고가 없으면 수락 가능 안내와 기준을 보여 준다', (tester) async {
    await loginDriver(tester);
    await openDriverTab(tester, '설정');
    await tapText(tester, '경고·정지 내역');
    expect(find.text('지금은 오더를 수락할 수 있어요.'), findsOneWidget);
    expect(find.text('받은 경고가 없어요.'), findsOneWidget);
    expect(find.textContaining('최초 경고 1년 뒤'), findsOneWidget);
  });

  testWidgets('정산: 운송 완료 건이 보이고, 상세에서 금액·지급일을, 별점·랭킹에서 순위를 본다', (tester) async {
    final container = await loginDriver(tester);
    final repo = container.read(orderRepositoryProvider) as MockOrderRepository;
    await repo.acceptOrder('order-1');
    await repo.uploadLoadingProof('order-1', '/l.jpg');
    await repo.uploadUnloadingProof(
        'order-1', '/u.jpg', UnloadingProofKind.weighTicket);
    await repo.simulateShipperResponse('order-1', confirmed: true);

    await openDriverTab(tester, '정산');
    expect(find.text('이번 달 별 0개 · 예상 수수료율 4%'), findsOneWidget);
    expect(find.text('화주 정산 대기'), findsWidgets);
    await tester.tap(find.byType(SettlementCard));
    await tester.pumpAndSettle();
    expect(find.text('정산 상세'), findsOneWidget);
    expect(find.text('수수료(예상 4%)'), findsOneWidget);
    expect(find.text('아직 정산 전'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('화주: 운송비 정산'), 100);
    await tapText(tester, '화주: 운송비 정산');
    await tester.scrollUntilVisible(find.text('지급일'), -100);
    expect(find.text('11월 20일(금)'), findsOneWidget); // 22일(일) → 그 전 영업일
    await tester.scrollUntilVisible(find.text('지급 예정'), -100);
    expect(find.text('지급 예정'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tapText(tester, '이번 달 별 0개 · 예상 수수료율 4%');
    expect(find.text('아직 이번 달 별점을 받지 않아 랭킹에 들지 않았어요.'), findsOneWidget);
    await tester.scrollUntilVisible(find.byTooltip('화주: 별 4개'), 100);
    await tester.tap(find.byTooltip('화주: 별 4개'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('4개'), -100);
    expect(find.text('랭킹 차주 20명 중 10위'), findsOneWidget);
    expect(find.byTooltip('화주: 별 4개'), findsNothing); // 한 번만
  });
}
