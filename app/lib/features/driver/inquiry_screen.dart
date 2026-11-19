import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/demo_notice.dart';
import '../orders/inquiry.dart';
import '../orders/order_policy.dart';
import '../orders/orders_providers.dart';
import '../orders/trip.dart';

/// 운행 화면의 ‘화주에게 전달’ 입구. 받은 답이 있으면 개수를 보여 준다.
class InquiryEntry extends ConsumerWidget {
  const InquiryEntry({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(inquiriesProvider(orderId)).value ?? const [];
    final waiting = list.where((q) => !q.answered).length;
    final subtitle = list.isEmpty
        ? '상·하차지 사정이 궁금하면 고객센터가 화주에게 물어봐 드려요.'
        : '보낸 글 ${list.length}건 · 답 기다리는 중 $waiting건';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.primarySoft),
        ),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: const Icon(Icons.forum_outlined, color: AppColors.primary),
          title: const Text('화주에게 전달',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing:
              const Icon(Icons.chevron_right, color: AppColors.borderStrong),
          onTap: () => context.push(AppRoutes.driverInquiry(orderId)),
        ),
      ),
    );
  }
}

/// ‘화주에게 전달’(D06·D07): 차주가 쓴 글을 고객센터가 화주에게 전달하고 답을 앱으로 보낸다.
class InquiryScreen extends ConsumerStatefulWidget {
  const InquiryScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addExample(String text) {
    final now = _controller.text.trim();
    _controller.text = now.isEmpty ? text : '$now\n$text';
    setState(() => _error = null);
  }

  Future<void> _send() async {
    final problem = validateInquiry(_controller.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _sending = true);
    try {
      await sendInquiry(ref, widget.orderId, _controller.text);
      if (!mounted) return;
      _controller.clear();
      setState(() => _error = null);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('고객센터에 보냈어요. 화주 답이 오면 알려 드려요.')));
    } on TripActionException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(widget.orderId)).value;
    final inquiries = ref.watch(inquiriesProvider(widget.orderId));
    final demo = ref.watch(isDemoRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('화주에게 전달',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (order != null) ...[
            Text('${order.originRegion} → ${order.destinationRegion}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('${order.shipperName} · ${order.itemLabel}',
                style: const TextStyle(color: AppColors.textChip)),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '쓴 내용은 고객센터가 화주에게 직접 전달하고, 화주 답을 받아 앱으로 보내 드려요. '
              '화주와 차주의 연락처는 서로 공개하지 않으니 전화번호는 적지 마세요. '
              '급한 일이면 고객센터로 전화해 주세요.',
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: 16),
          const Text('자주 묻는 내용',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in inquiryExamples)
                ActionChip(label: Text(e), onPressed: () => _addExample(e)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            maxLength: inquiryMaxLength,
            decoration: InputDecoration(
              hintText: '예: 하차지 공장 입구에 높이 제한이 있나요?',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send),
            label: const Text('고객센터로 보내기'),
          ),
          const SizedBox(height: 24),
          const Text('보낸 글',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AsyncValueView(
            value: inquiries,
            onRetry: () => ref.invalidate(inquiriesProvider(widget.orderId)),
            builder: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('아직 보낸 글이 없어요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted)),
                  )
                : Column(
                    children: [
                      for (final q in list)
                        _InquiryCard(
                            inquiry: q, orderId: widget.orderId, demo: demo),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _InquiryCard extends ConsumerWidget {
  const _InquiryCard(
      {required this.inquiry, required this.orderId, required this.demo});

  final ShipperInquiry inquiry;
  final String orderId;
  final bool demo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = inquiry;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(formatDeadline(q.sentAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const Spacer(),
              Text(q.statusLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: q.answered
                          ? AppColors.primaryDark
                          : AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(q.message, style: const TextStyle(height: 1.4)),
          if (q.answered) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('화주 답변 · ${formatDeadline(q.answeredAt!)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Text(q.answer!, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ] else if (demo) ...[
            const SizedBox(height: 10),
            const DemoNotice(),
            const SizedBox(height: 6),
            const Text('시연용: 화주 앱·고객센터 화면이 아직 없어 화주 답이 온 것으로 할 수 있어요.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () => simulateInquiryAnswer(ref, orderId, q.id,
                  '(시연용 답변) 도착하면 바로 작업할 수 있어요. 입구가 좁으니 천천히 들어와 주세요.'),
              child: const Text('고객센터: 화주 답 보내기'),
            ),
          ],
        ],
      ),
    );
  }
}
