import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../orders/order.dart';

/// 선호 구간을 고를 때 쓰는 시·도 이름(오더의 짧은 지역명 첫 단어와 같은 표기).
const provinces = [
  '서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종', '경기', //
  '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주',
];

/// ‘전북 김제’ -> ‘전북’.
String provinceOf(String region) => region.trim().split(RegExp(r'\s+')).first;

/// 자주 다니는 구간(사용자 결정 2026-11-12 17차: 설정에서 등록, 오더 찾기에서 ‘선호 구간만 보기’).
/// 구간 단위는 시·도 → 시·도로 해석했다(확인 필요).
class PreferredRoute {
  const PreferredRoute(this.from, this.to);
  final String from;
  final String to;

  String get label => '$from → $to';

  bool matches(Order order) =>
      provinceOf(order.originRegion) == from &&
      provinceOf(order.destinationRegion) == to;

  @override
  bool operator ==(Object other) =>
      other is PreferredRoute && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// 내 선호 구간 목록. 서버 연결 전이라 메모리에만 두며, 계정이 바뀌면 비운다.
class PreferredRoutesNotifier extends Notifier<List<PreferredRoute>> {
  @override
  List<PreferredRoute> build() {
    ref.watch(authProvider.select((account) => account?.id));
    return const [];
  }

  /// 이미 있는 구간이면 false.
  bool add(PreferredRoute route) {
    if (state.contains(route)) return false;
    state = [...state, route];
    return true;
  }

  void remove(PreferredRoute route) =>
      state = [for (final r in state) if (r != route) r];
}

final preferredRoutesProvider =
    NotifierProvider<PreferredRoutesNotifier, List<PreferredRoute>>(
        PreferredRoutesNotifier.new);
