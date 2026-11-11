final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// 8~16자, 영문·숫자·기호를 각각 1자 이상 포함.
bool isValidPassword(String value) =>
    value.length >= 8 &&
    value.length <= 16 &&
    RegExp(r'[A-Za-z]').hasMatch(value) &&
    RegExp(r'\d').hasMatch(value) &&
    RegExp(r'[^A-Za-z0-9\s]').hasMatch(value);

bool isValidPhone(String value) => RegExp(r'^010\d{8}$').hasMatch(value);

/// 'yyyy-MM-dd' 형식의 실제 존재하는 날짜. 기본적으로 미래 날짜는 허용하지 않는다.
bool isValidDate(String value, {bool allowFuture = false}) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return false;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return false;
  if (year < 1900) return false;
  return allowFuture || !date.isAfter(DateTime.now());
}

/// 사업자등록번호(10자리) 검증번호 확인. 하이픈은 있어도 된다.
bool isValidBusinessNumber(String value) {
  final digits = value.replaceAll('-', '');
  if (!RegExp(r'^\d{10}$').hasMatch(digits)) return false;
  final d = digits.split('').map(int.parse).toList();
  const weights = [1, 3, 7, 1, 3, 7, 1, 3, 5];
  var sum = 0;
  for (var i = 0; i < 9; i++) {
    sum += d[i] * weights[i];
  }
  sum += (d[8] * 5) ~/ 10;
  return (10 - sum % 10) % 10 == d[9];
}

/// 주민등록번호(13자리) 형식과 검증번호 확인. 하이픈은 있어도 된다.
bool isValidResidentNumber(String value) {
  final digits = value.replaceAll('-', '');
  if (!RegExp(r'^\d{13}$').hasMatch(digits)) return false;
  final d = digits.split('').map(int.parse).toList();
  const weights = [2, 3, 4, 5, 6, 7, 8, 9, 2, 3, 4, 5];
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += d[i] * weights[i];
  }
  return (11 - sum % 11) % 10 == d[12];
}

/// 차량번호의 띄어쓰기를 없앤다. 예: '경기 12 가 3456' -> '경기12가3456'.
String normalizePlateNumber(String value) => value.replaceAll(RegExp(r'\s'), '');

/// 자동차 번호판 형식. 지역명(2글자)은 있어도 없어도 되고, 숫자 2~3자리 + 한글 1자 + 숫자 4자리.
/// 사업용 화물차의 용도 글자(바·사·아·자 등)는 따로 제한하지 않는다.
bool isValidPlateNumber(String value) => RegExp(r'^([가-힣]{2})?\d{2,3}[가-힣]\d{4}$')
    .hasMatch(normalizePlateNumber(value));
