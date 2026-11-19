import 'package:farm_cargo/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// 권한 안내 → 로비 → 회원가입. 차주 전용 앱이라 역할 선택 없이 바로 차주 가입이다.
Future<void> startSignup(WidgetTester tester) async {
  await tapText(tester, '확인');
  await tapText(tester, '회원가입');
}

void main() {
  smallScreenTests();
  testWidgets('차주 회원가입: 안내부터 서류까지 마치면 가입 신청되고, 로그인하면 승인 대기 화면만 보인다',
      (tester) async {
    await pumpApp(tester);
    await startSignup(tester);

    // 1. 가입 조건 안내
    expect(
        find.textContaining('회원가입 · 차주', findRichText: true), findsOneWidget);
    expect(find.text('가입 전에 확인해 주세요'), findsOneWidget);
    expect(find.text('· 일반 카고(25톤)'), findsOneWidget);
    expect(find.text('· 통장 사본'), findsOneWidget);
    await tapText(tester, '확인했어요');

    // 2. 이름 + 휴대폰 인증: 둘 다 마쳐야 다음
    expect(find.text('이름과 휴대폰 번호를 인증해 주세요'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await enterAt(tester, 0, '이신규');
    await enterAt(tester, 1, '01099998888');
    await tapText(tester, '인증번호 받기');
    expect(find.textContaining('인증번호는 123456'), findsOneWidget); // 데모 안내
    await enterAt(tester, 2, '000000');
    await tapText(tester, '인증번호 확인');
    expect(find.text('인증번호가 일치하지 않아요.'), findsOneWidget);
    await enterAt(tester, 2, '123456');
    await tapText(tester, '인증번호 확인');
    expect(find.text('휴대폰 인증이 완료되었어요'), findsOneWidget);
    await enterAt(tester, 0, '');
    expect(bottomButtonEnabled(tester, '다음'), isFalse); // 이름이 비면 진행 불가
    await enterAt(tester, 0, '이신규');
    await tapText(tester, '다음');

    // 3. 약관
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await agreeAllTerms(tester);
    await tapText(tester, '다음');

    // 4. 비밀번호(인증 다음 단계)
    expect(find.text('비밀번호를 정해 주세요'), findsOneWidget);
    await enterAt(tester, 0, 'Abcd123!');
    await enterAt(tester, 1, 'Abcd1234!');
    expect(find.text('비밀번호가 일치하지 않아요.'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await enterAt(tester, 1, 'Abcd123!');
    await tapText(tester, '다음');

    // 5. 차량번호·차종: 기타를 고르면 직접 입력해야 한다
    expect(find.text('차량 정보를 입력해 주세요'), findsOneWidget);
    await enterAt(tester, 0, '12가34');
    expect(find.text('차량번호를 다시 확인해 주세요. 예: 경기12가3456'), findsOneWidget);
    await enterAt(tester, 0, '경기 12가 3456');
    await tapText(tester, '기타');
    expect(bottomButtonEnabled(tester, '다음'), isFalse);
    await enterAt(tester, 1, '윙바디(11톤)');
    expect(bottomButtonEnabled(tester, '다음'), isTrue);
    await tapText(tester, '워킹 덤프(워킹카)(25톤)');
    expect(find.text('차종·톤급 직접 입력'), findsNothing);
    await tapText(tester, '다음');

    // 6. 서류: 사진만 받고(항목 입력 없음) 승인 대기 표시, 이메일·위수탁 동의까지 해야 신청
    expect(find.text('서류를 제출해 주세요'), findsOneWidget);
    expect(find.text('화물운송종사자격증'), findsNothing);
    expect(find.byType(TextField), findsOneWidget); // 전자세금계산서 이메일만
    expect(bottomButtonEnabled(tester, '가입 신청'), isFalse);
    await fillDriverDocuments(tester);
    expect(find.text('승인 대기'), findsNWidgets(3));
    expect(find.byKey(const ValueKey('preview:/fake/photo.jpg')),
        findsNWidgets(3)); // 촬영한 사진 미리보기
    expect(bottomButtonEnabled(tester, '가입 신청'), isTrue);
    await tapText(tester, '(필수) 세금계산서 발행 위수탁에 동의합니다');
    expect(bottomButtonEnabled(tester, '가입 신청'), isFalse);
    await tapText(tester, '(필수) 세금계산서 발행 위수탁에 동의합니다');
    await tapText(tester, '가입 신청');

    // 7. 가입 신청 완료 → 로그인하면 승인 대기 화면만
    expect(find.text('가입 신청이 접수되었어요'), findsOneWidget);
    await tapText(tester, '처음 화면으로');
    await tapText(tester, '로그인');
    await enterAt(tester, 0, '01099998888');
    await enterAt(tester, 1, 'Abcd123!');
    await tapText(tester, '로그인');
    expect(find.text('이신규님, 가입 심사 중이에요'), findsOneWidget);
    expect(find.text('차주 홈'), findsNothing);
  });

  testWidgets('심사 중인 차주는 다른 차주 화면으로 갈 수 없고 로그아웃할 수 있다', (tester) async {
    final container = await pumpApp(tester);
    await startSignup(tester);
    await driverSignupUntilDocuments(tester, phone: '01077776666');
    await fillDriverDocuments(tester);
    await tapText(tester, '가입 신청');
    await tapText(tester, '처음 화면으로');
    await tapText(tester, '로그인');
    await enterAt(tester, 0, '01077776666');
    await enterAt(tester, 1, 'Abcd123!');
    await tapText(tester, '로그인');

    for (final path in [
      AppRoutes.driverHome,
      AppRoutes.driverJobs,
      AppRoutes.driverOrder('order-1'),
      '/shipper', // 화주 화면은 이 앱에 없다
    ]) {
      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(find.text('승인 대기'), findsOneWidget, reason: path);
    }

    await tapText(tester, '로그아웃'); // 승인 대기 화면의 로그아웃
    expect(find.text('로그인'), findsWidgets);
  });

  testWidgets('차주 가입 중 이미 가입된 번호면 본인 인증 단계로 돌아가 다른 번호로 다시 인증한다',
      (tester) async {
    await pumpApp(tester);
    await startSignup(tester);
    await driverSignupUntilDocuments(tester, phone: '01011112222'); // 데모 차주 번호
    await fillDriverDocuments(tester);
    await tapText(tester, '가입 신청');

    expect(find.text('이미 가입된 휴대폰 번호예요.'), findsOneWidget);
    expect(find.text('이름과 휴대폰 번호를 인증해 주세요'), findsOneWidget);
    expect(find.text('이신규'), findsOneWidget); // 이름은 유지
    // 오류 안내(스낵바)가 사라질 때까지 기다린다.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await enterAt(tester, 1, '01055550001');
    await tapText(tester, '인증번호 받기');
    await enterAt(tester, 2, '123456');
    await tapText(tester, '인증번호 확인');
    await tapText(tester, '다음');
    await tapText(tester, '다음'); // 약관(유지됨)
    await tapText(tester, '다음'); // 비밀번호(유지됨)
    await tapText(tester, '다음'); // 차량(유지됨)
    expect(find.text('승인 대기'), findsNWidgets(3)); // 서류(유지됨)
    await tapText(tester, '가입 신청');
    expect(find.text('가입 신청이 접수되었어요'), findsOneWidget);
  });

  testWidgets('뒤로가기는 이전 단계로 가고 입력값이 유지되며, 첫 단계에서는 로비로 간다', (tester) async {
    await pumpApp(tester);
    await startSignup(tester);
    await tapText(tester, '확인했어요');
    await enterAt(tester, 0, '이신규');
    await enterAt(tester, 1, '01044443333');
    await tapText(tester, '인증번호 받기');
    await enterAt(tester, 2, '123456');
    await tapText(tester, '인증번호 확인');
    await tapText(tester, '다음');
    expect(find.text('약관에 동의해 주세요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('이신규'), findsOneWidget); // 입력값 유지
    expect(find.text('휴대폰 인증이 완료되었어요'), findsOneWidget);

    // 시스템 뒤로가기도 이전 단계로 간다
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('가입 전에 확인해 주세요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('회원가입'), findsOneWidget); // 로비
  });

  testWidgets('로그인 화면의 회원이 아니신가요 버튼으로 회원가입에 갈 수 있다', (tester) async {
    await pumpApp(tester);
    await goToLogin(tester);
    await tapText(tester, '혹시 회원이 아니신가요?');
    expect(find.text('가입 전에 확인해 주세요'), findsOneWidget);
  });

  testWidgets('예전 역할별 가입 주소는 차주 가입 첫 화면으로 보낸다', (tester) async {
    final container = await pumpApp(tester);
    for (final path in ['/signup/shipper', '/signup/driver', '/signup/admin']) {
      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(find.text('가입 전에 확인해 주세요'), findsOneWidget, reason: path);
    }
  });
}

void smallScreenTests() {
  testWidgets('작은 화면과 키보드 영역에서도 가입 단계를 진행할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(tester);
    await startSignup(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await driverSignupUntilDocuments(tester, phone: '01012349999');
    await fillDriverDocuments(tester);

    expect(find.text('가입 신청'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
