import 'package:farm_cargo/core/router/app_router.dart';
import 'package:farm_cargo/features/auth/auth_provider.dart';
import 'package:farm_cargo/features/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<void> requestReset(WidgetTester tester, String email) async {
  await goToLogin(tester);
  await tapText(tester, '비밀번호를 잊으셨나요?');
  await enterAt(tester, 0, email);
  await tapText(tester, '재설정 링크 보내기');
}

Future<void> submitNewPassword(WidgetTester tester, String password) async {
  await enterAt(tester, 0, password);
  await enterAt(tester, 1, password);
  await tapText(tester, '비밀번호 재설정하기');
}

void main() {
  testWidgets('메일 링크로 비밀번호를 바꾸면 성공 팝업 후 새 비밀번호로만 로그인된다', (tester) async {
    await pumpApp(tester);
    await requestReset(tester, 'driver@farmcargo.test');
    expect(find.text('메일을 보냈어요'), findsOneWidget);
    await tapText(tester, '메일의 링크 열기');

    // 새 비밀번호: 형식 오류/불일치 시 버튼 비활성화
    expect(find.text('비밀번호 재설정'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '비밀번호 재설정하기'), isFalse);
    await enterAt(tester, 0, 'short');
    expect(find.text('8~16자의 영문, 숫자, 기호를 모두 포함해 주세요.'), findsOneWidget);
    await enterAt(tester, 0, 'NewPass123!');
    await enterAt(tester, 1, 'NewPass124!');
    expect(find.text('비밀번호가 일치하지 않아요.'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '비밀번호 재설정하기'), isFalse);
    await enterAt(tester, 1, 'NewPass123!');
    expect(bottomButtonEnabled(tester, '비밀번호 재설정하기'), isTrue);

    await tapText(tester, '비밀번호 재설정하기');
    expect(find.text('비밀번호가 성공적으로 재설정되었습니다!'), findsOneWidget);
    await tapText(tester, '확인');

    // 로그인 화면으로 이동. 이전 비밀번호는 거절, 새 비밀번호는 통과
    expect(find.text('이메일 주소'), findsOneWidget);
    await enterAt(tester, 0, 'driver@farmcargo.test');
    await enterAt(tester, 1, 'Passw0rd!');
    await tapText(tester, '로그인');
    expect(find.text('이메일 또는 비밀번호가 올바르지 않아요.'), findsOneWidget);
    await enterAt(tester, 1, 'NewPass123!');
    await tapText(tester, '로그인');
    expect(find.text('차주 홈'), findsOneWidget);
  });

  testWidgets('이미 쓴 링크로 다시 재설정하면 인증시간 만료 팝업이 뜬다', (tester) async {
    final container = await pumpApp(tester);
    final token = (await container
        .read(authRepositoryProvider)
        .requestPasswordReset('driver@farmcargo.test'))!;
    final link = AppRoutes.resetPasswordLink(token);

    container.read(routerProvider).go(link);
    await tester.pumpAndSettle();
    await submitNewPassword(tester, 'NewPass123!');
    expect(find.text('비밀번호가 성공적으로 재설정되었습니다!'), findsOneWidget);
    await tapText(tester, '확인');

    // 같은 링크를 다시 연다
    container.read(routerProvider).go(link);
    await tester.pumpAndSettle();
    await submitNewPassword(tester, 'Another123!');
    expect(find.text('인증시간이 만료되었습니다.'), findsOneWidget);
    expect(find.text('비밀번호가 성공적으로 재설정되었습니다!'), findsNothing);
    await tapText(tester, '확인');
    expect(find.text('이메일 주소'), findsOneWidget);

    // 두 번째 시도는 반영되지 않는다
    await enterAt(tester, 0, 'driver@farmcargo.test');
    await enterAt(tester, 1, 'NewPass123!');
    await tapText(tester, '로그인');
    expect(find.text('차주 홈'), findsOneWidget);
  });

  testWidgets('토큰이 없거나 잘못된 링크도 만료 팝업으로 처리한다', (tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go(AppRoutes.resetPassword);
    await tester.pumpAndSettle();
    await submitNewPassword(tester, 'NewPass123!');
    expect(find.text('인증시간이 만료되었습니다.'), findsOneWidget);
  });

  testWidgets('가입되지 않은 이메일도 같은 안내를 보여주지만 링크는 만들어지지 않는다', (tester) async {
    await pumpApp(tester);
    await requestReset(tester, 'nobody@farmcargo.test');
    expect(find.text('메일을 보냈어요'), findsOneWidget);
    expect(find.textContaining('nobody@farmcargo.test 로'), findsOneWidget);
    expect(find.text('메일의 링크 열기'), findsNothing);

    await tapText(tester, '로그인으로 돌아가기');
    expect(find.text('이메일 주소'), findsOneWidget);
  });

  testWidgets('이메일 형식이 틀리면 링크 보내기가 비활성화된다', (tester) async {
    await pumpApp(tester);
    await goToLogin(tester);
    await tapText(tester, '비밀번호를 잊으셨나요?');
    expect(bottomButtonEnabled(tester, '재설정 링크 보내기'), isFalse);
    await enterAt(tester, 0, 'not-an-email');
    expect(find.text('이메일 형식이 올바르지 않아요.'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '재설정 링크 보내기'), isFalse);
  });

  group('MockAuthRepository 재설정 토큰', () {
    test('30분이 지나면 만료된다', () async {
      var now = DateTime(2026, 10, 31, 12);
      final repo = MockAuthRepository(now: () => now);
      final token = (await repo.requestPasswordReset('driver@farmcargo.test'))!;

      now = now.add(MockAuthRepository.resetLinkValidity);
      expect(
        () => repo.resetPassword(token: token, newPassword: 'NewPass123!'),
        throwsA(isA<ResetLinkExpiredException>()),
      );
    });

    test('만료 직전에는 쓸 수 있다', () async {
      var now = DateTime(2026, 10, 31, 12);
      final repo = MockAuthRepository(now: () => now);
      final token = (await repo.requestPasswordReset('driver@farmcargo.test'))!;

      now = now.add(
          MockAuthRepository.resetLinkValidity - const Duration(seconds: 1));
      await repo.resetPassword(token: token, newPassword: 'NewPass123!');
      final account = await repo.signIn(
          identifier: 'driver@farmcargo.test', password: 'NewPass123!');
      expect(account.name, '김기사');
    });

    test('새 링크를 요청하면 이전 링크는 쓸 수 없다', () async {
      final repo = MockAuthRepository();
      final first = (await repo.requestPasswordReset('driver@farmcargo.test'))!;
      final second = (await repo
          .requestPasswordReset('Driver@FarmCargo.test'))!; // 대소문자 무시
      expect(
        () => repo.resetPassword(token: first, newPassword: 'NewPass123!'),
        throwsA(isA<ResetLinkExpiredException>()),
      );
      await repo.resetPassword(token: second, newPassword: 'NewPass123!');
    });

    test('가입되지 않은 이메일은 토큰을 만들지 않는다', () async {
      final repo = MockAuthRepository();
      expect(await repo.requestPasswordReset('nobody@farmcargo.test'), isNull);
    });
  });
}
