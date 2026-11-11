import 'package:farm_cargo/core/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatWon은 천 단위 쉼표를 넣는다', () {
    expect(formatWon(0), '0');
    expect(formatWon(999), '999');
    expect(formatWon(1000), '1,000');
    expect(formatWon(256500), '256,500');
    expect(formatWon(1234567), '1,234,567');
  });

  test('kg당 단가는 소수점 첫째 자리까지, 정수면 소수점 없이 보인다', () {
    expect(formatKgPrice(12.5), '12.5');
    expect(formatKgPrice(19), '19');
    expect(formatKgPrice(1234.5), '1,234.5');
  });

  test('날짜는 월·일·요일로 보인다', () {
    expect(formatShortDate(DateTime(2026, 11, 13)), '11월 13일(금)');
    expect(formatShortDate(DateTime(2026, 11, 16)), '11월 16일(월)');
  });
}
