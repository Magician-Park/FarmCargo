import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../auth/auth_provider.dart';
import 'driver_alert.dart';
import 'inquiry.dart';
import 'order.dart';
import 'order_policy.dart';
import 'order_repository.dart';
import 'settlement.dart';
import 'trip.dart';
import 'trip_record.dart';

/// 로그인한 계정이 바뀌면 새로 만든다. 이전 차주의 수락 내역이 다음 사용자에게 보이지 않게 한다.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  ref.watch(authProvider.select((account) => account?.id));
  return MockOrderRepository(now: ref.watch(clockProvider));
});

/// 차주 홈의 추천 맞춤 오더.
final recommendedOrdersProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchRecommendedOrders());

/// ‘오더 찾기’ 탭의 게시글 목록.
final jobPostsProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchJobPosts());

final orderProvider = FutureProvider.family<Order?, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).fetchOrder(id));

/// ‘내 오더’: 내가 수락한 오더.
final myOrdersProvider = FutureProvider<List<Order>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchMyOrders());

/// ‘내 오더’ 운행 기록.
final tripRecordsProvider = FutureProvider<List<TripRecord>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchTripRecords());

/// 오더를 수락하고 목록들을 새로 불러온다. 실패하면 [OrderAcceptException].
Future<void> acceptOrder(WidgetRef ref, String id) async {
  await ref.read(orderRepositoryProvider).acceptOrder(id);
  ref.invalidate(sanctionProvider);
  ref.invalidate(jobPostsProvider);
  ref.invalidate(recommendedOrdersProvider);
  ref.invalidate(myOrdersProvider);
  ref.invalidate(tripProvider(id));
}

/// 내가 수락한 오더의 운행 진행 상태.
final tripProvider = FutureProvider.family<TripProgress?, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).fetchTrip(id));

void _refreshTrip(WidgetRef ref, String orderId) {
  ref.invalidate(alertsProvider);
  ref.invalidate(tripProvider(orderId));
  ref.invalidate(myOrdersProvider);
  ref.invalidate(tripRecordsProvider);
  ref.invalidate(settlementsProvider);
  ref.invalidate(rankingProvider);
}

/// 상차 계근표를 올린다. 실패하면 [TripActionException].
Future<void> uploadLoadingProof(
    WidgetRef ref, String orderId, String photoPath) async {
  await ref.read(orderRepositoryProvider).uploadLoadingProof(orderId, photoPath);
  _refreshTrip(ref, orderId);
}

/// 하차 증빙을 올리고 화주 확인을 요청한다. 실패하면 [TripActionException].
Future<void> uploadUnloadingProof(WidgetRef ref, String orderId,
    String photoPath, UnloadingProofKind kind) async {
  await ref
      .read(orderRepositoryProvider)
      .uploadUnloadingProof(orderId, photoPath, kind);
  _refreshTrip(ref, orderId);
}

/// 시연용: 화주 응답을 대신한다. 샘플 저장소일 때만 동작한다.
Future<void> simulateShipperResponse(
    WidgetRef ref, String orderId, bool confirmed) async {
  final repository = ref.read(orderRepositoryProvider);
  if (repository is! MockOrderRepository) return;
  await repository.simulateShipperResponse(orderId, confirmed: confirmed);
  _refreshTrip(ref, orderId);
}

/// 시연용 화주 응답 버튼을 보여 줄지(샘플 저장소일 때만).
final isDemoRepositoryProvider = Provider<bool>(
    (ref) => ref.watch(orderRepositoryProvider) is MockOrderRepository);

/// 내 경고·정지 상태(D14).
final sanctionProvider = FutureProvider<DriverSanction>(
    (ref) => ref.watch(orderRepositoryProvider).fetchSanction());

/// 오늘 이미 취소한 건수.
final cancellationsTodayProvider = FutureProvider<int>(
    (ref) => ref.watch(orderRepositoryProvider).cancellationsToday());

/// 화주가 보낸, 아직 답하지 않은 조건 변경.
final pendingChangeProvider = FutureProvider.family<ConditionChange?, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).fetchPendingChange(id));

