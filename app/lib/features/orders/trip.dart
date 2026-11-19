/// 운행 진행 상태(차주 관점, D05).
/// 상차 계근표는 사진만 올리고, 하차 증빙은 화주의 예/아니오 확인을 받는다.
enum TripStatus {
  assigned('상차 전'), // 배차 확정, 상차 계근표를 아직 안 올림
  inTransit('운송 중'), // 상차 계근표를 올림
  awaitingConfirmation('화주 확인 대기'), // 하차 증빙을 올리고 화주 답을 기다림
  disputed('고객센터 확인 중'), // 화주가 ‘아니오’라고 답함
  completed('운송 완료'); // 화주가 ‘예’라고 답함

  const TripStatus(this.label);
  final String label;
}

/// 하차 증빙 종류. 하차지 계근표가 없을 때만 공장 사무실 직원 서명을 받는다(D05).
enum UnloadingProofKind {
  weighTicket('하차 계근표'),
  staffSignature('공장 직원 서명');

  const UnloadingProofKind(this.label);
  final String label;
}

/// 화주가 수락 뒤 바꾼 항목 하나(바꾸기 전 → 바꾼 뒤).
class FieldChange {
  const FieldChange(this.label, this.before, this.after);
  final String label;
  final String before;
  final String after;
}

/// 화주의 조건 변경 요청(D04). 차주가 수락하거나 거절한다.
class ConditionChange {
  const ConditionChange({
    required this.orderId,
    required this.changes,
    required this.locationChanged,
    required this.vehicleTypeChanged,
    required this.requestedAt,
    this.message,
  });

  final String orderId;
  final List<FieldChange> changes;
  final bool locationChanged; // 상/하차지를 바꿈
  final bool vehicleTypeChanged; // 차종을 잘못 입력해 바꿈
  final DateTime requestedAt;
  final String? message; // 화주가 따로 보낸 변경 사유·양해 메시지

  /// 거절해도 패널티가 없는지(D04): 상/하차지를 바꿨거나(사유 메시지를 보냈어도) 차종을 잘못 입력한 경우.
  bool get refusableWithoutPenalty => locationChanged || vehicleTypeChanged;
}

/// 한 오더의 운행 진행 기록.
class TripProgress {
  final String orderId;
  final TripStatus status;
  final DateTime acceptedAt; // 배차일(수락한 시각). 취소 마감 계산에 쓴다
  final String? loadingProofPath; // 상차 계근표 사진
  final DateTime? loadedAt;
  final String? unloadingProofPath; // 하차 계근표 또는 서명 사진
  final UnloadingProofKind? unloadingProofKind;
  final DateTime? unloadingSubmittedAt;
  final DateTime? confirmedAt; // 화주가 예/아니오로 답한 시각

  const TripProgress({
    required this.orderId,
    required this.acceptedAt,
    this.status = TripStatus.assigned,
    this.loadingProofPath,
    this.loadedAt,
    this.unloadingProofPath,
    this.unloadingProofKind,
    this.unloadingSubmittedAt,
    this.confirmedAt,
  });

  TripProgress copyWith({
    TripStatus? status,
    String? loadingProofPath,
    DateTime? loadedAt,
    String? unloadingProofPath,
    UnloadingProofKind? unloadingProofKind,
    DateTime? unloadingSubmittedAt,
    DateTime? confirmedAt,
  }) =>
      TripProgress(
        orderId: orderId,
        acceptedAt: acceptedAt,
        status: status ?? this.status,
        loadingProofPath: loadingProofPath ?? this.loadingProofPath,
        loadedAt: loadedAt ?? this.loadedAt,
        unloadingProofPath: unloadingProofPath ?? this.unloadingProofPath,
        unloadingProofKind: unloadingProofKind ?? this.unloadingProofKind,
        unloadingSubmittedAt: unloadingSubmittedAt ?? this.unloadingSubmittedAt,
        confirmedAt: confirmedAt ?? this.confirmedAt,
      );
}

/// 운행 단계를 지금 상태에서 진행할 수 없을 때. [message]는 화면에 그대로 보여 준다.
class TripActionException implements Exception {
  const TripActionException(this.message);
  final String message;

  @override
  String toString() => message;
}
