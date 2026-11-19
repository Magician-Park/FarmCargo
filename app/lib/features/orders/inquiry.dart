/// 배차 질의(‘화주에게 전달’, D06·D07).
/// 차주가 쓰면 고객센터가 화주에게 직접 전달하고, 받은 답을 앱으로 차주에게 보낸다.
/// 화주↔차주 연락처는 서로 공개하지 않으므로 글에 전화번호를 넣지 못하게 한다.
class ShipperInquiry {
  const ShipperInquiry({
    required this.id,
    required this.orderId,
    required this.message,
    required this.sentAt,
    this.answer,
    this.answeredAt,
  });

  final String id;
  final String orderId;
  final String message;
  final DateTime sentAt;

  /// 고객센터가 화주에게 받아 보낸 답. 아직이면 null.
  final String? answer;
  final DateTime? answeredAt;

  bool get answered => answer != null;
  String get statusLabel => answered ? '답변 도착' : '고객센터가 화주에게 전달 중';

  ShipperInquiry withAnswer(String text, DateTime at) => ShipperInquiry(
        id: id,
        orderId: orderId,
        message: message,
        sentAt: sentAt,
        answer: text,
        answeredAt: at,
      );
}

/// 한 번에 보낼 수 있는 글자 수(화면 입력 제한).
const inquiryMaxLength = 300;

/// 자주 묻는 내용(D06 예시). 누르면 글에 이어 붙인다.
const inquiryExamples = [
  '도착하면 바로 싣고 내릴 수 있나요?',
  '가는 길이 좁은가요?',
  '조심해야 할 길이 있나요?',
  '높이 제한이 있나요?',
];

final _phonePattern = RegExp(r'0\d{1,2}[-.\s]?\d{3,4}[-.\s]?\d{4}');

/// 보낼 글을 검사한다. 문제없으면 null, 아니면 화면에 보여 줄 안내.
String? validateInquiry(String text) {
  final t = text.trim();
  if (t.isEmpty) return '화주에게 전달할 내용을 써 주세요.';
  if (t.length > inquiryMaxLength) return '$inquiryMaxLength자 안으로 써 주세요.';
  if (_phonePattern.hasMatch(t)) {
    return '연락처는 적을 수 없어요. 화주와 차주의 연락처는 서로 공개하지 않아요.';
  }
  return null;
}
