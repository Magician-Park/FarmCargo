import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 지금 시각. 테스트에서는 고정된 시각으로 바꿔 끼운다.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// 시각을 뺀 날짜(자정).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [from]에서 [to]까지 날짜 차이(일). 시각은 무시한다.
int daysBetween(DateTime from, DateTime to) =>
    dateOnly(to).difference(dateOnly(from)).inHours ~/ 24;
