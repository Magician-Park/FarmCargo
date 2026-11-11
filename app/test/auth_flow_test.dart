import 'package:farm_cargo/core/router/app_router.dart';
import 'package:farm_cargo/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('앱 실행 시 권한 안내 -> 로비(로그인/회원가입) 순서로 보인다', (tester) async {
    await pumpApp(tester);
    expect(find.text('팜카고 이용을 위해\n접근 권한을 허용해 주세요'), findsOneWidget);
    for (final name in ['카메라', '사진', '위치', '알림', '전화']) {
      expect(find.text(name), findsOneWidget);
    }

    await tapText(tester, '확인');
    expect(find.text('팜카고'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });

  testWidgets('로그인은 휴대폰 번호와 비밀번호가 맞아야 하고, 로그아웃하면 로비로 돌아온다', (tester) async {
    await pumpApp(tester);
    await goToLogin(tester);

    expect(find.text('휴대폰 번호'), findsOneWidget);
    expect(find.textContaining('이메일'), findsNothing); // 이메일 로그인은 없다
    expect(bottomButtonEnabled(tester, '로그인'), isFalse);
    await enterAt(tester, 0, '01011112222');
    await enterAt(tester, 1, 'wrong-password');
    await tapText(tester, '로그인');
    expect(find.text('휴대폰 번호 또는 비밀번호가 올바르지 않아요.'), findsOneWidget);
    expect(find.text('차주 홈'), findsNothing);

    await enterAt(tester, 1, 'Passw0rd!');
    await tapText(tester, '로그인');
    expect(find.text('차주 홈'), findsOneWidget);
    expect(find.text('김기사님,'), findsOneWidget);

    await tester.ensureVisible(find.text('대두 · 국산'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대두 · 국산'));
    await tester.pumpAndSettle();
    expect(find.text('오더 상세'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('차주 홈'), findsOneWidget);

    await tapText(tester, '로그아웃');
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });

  testWidgets('화주는 화주 홈으로 가고, 번호 입력칸에는 숫자만 들어간다', (tester) async {
    await pumpApp(tester);
    await goToLogin(tester);

    // 하이픈·문자는 걸러지고 11자리까지만 입력된다
    await enterAt(tester, 0, '010-3333-4444-99');
    expect(find.text('01033334444'), findsOneWidget);
    await enterAt(tester, 1, 'Passw0rd!');
    await tapText(tester, '로그인');
    expect(find.text('화주 홈'), findsOneWidget);
    expect(find.text('박농부님, 안녕하세요'), findsOneWidget);
  });

  testWidgets('가입되지 않은 번호나 형식이 틀린 번호는 로그인할 수 없다', (tester) async {
    await pumpApp(tester);
    await goToLogin(tester);

    await enterAt(tester, 0, '01012345');
    await enterAt(tester, 1, 'Passw0rd!');
    expect(find.text('010으로 시작하는 11자리 번호를 입력해 주세요.'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '로그인'), isFalse);

    await enterAt(tester, 0, '01099990000');
    await tapText(tester, '로그인');
    expect(find.text('휴대폰 번호 또는 비밀번호가 올바르지 않아요.'), findsOneWidget);
  });

  testWidgets('로그아웃 상태에서 보호된 경로로 가면 로비로 돌아온다', (tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go(AppRoutes.driverHome);
    await tester.pumpAndSettle();
    expect(find.text('차주 홈'), findsNothing);
    expect(find.text('로그인'), findsOneWidget);
  });

  testWidgets('차주는 화주 영역으로 갈 수 없다', (tester) async {
    final container = await pumpApp(tester);
    await container
        .read(authProvider.notifier)
        .signIn(phone: '01011112222', password: 'Passw0rd!');
    await tester.pumpAndSettle();
    expect(find.text('차주 홈'), findsOneWidget);

    container.read(routerProvider).go(AppRoutes.shipperHome);
    await tester.pumpAndSettle();
    expect(find.text('차주 홈'), findsOneWidget);
    expect(find.text('화주 홈'), findsNothing);
  });

  testWidgets('퇴비 오더 상세에는 이력 경고가 표시된다', (tester) async {
    final container = await pumpApp(tester);
    await container
        .read(authProvider.notifier)
        .signIn(phone: '01011112222', password: 'Passw0rd!');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('퇴비 · 국산'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('퇴비 · 국산'));
    await tester.pumpAndSettle();
    expect(find.textContaining('퇴비 이력이 기록됩니다'), findsOneWidget);
    expect(find.text('이력 기록 동의하고 수락하기'), findsOneWidget);
  });

  testWidgets('없는 오더 id는 안내 문구를 보여주고 뒤로 가면 홈으로 간다', (tester) async {
    final container = await pumpApp(tester);
    await container
        .read(authProvider.notifier)
        .signIn(phone: '01011112222', password: 'Passw0rd!');
    await tester.pumpAndSettle();

    container.read(routerProvider).go(AppRoutes.driverOrder('nope'));
    await tester.pumpAndSettle();
    expect(find.text('오더를 찾을 수 없어요.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('차주 홈'), findsOneWidget);
  });
}
