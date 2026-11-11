import 'package:farm_cargo/features/auth/auth_provider.dart';
import 'package:farm_cargo/features/driver/my_orders_screen.dart';
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

    // 다시 열면 수락 버튼 대신 안내가 보인다
    await tester.tap(find.text('소맥피 · 외국산'));
    await tester.pumpAndSettle();
    expect(find.text('내가 수락한 오더예요'), findsOneWidget);
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
}
