import 'order.dart';

enum ShipmentStatus {
  waitingDispatch('배차 대기'),
  inTransit('운송 중');

  const ShipmentStatus(this.label);
  final String label;
}

/// 화주 입장의 운송 건: 오더 + 진행 상태.
class Shipment {
  final Order order;
  final ShipmentStatus status;
  final String description;

  const Shipment({
    required this.order,
    required this.status,
    required this.description,
  });
}
