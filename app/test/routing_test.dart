import 'package:farm_cargo/app.dart';
import 'package:farm_cargo/core/router/app_router.dart';
import 'package:farm_cargo/features/auth/account_role.dart';
import 'package:farm_cargo/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container, child: const FarmCargoApp()));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('로그아웃 상태에서 보호된 경로로 가면 로그인으로 돌아온다', (tester) async {
    final container = await pumpApp(tester);

    container.read(routerProvider).go(AppRoutes.driverHome);
    await tester.pumpAndSettle();

    expect(find.text('어떻게 이용하시나요?'), findsOneWidget);
    expect(find.text('차주 홈'), findsNothing);
  });

  testWidgets('차주는 화주 영역으로 갈 수 없다', (tester) async {
    final container = await pumpApp(tester);
    container.read(authProvider.notifier).login(AccountRole.driver);
    await tester.pumpAndSettle();
    expect(find.text('차주 홈'), findsOneWidget);

    container.read(routerProvider).go(AppRoutes.shipperHome);
    await tester.pumpAndSettle();

    expect(find.text('차주 홈'), findsOneWidget);
    expect(find.text('화주 홈'), findsNothing);
  });

  testWidgets('퇴비 오더 상세에는 이력 경고가 표시된다', (tester) async {
    final container = await pumpApp(tester);
    container.read(authProvider.notifier).login(AccountRole.driver);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('퇴비 벌크'));
    await tester.tap(find.text('퇴비 벌크'));
    await tester.pumpAndSettle();

    expect(find.textContaining('퇴비 이력이 기록됩니다'), findsOneWidget);
    expect(find.text('이력 기록 동의하고 수락하기'), findsOneWidget);
  });

  testWidgets('없는 오더 id는 안내 문구를 보여주고 뒤로 가면 홈으로 간다', (tester) async {
    final container = await pumpApp(tester);
    container.read(authProvider.notifier).login(AccountRole.driver);
    await tester.pumpAndSettle();

    container.read(routerProvider).go(AppRoutes.driverOrder('nope'));
    await tester.pumpAndSettle();
    expect(find.text('오더를 찾을 수 없어요.'), findsOneWidget);
    expect(find.text('이 오더 수락하기'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('차주 홈'), findsOneWidget);
  });
}
