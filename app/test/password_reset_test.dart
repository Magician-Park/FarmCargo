import 'package:farm_cargo/core/router/app_router.dart';
import 'package:farm_cargo/features/auth/auth_provider.dart';
import 'package:farm_cargo/features/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _driverPhone = '01011112222';

/// 로그인 화면에서 '비밀번호를 잊으셨나요?'로 들어가 휴대폰 인증을 마친다.
Future<void> verifyForReset(WidgetTester tester, String phone) async {
  await goToLogin(tester);
  await tapText(tester, '비밀번호를 잊으셨나요?');
  await enterAt(tester, 0, phone);
  await tapText(tester, '인증번호 받기');
  await enterAt(tester, 1, '123456');
  await tapText(tester, '인증번호 확인');
}

Future<void> submitNewPassword(WidgetTester tester, String password) async {
  await enterAt(tester, 0, password);
  await enterAt(tester, 1, password);
  await tapText(tester, '비밀번호 재설정하기');
}

void main() {
  testWidgets('휴대폰 인증 후 비밀번호를 바꾸면 성공 팝업이 뜨고 새 비밀번호로만 로그인된다', (tester) async {
    await pumpApp(tester);
    await verifyForReset(tester, _driverPhone);
    expect(find.textContaining('이메일'), findsNothing);
    expect(find.textContaining('인증번호는 123456'), findsNothing); // 확인 후엔 안내 숨김
    expect(find.text('휴대폰 인증이 완료되었어요'), findsOneWidget);
    await tapText(tester, '새 비밀번호 설정하기');

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
    expect(find.text('휴대폰 번호'), findsOneWidget);
    await enterAt(tester, 0, _driverPhone);
    await enterAt(tester, 1, 'Passw0rd!');
    await tapText(tester, '로그인');
    expect(find.text('휴대폰 번호 또는 비밀번호가 올바르지 않아요.'), findsOneWidget);
    await enterAt(tester, 1, 'NewPass123!');
    await tapText(tester, '로그인');
    expect(find.text('차주 홈'), findsOneWidget);
  });

  testWidgets('이미 쓴 재설정 인증으로 다시 설정하면 인증시간 만료 팝업이 뜬다', (tester) async {
    final container = await pumpApp(tester);
    final repository = container.read(authRepositoryProvider);
    final token = (await repository.verifyPasswordResetCode(
        _driverPhone, MockAuthRepository.demoCode))!;
    final link = AppRoutes.resetPasswordLink(token);

    container.read(routerProvider).go(link);
    await tester.pumpAndSettle();
    await submitNewPassword(tester, 'NewPass123!');
    expect(find.text('비밀번호가 성공적으로 재설정되었습니다!'), findsOneWidget);
    await tapText(tester, '확인');

    // 같은 주소를 다시 연다
    container.read(routerProvider).go(link);
    await tester.pumpAndSettle();
    await submitNewPassword(tester, 'Another123!');
    expect(find.text('인증시간이 만료되었습니다.'), findsOneWidget);
    expect(find.text('비밀번호가 성공적으로 재설정되었습니다!'), findsNothing);
    await tapText(tester, '확인');
    expect(find.text('휴대폰 번호'), findsOneWidget);

    // 두 번째 시도는 반영되지 않는다
    await enterAt(tester, 0, _driverPhone);
    await enterAt(tester, 1, 'NewPass123!');
    await tapText(tester, '로그인');
    expect(find.text('차주 홈'), findsOneWidget);
  });

  testWidgets('토큰이 없거나 잘못된 주소도 만료 팝업으로 처리한다', (tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go(AppRoutes.resetPassword);
    await tester.pumpAndSettle();
    await submitNewPassword(tester, 'NewPass123!');
    expect(find.text('인증시간이 만료되었습니다.'), findsOneWidget);
  });

  testWidgets('가입되지 않은 번호는 인증을 통과할 수 없고 가입 여부도 드러내지 않는다', (tester) async {
    await pumpApp(tester);
    await goToLogin(tester);
    await tapText(tester, '비밀번호를 잊으셨나요?');
    await enterAt(tester, 0, '01099990000');
    await tapText(tester, '인증번호 받기');
    // 가입된 번호와 같은 화면(인증번호 입력)이 나온다. 데모 안내만 다르다
    expect(find.text('인증번호 6자리'), findsOneWidget);
    expect(find.textContaining('인증번호가 만들어지지 않았어요'), findsOneWidget);

    await enterAt(tester, 1, '123456');
    await tapText(tester, '인증번호 확인');
    expect(find.text('인증번호가 일치하지 않아요.'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '새 비밀번호 설정하기'), isFalse);
  });

  testWidgets('인증번호가 틀리면 다음으로 갈 수 없다', (tester) async {
    await pumpApp(tester);
    await goToLogin(tester);
    await tapText(tester, '비밀번호를 잊으셨나요?');
    expect(bottomButtonEnabled(tester, '새 비밀번호 설정하기'), isFalse);
    await enterAt(tester, 0, _driverPhone);
    await tapText(tester, '인증번호 받기');
    await enterAt(tester, 1, '000000');
    await tapText(tester, '인증번호 확인');
    expect(find.text('인증번호가 일치하지 않아요.'), findsOneWidget);
    expect(bottomButtonEnabled(tester, '새 비밀번호 설정하기'), isFalse);
  });

  group('MockAuthRepository 비밀번호 재설정', () {
    const code = MockAuthRepository.demoCode;

    test('토큰은 3분이 지나면 만료된다', () async {
      var now = DateTime(2026, 11, 4, 12);
      final repo = MockAuthRepository(now: () => now);
      final token = (await repo.verifyPasswordResetCode(_driverPhone, code))!;

      now = now.add(MockAuthRepository.resetTokenValidity);
      expect(
        () => repo.resetPassword(token: token, newPassword: 'NewPass123!'),
        throwsA(isA<ResetLinkExpiredException>()),
      );
    });

    test('만료 직전에는 쓸 수 있다', () async {
      var now = DateTime(2026, 11, 4, 12);
      final repo = MockAuthRepository(now: () => now);
      final token = (await repo.verifyPasswordResetCode(_driverPhone, code))!;

      now = now.add(
          MockAuthRepository.resetTokenValidity - const Duration(seconds: 1));
      await repo.resetPassword(token: token, newPassword: 'NewPass123!');
      final account =
          await repo.signIn(phone: _driverPhone, password: 'NewPass123!');
      expect(account.name, '김기사');
    });

    test('다시 인증하면 이전 토큰은 쓸 수 없다', () async {
      final repo = MockAuthRepository();
      final first = (await repo.verifyPasswordResetCode(_driverPhone, code))!;
      final second = (await repo.verifyPasswordResetCode(_driverPhone, code))!;
      expect(
        () => repo.resetPassword(token: first, newPassword: 'NewPass123!'),
        throwsA(isA<ResetLinkExpiredException>()),
      );
      await repo.resetPassword(token: second, newPassword: 'NewPass123!');
    });

    test('가입되지 않은 번호이거나 인증번호가 틀리면 토큰을 만들지 않는다', () async {
      final repo = MockAuthRepository();
      expect(await repo.sendPasswordResetCode('01099990000'), isNull);
      expect(await repo.sendPasswordResetCode(_driverPhone), code);
      expect(await repo.verifyPasswordResetCode('01099990000', code), isNull);
      expect(
          await repo.verifyPasswordResetCode(_driverPhone, '000000'), isNull);
    });
  });
}
