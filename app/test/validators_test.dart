import 'package:farm_cargo/core/utils/input_formatters.dart';
import 'package:farm_cargo/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('비밀번호는 8~16자의 영문·숫자·기호를 모두 포함해야 한다', () {
    expect(isValidPassword('Abcd123!'), isTrue);
    expect(isValidPassword('Abcd123'), isFalse); // 기호 없음, 7자
    expect(isValidPassword('abcdefgh!'), isFalse); // 숫자 없음
    expect(isValidPassword('12345678!'), isFalse); // 영문 없음
    expect(isValidPassword('Abcd1234!Abcd1234!'), isFalse); // 18자
  });

  test('이메일/휴대폰 형식', () {
    expect(isValidEmail('a@b.co'), isTrue);
    expect(isValidEmail('a@b'), isFalse);
    expect(isValidEmail('a b@c.com'), isFalse);
    expect(isValidPhone('01012345678'), isTrue);
    expect(isValidPhone('0111234567'), isFalse);
  });

  test('날짜는 실제 존재하는 과거 날짜만 허용한다', () {
    expect(isValidDate('1975-03-15'), isTrue);
    expect(isValidDate('2023-02-29'), isFalse);
    expect(isValidDate('1975-13-01'), isFalse);
    expect(isValidDate('1899-01-01'), isFalse);
    expect(isValidDate('2999-01-01'), isFalse);
    expect(isValidDate('2999-01-01', allowFuture: true), isTrue);
    expect(isValidDate('19750315'), isFalse);
  });

  test('사업자등록번호와 주민등록번호는 검증번호를 확인한다', () {
    expect(isValidBusinessNumber('123-45-67891'), isTrue);
    expect(isValidBusinessNumber('1234567891'), isTrue);
    expect(isValidBusinessNumber('123-45-67890'), isFalse);
    expect(isValidBusinessNumber('123-45-678'), isFalse);
    expect(isValidResidentNumber('750315-1234568'), isTrue);
    expect(isValidResidentNumber('750315-1234567'), isFalse);
  });

  test('DigitPatternFormatter는 숫자만 받아 구분자를 넣는다', () {
    TextEditingValue run(String text) => businessNumberFormatter
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));
    expect(run('1234567891').text, '123-45-67891');
    expect(run('123').text, '123');
    expect(run('1234').text, '123-4');
    expect(run('12a34-5').text, '123-45');
    expect(run('12345678912345').text, '123-45-67891'); // 초과분은 버림
  });
}
