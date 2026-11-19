/// 차주에게 오는 알림 종류(D02·D04·D05·D14).
enum DriverAlertType {
  conditionChanged('조건 변경'),
  proofConfirmed('증빙 확인'),
  proofRejected('증빙 확인 거부'),
  warning('경고·정지'),
  released('배차 해제');

  const DriverAlertType(this.label);
  final String label;
}

/// 알림 한 건. 앱 푸시·카카오 알림톡으로도 보내고(D02), 앱 안에서는 알림 목록에 모은다.
class DriverAlert {
  const DriverAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.read = false,
  });

  final String id;
  final DriverAlertType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? orderId; // 누르면 이 오더의 운행·상세 화면으로 간다
  final bool read;

  DriverAlert markRead() => DriverAlert(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      orderId: orderId,
      read: true);
}

/// 경고 한 건(D14). 사유와 기록 시각.
class WarningEntry {
  const WarningEntry({required this.at, required this.reason});
  final DateTime at;
  final String reason;
}
