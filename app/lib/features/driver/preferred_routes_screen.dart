import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'preferred_routes.dart';

/// 설정 > 선호 구간 설정. 상차 시·도와 하차 시·도를 골라 구간을 등록한다.
class PreferredRoutesScreen extends ConsumerStatefulWidget {
  const PreferredRoutesScreen({super.key});

  @override
  ConsumerState<PreferredRoutesScreen> createState() =>
      _PreferredRoutesScreenState();
}

class _PreferredRoutesScreenState extends ConsumerState<PreferredRoutesScreen> {
  String? _from;
  String? _to;

  void _add() {
    final added = ref
        .read(preferredRoutesProvider.notifier)
        .add(PreferredRoute(_from!, _to!));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added ? '선호 구간을 추가했어요.' : '이미 등록한 구간이에요.')));
    if (added) setState(() => _from = _to = null);
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(preferredRoutesProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('선호 구간 설정',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('자주 다니는 구간을 등록하면 오더 찾기에서 ‘선호 구간만’을 켜서 그 구간의 오더만 볼 수 있어요.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProvinceField(
                  label: '상차 지역',
                  value: _from,
                  onChanged: (v) => setState(() => _from = v),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: AppColors.primary),
              ),
              Expanded(
                child: _ProvinceField(
                  label: '하차 지역',
                  value: _to,
                  onChanged: (v) => setState(() => _to = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _from != null && _to != null ? _add : null,
            icon: const Icon(Icons.add),
            label: const Text('구간 추가'),
          ),
          const SizedBox(height: 24),
          Text('등록한 구간 ${routes.length}개',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (routes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('아직 등록한 구간이 없어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted)),
            )
          else
            for (final r in routes)
              Card(
                elevation: 0,
                color: AppColors.primarySoft,
                child: ListTile(
                  leading: const Icon(Icons.route, color: AppColors.primary),
                  title: Text(r.label,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    tooltip: '${r.label} 삭제',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(preferredRoutesProvider.notifier).remove(r),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ProvinceField extends StatelessWidget {
  const _ProvinceField(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // 추가한 뒤 선택을 비우면 새로 그리도록 값으로 키를 준다.
      key: ValueKey(value),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final p in provinces) DropdownMenuItem(value: p, child: Text(p)),
      ],
      onChanged: onChanged,
    );
  }
}
