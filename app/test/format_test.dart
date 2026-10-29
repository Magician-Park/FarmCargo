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
}
