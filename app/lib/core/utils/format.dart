/// 1234567 -> '1,234,567'
String formatWon(int n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

/// kg당 단가는 소수점 첫째 자리까지 받는다(D01, 2026-11-11).
/// 12.5 -> '12.5', 19 -> '19', 1234.5 -> '1,234.5'
String formatKgPrice(num price) {
  final tenths = (price * 10).round();
  final won = formatWon(tenths ~/ 10);
  final decimal = tenths % 10;
  return decimal == 0 ? won : '$won.$decimal';
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 2026-11-13 -> '11월 13일(금)'
String formatShortDate(DateTime d) =>
    '${d.month}월 ${d.day}일(${_weekdays[d.weekday - 1]})';
