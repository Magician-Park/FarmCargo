import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/demo_notice.dart';
import '../../core/widgets/section_card.dart';
import '../orders/order.dart';
import '../orders/orders_providers.dart';
import '../orders/trip.dart';
import '../signup/document_capture_card.dart';
import '../signup/photo_capture.dart';
import '../signup/photo_preview.dart';
import 'trip_changes.dart';

/// 운행 진행·운송 증빙(D05). 수락한 오더를 상차 계근표 → 하차 증빙 → 화주 확인 → 운송 완료 순으로 진행한다.
class TripScreen extends ConsumerWidget {
  const TripScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(orderId));
    final trip = ref.watch(tripProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '뒤로가기',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.driverMyOrders),
        ),
        title: const Text('운행', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: AsyncValueView(
        value: order,
        onRetry: () => ref.invalidate(orderProvider(orderId)),
        builder: (order) => AsyncValueView(
          value: trip,
          onRetry: () => ref.invalidate(tripProvider(orderId)),
          builder: (trip) => order == null || trip == null
              ? const Center(child: Text('내가 수락한 오더가 아니에요.'))
              : _TripBody(order: order, trip: trip),
        ),
      ),
    );
  }
}

class _TripBody extends StatelessWidget {
  const _TripBody({required this.order, required this.trip});

  final Order order;
  final TripProgress trip;

  int get _stage => switch (trip.status) {
        TripStatus.assigned => 1,
        TripStatus.inTransit => 2,
        TripStatus.awaitingConfirmation || TripStatus.disputed => 3,
        TripStatus.completed => 4,
      };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Summary(order: order, status: trip.status),
        const SizedBox(height: 16),
        ConditionChangeCard(orderId: order.id),
        _StageTile(
          number: 1,
          title: '배차 확정',
          done: true,
          active: false,
          child: null,
        ),
        _StageTile(
          number: 2,
          title: '상차 계근표 올리기',
          done: _stage > 1,
          active: _stage == 1,
          child: _stage == 1
              ? _LoadingProofForm(orderId: order.id)
              : _stage > 1
                  ? _UploadedPhoto(
                      label: '상차 계근표', path: trip.loadingProofPath!)
                  : null,
        ),
        _StageTile(
          number: 3,
          title: '하차 증빙 올리기',
          done: _stage > 2,
          active: _stage == 2,
          child: _stage == 2
              ? _UnloadingProofForm(orderId: order.id)
              : _stage > 2
                  ? _UploadedPhoto(
                      label: trip.unloadingProofKind!.label,
                      path: trip.unloadingProofPath!)
                  : null,
        ),
        _StageTile(
          number: 4,
          title: '화주 확인',
          done: _stage > 3,
          active: _stage == 3,
          child: _stage == 3 ? _Confirmation(trip: trip) : null,
        ),
        _StageTile(
          number: 5,
          title: '운송 완료',
          done: _stage == 4,
          active: false,
          last: true,
          child: _stage == 4 ? const _Completed() : null,
        ),
        const SizedBox(height: 8),
        const Text(
          '증빙 사진은 운송이 끝난 날부터 3개월 뒤 완전히 삭제돼요.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        if (trip.status == TripStatus.assigned)
          CancelSection(order: order, trip: trip),
        if (trip.status == TripStatus.assigned ||
            trip.status == TripStatus.inTransit)
          ConditionChangeDemo(orderId: order.id),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.order, required this.status});

  final Order order;
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final done = status == TripStatus.completed;
    final warn = status == TripStatus.disputed;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${order.originRegion} → ${order.destinationRegion}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: warn
                      ? AppColors.warningSoft
                      : done
                          ? AppColors.surfaceMuted
                          : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: warn
                            ? AppColors.warningText
                            : done
                                ? AppColors.textChip
                                : AppColors.primaryDark)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('화주 ${order.shipperName} · ${order.itemLabel} · ${order.quantity}',
              style: const TextStyle(color: AppColors.textChip)),
          const SizedBox(height: 4),
          Text('상차 ${order.loading.label}  ·  하차 ${order.unloading.label}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text('${order.priceLabel} · 예상 ${formatWon(order.estimatedFare)}원(부가세 별도)',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// 세로 단계 표시 한 칸.
class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.number,
    required this.title,
    required this.done,
    required this.active,
    required this.child,
    this.last = false,
  });

  final int number;
  final String title;
  final bool done;
  final bool active;
  final Widget? child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done || active ? AppColors.primary : AppColors.borderStrong;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Semantics(
                label: '$number단계 $title ${done ? '완료' : active ? '진행 중' : '대기'}',
                excludeSemantics: true,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.primary : Colors.white,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text('$number',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color)),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                      width: 2,
                      color: done ? AppColors.primary : AppColors.border),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: done || active
                                ? AppColors.textStrong
                                : AppColors.textMuted)),
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 10),
                    child!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 올린 사진 한 장 미리보기.
class _UploadedPhoto extends ConsumerWidget {
  const _UploadedPhoto({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(photoPreviewProvider);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 48, height: 48, child: preview(path)),
        ),
        const SizedBox(width: 10),
        Text('$label 올림',
            style: const TextStyle(color: AppColors.textChip)),
      ],
    );
  }
}

