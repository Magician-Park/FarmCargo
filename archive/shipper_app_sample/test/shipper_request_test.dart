import 'package:farm_cargo/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<void> openShipperRequest(WidgetTester tester) async {
  final container = await pumpApp(tester);
  await container
      .read(authProvider.notifier)
      .signIn(phone: '01033334444', password: 'Passw0rd!');
  await tester.pumpAndSettle();
  expect(find.text('화주 홈'), findsOneWidget);
  await tester.tap(find.text('운송 요청하기'));
  await tester.pumpAndSettle();
}

void main() {
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

  testWidgets('화주가 곡물 운송 조건과 적재 형태를 선택한다', (tester) async {
    await openShipperRequest(tester);

    expect(find.text('곡물 구분'), findsOneWidget);
    expect(find.text('어떻게 실려 있나요?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('grain-type-LMO (유전자변형)')));
    await tester.pumpAndSettle();
    expect(find.text('LMO 운송 승인과 밀폐 적재함을 확인한 차량만 매칭해요.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('grain-type-친환경 인증')));
    await tester.pumpAndSettle();
    expect(find.text('세척 확인을 마친 차량만 매칭해 친환경 인증 화물을 보호해요.'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('package-벌크')));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('package-벌크')));
    await tester.pumpAndSettle();
    expect(find.text('5톤'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('package-파렛트')));
    await tester.pumpAndSettle();
    expect(find.text('8개'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('package-포대')));
    await tester.pumpAndSettle();
    expect(find.text('100포'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('이 조건으로 곡물 운송 요청하기'),
      find.byType(ListView),
      const Offset(0, -350),
    );
    expect(find.text('이 조건으로 곡물 운송 요청하기'), findsOneWidget);
  });

  testWidgets('곡물 요청을 등록하면 화주 홈으로 돌아간다', (tester) async {
    await openShipperRequest(tester);

    await tester.dragUntilVisible(
      find.text('이 조건으로 곡물 운송 요청하기'),
      find.byType(ListView),
      const Offset(0, -350),
    );
    await tester.tap(find.text('이 조건으로 곡물 운송 요청하기'));
    await tester.pumpAndSettle();
    expect(find.text('곡물 운송 요청을 등록했어요'), findsOneWidget);

    await tester.tap(find.text('화주 홈으로'));
    await tester.pumpAndSettle();
    expect(find.text('화주 홈'), findsOneWidget);
    expect(find.text('곡물 구분'), findsNothing);
  });

  testWidgets('곡물 화면에서 비료 운송 요청 화면으로 이동한다', (tester) async {
    await openShipperRequest(tester);
    await tester.tap(find.text('🧪 비료'));
    await tester.pumpAndSettle();

    expect(find.text('비료 종류'), findsOneWidget);
    expect(find.text('복합비료'), findsOneWidget);
  });

  testWidgets('화주가 사료 운송 요청 화면으로 이동한다', (tester) async {
    await openShipperRequest(tester);
    await tester.tap(find.text('🐄 사료'));
    await tester.pumpAndSettle();

    expect(find.text('사료 종류'), findsOneWidget);
    expect(find.text('배합사료'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('사료 보호·농장 방역'),
      find.byType(ListView),
      const Offset(0, -350),
    );
    expect(find.text('사료 보호·농장 방역'), findsOneWidget);
    expect(find.text('이 조건으로 사료 운송 요청하기'), findsOneWidget);
  });

  testWidgets('곡물에서 사료로 간 뒤 요청을 등록해도 화주 홈으로 돌아간다', (tester) async {
    await openShipperRequest(tester);
    await tester.tap(find.text('🐄 사료'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('이 조건으로 사료 운송 요청하기'),
      find.byType(ListView),
      const Offset(0, -350),
    );
    await tester.tap(find.text('이 조건으로 사료 운송 요청하기'));
    await tester.pumpAndSettle();
    expect(find.text('사료 운송 요청을 등록했어요'), findsOneWidget);

    await tester.tap(find.text('화주 홈으로'));
    await tester.pumpAndSettle();
    expect(find.text('화주 홈'), findsOneWidget);
    expect(find.text('사료 종류'), findsNothing);
  });

  testWidgets('사료 화면의 비료 칩으로 비료 화면에 갈 수 있다', (tester) async {
    await openShipperRequest(tester);
    await tester.tap(find.text('🐄 사료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🧪 비료'));
    await tester.pumpAndSettle();
    expect(find.text('비료 종류'), findsOneWidget);

    // 뒤로 가면 화주 홈
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('화주 홈'), findsOneWidget);
  });
}
