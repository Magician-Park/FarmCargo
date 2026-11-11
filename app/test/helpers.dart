import 'package:farm_cargo/app.dart';
import 'package:farm_cargo/features/signup/document_scanner.dart';
import 'package:farm_cargo/features/signup/photo_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 카메라를 열지 않고 항상 같은 경로를 돌려주는 가짜 촬영.
class FakePhotoCapture implements PhotoCapture {
  const FakePhotoCapture();

  @override
  Future<String?> capture() async => '/fake/photo.jpg';
}

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final container = ProviderContainer(overrides: [
    photoCaptureProvider.overrideWithValue(const FakePhotoCapture()),
    // 테스트에는 실제 사진 파일이 없으므로 미리보기 자리에 빈 상자를 둔다.
    photoPreviewProvider.overrideWithValue(
        (path) => ColoredBox(color: Colors.grey, key: ValueKey('preview:$path'))),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container, child: const FarmCargoApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapText(WidgetTester tester, String text) async {
  // 같은 문구가 제목과 버튼에 함께 있을 수 있어 버튼을 우선한다.
  final button = find.widgetWithText(FilledButton, text);
  final finder = button.evaluate().length == 1 ? button : find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterAt(WidgetTester tester, int index, String text) async {
  await tester.enterText(find.byType(TextField).at(index), text);
  await tester.pump();
}

/// 하단 주 버튼(FilledButton)의 활성 여부.
bool bottomButtonEnabled(WidgetTester tester, String label) {
  final button =
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));
  return button.onPressed != null;
}

Future<void> goToLogin(WidgetTester tester) async {
  await tapText(tester, '확인'); // 권한 안내 -> 로비
  await tapText(tester, '로그인');
}

Future<void> fillAccount(WidgetTester tester, {String name = '이신규'}) async {
  await enterAt(tester, 0, name);
  await enterAt(tester, 1, 'Abcd123!');
  await enterAt(tester, 2, 'Abcd123!');
}

Future<void> verifyPhone(WidgetTester tester, String phone) async {
  await enterAt(tester, 0, phone);
  await tapText(tester, '인증번호 받기');
  await enterAt(tester, 1, '123456');
  await tapText(tester, '인증번호 확인');
}

Future<void> agreeAllTerms(WidgetTester tester) async {
  await tapText(tester, '약관 전체동의');
}

Future<void> captureDocument(WidgetTester tester) async {
  await tapText(tester, '촬영');
}

/// 차주 가입: 안내 확인 → 이름·휴대폰 인증 → 약관 → 비밀번호 → 차량까지 마친다.
Future<void> driverSignupUntilDocuments(WidgetTester tester,
    {String name = '이신규', required String phone}) async {
  await tapText(tester, '확인했어요');
  await enterAt(tester, 0, name);
  await enterAt(tester, 1, phone);
  await tapText(tester, '인증번호 받기');
  await enterAt(tester, 2, '123456');
  await tapText(tester, '인증번호 확인');
  await tapText(tester, '다음');
  await agreeAllTerms(tester);
  await tapText(tester, '다음');
  await enterAt(tester, 0, 'Abcd123!');
  await enterAt(tester, 1, 'Abcd123!');
  await tapText(tester, '다음');
  await enterAt(tester, 0, '경기12가3456');
  await tapText(tester, '일반 카고(25톤)');
  await tapText(tester, '다음');
}

/// 차주 서류 단계: 세 서류를 촬영하고 이메일·위수탁 동의를 채운다.
Future<void> fillDriverDocuments(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    // 아직 찍지 않은 서류의 ‘촬영’ 버튼(찍은 서류는 ‘다시 촬영’으로 바뀐다).
    final button = find.widgetWithText(FilledButton, '촬영').first;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byType(TextField).last, 'tax@example.com');
  await tester.pump();
  await tapText(tester, '(필수) 세금계산서 발행 위수탁에 동의합니다');
}
