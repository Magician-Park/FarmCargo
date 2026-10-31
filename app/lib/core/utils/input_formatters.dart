import 'package:flutter/services.dart';

/// 숫자만 받아 [pattern]의 '#' 자리에 채우고 나머지 문자는 구분자로 넣는다.
/// 예: '###-##-#####' -> '123-45-67891'
class DigitPatternFormatter extends TextInputFormatter {
  const DigitPatternFormatter(this.pattern);

  final String pattern;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    var index = 0;
    for (final char in pattern.split('')) {
      if (index >= digits.length) break;
      if (char == '#') {
        buffer.write(digits[index++]);
      } else {
        buffer.write(char);
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

const dateFormatter = DigitPatternFormatter('####-##-##');
const businessNumberFormatter = DigitPatternFormatter('###-##-#####');
const residentNumberFormatter = DigitPatternFormatter('######-#######');