/// 사진을 찍고 ‘올리기’를 눌러 보내는 공통 흐름.
mixin _PhotoSubmit<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  String? photoPath;
  bool sending = false;

  Future<void> capture() async {
    final path = await ref.read(photoCaptureProvider).capture();
    if (path == null || !mounted) return;
    setState(() => photoPath = path);
  }

  Future<void> send(Future<void> Function() action, String doneMessage) async {
    setState(() => sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
    } on TripActionException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}

class _LoadingProofForm extends ConsumerStatefulWidget {
  const _LoadingProofForm({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_LoadingProofForm> createState() => _LoadingProofFormState();
}

class _LoadingProofFormState extends ConsumerState<_LoadingProofForm>
    with _PhotoSubmit {
  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(photoPreviewProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('상차지에서 받은 계근표를 찍어 올려 주세요. 화주 확인 없이 사진만 저장돼요.',
            style: TextStyle(fontSize: 13, color: AppColors.textChip, height: 1.4)),
        const SizedBox(height: 10),
        DocumentCaptureCard(
          title: '상차 계근표',
          icon: Icons.receipt_long_outlined,
          captured: photoPath != null,
          busy: sending,
          onCapture: capture,
          hint: '계근표 사진을 촬영해 주세요',
          capturedText: '촬영 완료 · 올리기를 눌러 주세요',
          preview: photoPath == null ? null : preview(photoPath!),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: photoPath == null || sending
              ? null
              : () => send(
                  () => uploadLoadingProof(ref, widget.orderId, photoPath!),
                  '상차 계근표를 올렸어요. 안전 운행하세요.'),
          child: const Text('상차 계근표 올리기'),
        ),
      ],
    );
  }
}

class _UnloadingProofForm extends ConsumerStatefulWidget {
  const _UnloadingProofForm({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_UnloadingProofForm> createState() =>
      _UnloadingProofFormState();
}

class _UnloadingProofFormState extends ConsumerState<_UnloadingProofForm>
    with _PhotoSubmit {
  UnloadingProofKind _kind = UnloadingProofKind.weighTicket;

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(photoPreviewProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
            '하차지 계근표를 찍어 올리면 바로 화주에게 전달돼요. 계근표가 없으면 하차지 공장 사무실 직원의 서명을 받아 찍어 주세요.',
            style: TextStyle(fontSize: 13, color: AppColors.textChip, height: 1.4)),
        const SizedBox(height: 10),
        SegmentedButton<UnloadingProofKind>(
          segments: [
            for (final k in UnloadingProofKind.values)
              ButtonSegment(value: k, label: Text(k.label)),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _kind = s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        DocumentCaptureCard(
          title: _kind.label,
          icon: _kind == UnloadingProofKind.weighTicket
              ? Icons.receipt_long_outlined
              : Icons.draw_outlined,
          captured: photoPath != null,
          busy: sending,
          onCapture: capture,
          hint: _kind == UnloadingProofKind.weighTicket
              ? '계근표 사진을 촬영해 주세요'
              : '직원이 서명한 종이를 촬영해 주세요',
          capturedText: '촬영 완료 · 보내기를 눌러 주세요',
          preview: photoPath == null ? null : preview(photoPath!),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: photoPath == null || sending
              ? null
              : () => send(
                  () => uploadUnloadingProof(
                      ref, widget.orderId, photoPath!, _kind),
                  '하차 증빙을 화주에게 보냈어요.'),
          child: const Text('하차 증빙 보내기'),
        ),
      ],
    );
  }
}

class _Confirmation extends ConsumerWidget {
  const _Confirmation({required this.trip});
  final TripProgress trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputed = trip.status == TripStatus.disputed;
    final demo = ref.watch(isDemoRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: disputed ? AppColors.warningBg : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            disputed
                ? '화주가 하차 증빙에 ‘아니오’라고 답해 고객센터가 확인하고 있어요. 고객센터 안내를 기다려 주세요.'
                : '화주가 하차 증빙을 확인하고 있어요. 30분 안에 답이 없으면 화주에게 다시 알리고, '
                    '1시간 10분 동안 답이 없으면 고객센터가 확인해요.',
            style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: disputed ? AppColors.warningText : AppColors.primaryDark),
          ),
        ),
        if (demo && !disputed) ...[
          const SizedBox(height: 12),
          const DemoNotice(),
          const SizedBox(height: 8),
          const Text('시연용: 화주 앱이 아직 없어 화주의 답을 대신 누를 수 있어요.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      simulateShipperResponse(ref, trip.orderId, false),
                  child: const Text('화주: 아니오'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      simulateShipperResponse(ref, trip.orderId, true),
                  child: const Text('화주: 예'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Completed extends StatelessWidget {
  const _Completed();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('화주가 하차 증빙을 확인했어요. 운행 기록에서 볼 수 있고, 화주가 별점을 주면 함께 보여요.',
            style: TextStyle(fontSize: 13, color: AppColors.textChip, height: 1.4)),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.driverMyOrders),
          child: const Text('내 오더로 가기'),
        ),
      ],
    );
  }
}
