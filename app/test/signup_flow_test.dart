import 'package:farm_cargo/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<void> startSignup(WidgetTester tester, String roleCard) async {
  await tapText(tester, '확인');
  await tapText(tester, '회원가입');
  await tapText(tester, roleCard);
}

void main() {
  smallScreenTests();
  testWidgets('차주 회원가입: 모든 단계를 거치면 가입되고 그 계정으로 로그인할 수 있다', (tester) async {
    await pumpApp(tester);
    await startSignup(tester, '화물차로 운송해요');

    // 1. 계정 정보: 모두 올바르게 입력하기 전에는 다음이 비활성화
    expect(
        find.textContaining('회원가입 · 차주', findRichText: true), findsOneWidget);
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await enterAt(tester, 0, '이신규');
    await enterAt(tester, 1, 'new@farmcargo.test');
    await enterAt(tester, 2, 'Abcd123!');
    await enterAt(tester, 3, 'Abcd1234!');
    expect(find.text('비밀번호가 일치하지 않아요.'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await enterAt(tester, 3, 'Abcd123!');
    expect(find.text('비밀번호가 일치하지 않아요.'), findsNothing);
    expect(bottomButtonEnabled(tester, '다음'), isTrue);
    await tapText(tester, '다음');

    // 2. 휴대폰 인증: 틀린 번호는 거절, 맞는 번호만 통과
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await enterAt(tester, 0, '01099998888');
    await tapText(tester, '인증번호 받기');
    expect(find.textContaining('인증번호는 123456'), findsOneWidget); // 데모 안내
    await enterAt(tester, 1, '000000');
    await tapText(tester, '인증번호 확인');
    expect(find.text('인증번호가 일치하지 않아요.'), findsOneWidget);
    await enterAt(tester, 1, '123456');
    await tapText(tester, '인증번호 확인');
    expect(find.text('휴대폰 인증이 완료되었어요'), findsOneWidget);
    await tapText(tester, '다음');

    // 3. 약관: 필수 항목을 모두 체크해야 진행
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await agreeAllTerms(tester);
    expect(bottomButtonEnabled(tester, '다음'), isTrue);
    await tapText(tester, '다음');

    // 4. 화물운송종사자격증: 촬영하면 자동 입력되고 수정할 수 있다
    expect(find.text('성명'), findsNothing);
    await captureDocument(tester);
    expect(find.text('자동으로 입력했어요. 틀린 곳이 있으면 직접 고쳐 주세요.'), findsOneWidget);
    expect(find.text('11-1234567-01'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '다음'), isTrue);
    await enterAt(tester, 1, '1975-13-45');
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await enterAt(tester, 1, '19750315');
    expect(find.text('1975-03-15'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '다음'), isTrue);
    await tapText(tester, '다음');

    // 5. 사업자등록증 (차주는 관할 세무서 포함)
    await captureDocument(tester);
    expect(find.text('강서세무서'), findsOneWidget);
    expect(find.text('사업자 단위 과세 적용사업자 여부'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '가입 완료'), isTrue);
    await enterAt(tester, 0, '123-45-67890'); // 검증번호가 틀린 등록번호
    expect(bottomButtonEnabled(tester, '가입 완료'), isFalse);
    await enterAt(tester, 0, '1234567891');
    expect(bottomButtonEnabled(tester, '가입 완료'), isTrue);
    await tapText(tester, '가입 완료');

    // 6. 완료 -> 로비 -> 새 계정으로 로그인
    expect(find.text('회원가입이 완료되었어요'), findsOneWidget);
    await tapText(tester, '로그인하기');
    await tapText(tester, '로그인');
    await enterAt(tester, 0, 'new@farmcargo.test');
    await enterAt(tester, 1, 'Abcd123!');
    await tapText(tester, '로그인');
    expect(find.text('차주 홈'), findsOneWidget);
    expect(find.text('이신규님,'), findsOneWidget);
  });

  testWidgets('화주 회원가입: 주민등록증과 사업자등록증(세무서 없음)으로 가입한다', (tester) async {
    await pumpApp(tester);
    await startSignup(tester, '짐을 보내요');

    await fillAccount(tester, name: '최화주', email: 'shipper2@farmcargo.test');
    await tapText(tester, '다음');
    await verifyPhone(tester, '01055556666');
    await tapText(tester, '다음');
    await agreeAllTerms(tester);
    await tapText(tester, '다음');

    // 신분증
    expect(find.text('주민등록증'), findsOneWidget);
    await captureDocument(tester);
    expect(find.text('750315-1234568'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '다음'), isTrue);
    await enterAt(tester, 1, '7503151234567'); // 검증번호가 틀린 번호
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await enterAt(tester, 1, '7503151234568');
    await tapText(tester, '다음');

    // 사업자등록증: 세무서 항목이 없다
    await captureDocument(tester);
    expect(find.text('관할 세무서'), findsNothing);
    await tapText(tester, '가입 완료');
    expect(find.text('회원가입이 완료되었어요'), findsOneWidget);
  });

  testWidgets('이미 가입된 이메일이면 계정 단계로 돌아가 안내한다', (tester) async {
    await pumpApp(tester);
    await startSignup(tester, '화물차로 운송해요');

    await fillAccount(tester, email: 'driver@farmcargo.test'); // 데모 계정과 중복
    await tapText(tester, '다음');
    await verifyPhone(tester, '01077778888');
    await tapText(tester, '다음');
    await agreeAllTerms(tester);
    await tapText(tester, '다음');
    await captureDocument(tester);
    await tapText(tester, '다음');
    await captureDocument(tester);
    await tapText(tester, '가입 완료');

    expect(find.text('이미 가입된 이메일이에요.'), findsOneWidget);
    expect(find.text('계정 정보를 입력해 주세요'), findsOneWidget);
    expect(find.text('driver@farmcargo.test'), findsOneWidget); // 입력값 유지
  });

  testWidgets('뒤로가기는 이전 단계로 가고 입력값이 유지되며, 첫 단계에서는 역할 선택으로 간다', (tester) async {
    await pumpApp(tester);
    await startSignup(tester, '짐을 보내요');

    await fillAccount(tester);
    await tapText(tester, '다음');
    expect(find.text('휴대폰 번호를 인증해 주세요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('계정 정보를 입력해 주세요'), findsOneWidget);
    expect(find.text('new@farmcargo.test'), findsOneWidget);

    // 시스템 뒤로가기도 동일하게 동작
    await tapText(tester, '다음');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('계정 정보를 입력해 주세요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('어떻게 이용하시나요?'), findsOneWidget);
  });

  testWidgets('로그인 화면의 회원이 아니신가요 버튼으로 회원가입에 갈 수 있다', (tester) async {
    await pumpApp(tester);
    await goToLogin(tester);
    await tapText(tester, '혹시 회원이 아니신가요?');
    expect(find.text('어떻게 이용하시나요?'), findsOneWidget);
  });

  testWidgets('잘못된 역할 경로는 역할 선택으로 돌려보낸다', (tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go('/signup/admin');
    await tester.pumpAndSettle();
    expect(find.text('어떻게 이용하시나요?'), findsOneWidget);
  });
}

void smallScreenTests() {
  testWidgets('작은 화면과 키보드 영역에서도 가입 단계를 진행할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(tester);
    await startSignup(tester, '화물차로 운송해요');

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await fillAccount(tester);
    await tapText(tester, '다음');
    await verifyPhone(tester, '01012349999');
    await tapText(tester, '다음');
    await agreeAllTerms(tester);
    await tapText(tester, '다음');
    await captureDocument(tester);
    await tapText(tester, '다음');
    await captureDocument(tester);

    expect(find.text('가입 완료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
