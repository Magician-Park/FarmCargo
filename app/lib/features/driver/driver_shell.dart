import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 차주 화면의 하단 탭(홈 / 오더 찾기). 탭을 오가도 각 탭의 스크롤·상태가 유지된다.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // 이미 선택된 탭을 다시 누르면 그 탭의 첫 화면으로 돌아간다.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: '오더 찾기'),
        ],
      ),
    );
  }
}