void _refreshAll(WidgetRef ref, String orderId) {
  _refreshTrip(ref, orderId);
  ref.invalidate(orderProvider(orderId));
  ref.invalidate(pendingChangeProvider(orderId));
  ref.invalidate(jobPostsProvider);
  ref.invalidate(recommendedOrdersProvider);
  ref.invalidate(sanctionProvider);
  ref.invalidate(cancellationsTodayProvider);
}

/// 배차를 취소한다. 실패하면 [TripActionException].
Future<void> cancelOrder(WidgetRef ref, String orderId, String reason) async {
  await ref.read(orderRepositoryProvider).cancelOrder(orderId, reason);
  _refreshAll(ref, orderId);
}

/// 조건 변경에 답한다. 실패하면 [TripActionException].
Future<void> respondToChange(WidgetRef ref, String orderId, bool accept) async {
  await ref.read(orderRepositoryProvider).respondToChange(orderId, accept: accept);
  _refreshAll(ref, orderId);
}

/// 시연용: 화주의 조건 변경을 대신 만든다. 샘플 저장소일 때만 동작한다.
Future<void> simulateConditionChange(
    WidgetRef ref, String orderId, bool location) async {
  final repository = ref.read(orderRepositoryProvider);
  if (repository is! MockOrderRepository) return;
  await repository.simulateConditionChange(orderId, location: location);
  ref.invalidate(pendingChangeProvider(orderId));
  ref.invalidate(alertsProvider);
}

/// 내 알림 목록.
final alertsProvider = FutureProvider<List<DriverAlert>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchAlerts());

/// 안 읽은 알림 수(홈의 종 아이콘 표시).
final unreadAlertCountProvider = Provider<int>((ref) =>
    ref.watch(alertsProvider).value?.where((a) => !a.read).length ?? 0);

/// 알림을 모두 읽음으로 바꾼다.
Future<void> markAlertsRead(WidgetRef ref) async {
  await ref.read(orderRepositoryProvider).markAlertsRead();
  ref.invalidate(alertsProvider);
}

/// 정산 내역(D09).
final settlementsProvider = FutureProvider<List<SettlementItem>>(
    (ref) => ref.watch(orderRepositoryProvider).fetchSettlements());

/// 이번 달 별점 랭킹(D17).
final rankingProvider = FutureProvider<MonthlyRanking>(
    (ref) => ref.watch(orderRepositoryProvider).fetchRanking());

/// 시연용: 화주의 별점을 대신 준다. 샘플 저장소일 때만 동작한다. 실패하면 [TripActionException].
Future<void> simulateShipperRating(
    WidgetRef ref, String orderId, int stars) async {
  final repository = ref.read(orderRepositoryProvider);
  if (repository is! MockOrderRepository) return;
  await repository.simulateShipperRating(orderId, stars);
  ref.invalidate(tripRecordsProvider);
  ref.invalidate(settlementsProvider);
  ref.invalidate(rankingProvider);
}

/// 시연용: 화주의 운송비 정산(입금)을 대신한다. 샘플 저장소일 때만 동작한다.
Future<void> simulateShipperPayment(WidgetRef ref, String orderId) async {
  final repository = ref.read(orderRepositoryProvider);
  if (repository is! MockOrderRepository) return;
  await repository.simulateShipperPayment(orderId);
  ref.invalidate(settlementsProvider);
}

/// 이 오더의 ‘화주에게 전달’ 글(D06).
final inquiriesProvider = FutureProvider.family<List<ShipperInquiry>, String>(
    (ref, id) => ref.watch(orderRepositoryProvider).fetchInquiries(id));

/// ‘화주에게 전달’ 글을 보낸다. 실패하면 [TripActionException].
Future<void> sendInquiry(WidgetRef ref, String orderId, String message) async {
  await ref.read(orderRepositoryProvider).sendInquiry(orderId, message);
  ref.invalidate(inquiriesProvider(orderId));
}

/// 시연용: 고객센터가 화주 답을 보낸 것으로 한다. 샘플 저장소일 때만 동작한다.
Future<void> simulateInquiryAnswer(
    WidgetRef ref, String orderId, String inquiryId, String answer) async {
  final repository = ref.read(orderRepositoryProvider);
  if (repository is! MockOrderRepository) return;
  await repository.simulateInquiryAnswer(inquiryId, answer);
  ref.invalidate(inquiriesProvider(orderId));
  ref.invalidate(alertsProvider);
}
