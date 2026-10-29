import 'package:farm_cargo/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openPhoneLogin(WidgetTester tester, {bool driver = false}) async {
  if (driver) {
    await tester.tap(find.text('화물차로 운송해요'));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text('휴대폰 번호로 시작'));
  await tester.tap(find.text('휴대폰 번호로 시작'));
  await tester.pumpAndSettle();
}

Future<void> submitDemoLogin(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField), '01012345678');
  await tester.ensureVisible(find.text('데모 로그인'));
  await tester.tap(find.text('데모 로그인'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('앱 실행 시 역할 선택 화면이 표시된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FarmCargoApp()));

    expect(find.text('팜카고'), findsOneWidget);
    expect(find.text('짐을 보내요'), findsOneWidget);
    expect(find.text('화물차로 운송해요'), findsOneWidget);
    expect(find.text('김기사님,'), findsNothing);
  });

  testWidgets('잘못된 번호는 로그인할 수 없고 올바른 번호로 화주 홈에 진입한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FarmCargoApp()));
    await openPhoneLogin(tester);

    for (final phone in ['', '010123', '01112345678']) {
      await tester.enterText(find.byType(TextFormField), phone);
      await tester.ensureVisible(find.text('데모 로그인'));
      await tester.tap(find.text('데모 로그인'));
      await tester.pumpAndSettle();

      expect(find.text('010으로 시작하는 휴대폰 번호 11자리를 입력해 주세요.'), findsOneWidget);
      expect(find.text('박농부님,'), findsNothing);
    }

    await submitDemoLogin(tester);
    expect(find.text('화주 홈'), findsOneWidget);
    expect(find.text('박농부님,'), findsOneWidget);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.text('어떻게 이용하시나요?'), findsOneWidget);
  });

  testWidgets('차주 로그인 후 상세를 열고 복귀한 뒤 로그아웃할 수 있다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FarmCargoApp()));
    await openPhoneLogin(tester, driver: true);
    await submitDemoLogin(tester);

    expect(find.text('차주 홈'), findsOneWidget);
    expect(find.text('김기사님,'), findsOneWidget);

    await tester.ensureVisible(find.text('식용 곡물'));
    await tester.tap(find.text('식용 곡물'));
    await tester.pumpAndSettle();
    expect(find.text('오더 상세'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('차주 홈'), findsOneWidget);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await openPhoneLogin(tester);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        isEmpty);
    await submitDemoLogin(tester);
    expect(find.text('화주 홈'), findsOneWidget);
    expect(find.text('차주 홈'), findsNothing);
  });

  testWidgets('휴대폰 입력에서 시스템 뒤로가기로 역할 선택에 돌아간다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FarmCargoApp()));
    await openPhoneLogin(tester, driver: true);
    await tester.enterText(find.byType(TextFormField), '01012345678');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('어떻게 이용하시나요?'), findsOneWidget);

    await openPhoneLogin(tester);
    expect(find.text('차주'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        isEmpty);
  });

  testWidgets('카카오 로그인은 준비 중 안내를 표시한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FarmCargoApp()));
    await tester.ensureVisible(find.text('카카오로 시작'));
    await tester.tap(find.text('카카오로 시작'));
    await tester.pump();

    expect(find.text('카카오 로그인은 준비 중이에요. 휴대폰 데모 로그인을 이용해 주세요.'), findsOneWidget);
    expect(find.text('어떻게 이용하시나요?'), findsOneWidget);
  });

  testWidgets('작은 화면과 키보드 영역에서도 로그인 버튼으로 이동할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: FarmCargoApp()));
    await openPhoneLogin(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await submitDemoLogin(tester);

    expect(find.text('화주 홈'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
