import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// 화주가 비료 운송에 필요한 포장, 수량, 장비, 안전 조건을 입력하는 화면.
class FertilizerRequestScreen extends StatefulWidget {
  const FertilizerRequestScreen({super.key});

  @override
  State<FertilizerRequestScreen> createState() =>
      _FertilizerRequestScreenState();
}

class _FertilizerRequestScreenState extends State<FertilizerRequestScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _fertilizerTypes = ['복합비료', '요소·질소질', '유기질비료', '토양개량제'];
  static const _packages = ['파렛트', '톤백', '포대', '액상 탱크'];

  String fertilizerType = _fertilizerTypes.first;
  String packageType = _packages.first;
  int quantity = 8;
  bool loadingForklift = true;
  bool unloadingForklift = false;
  bool nonHazardousConfirmed = true;

  String get unit => switch (packageType) {
        '파렛트' => '개',
        '톤백' => '백',
        '포대' => '포',
        _ => 'L',
      };

  String get recommendedVehicle =>
      packageType == '액상 탱크' ? '액상 전용 탱크로리' : '5톤 윙바디 · 리프트';

  String get estimatedPrice => packageType == '액상 탱크' ? '협의 필요' : '190,000원';

  void _submit() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon:
            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 36),
        title: const Text('비료 운송 요청을 등록했어요'),
        content: Text(
          '$fertilizerType · $packageType $quantity$unit 조건으로\n배차 가능한 차량을 찾기 시작합니다.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(AppRoutes.shipperHome);
            },
            child: const Text('화주 홈으로'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운송 요청하기'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        children: [
          const _StepHeader(step: '1 / 4', title: '무엇을 보내시나요?'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _CargoChip('🌾 곡물'),
              const _CargoChip('💩 퇴비'),
              const _CargoChip('🧪 비료', selected: true),
              _CargoChip(
                '🐄 사료',
                onTap: () => context.pushReplacement(AppRoutes.feedRequest),
              ),
              const _CargoChip('📦 농자재'),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('비료 종류'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fertilizerTypes
                .map((type) => ChoiceChip(
                      label: Text(type),
                      selected: fertilizerType == type,
                      onSelected: (_) => setState(() => fertilizerType = type),
                    ))
                .toList(),
          ),
          const SizedBox(height: 7),
          const Text('제품명이나 제조사는 차주에게 전달되는 요청 메모에서 추가할 수 있어요.',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 22),
          const _SectionTitle('포장 형태'),
          const SizedBox(height: 9),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: .9,
            children: _packages.map((item) {
              final selected = item == packageType;
              final icon = switch (item) {
                '파렛트' => Icons.view_in_ar_outlined,
                '톤백' => Icons.inventory_2_outlined,
                '포대' => Icons.shopping_bag_outlined,
                _ => Icons.water_drop_outlined,
              };
              return InkWell(
                onTap: () => setState(() {
                  packageType = item;
                  quantity = item == '액상 탱크' ? 5000 : 8;
                }),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? _blue : const Color(0xFFE5E7EB),
                        width: selected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: selected ? _blue : Colors.grey),
                      const SizedBox(height: 6),
                      Text(item,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: selected ? _blue : Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Expanded(
                    child: Text('수량',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                IconButton(
                  onPressed: quantity > (packageType == '액상 탱크' ? 500 : 1)
                      ? () => setState(
                          () => quantity -= packageType == '액상 탱크' ? 500 : 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 72,
                  child: Text('$quantity$unit',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => setState(
                      () => quantity += packageType == '액상 탱크' ? 500 : 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('상·하차 장소와 장비'),
          const SizedBox(height: 9),
          const _LocationCard(
            icon: Icons.circle,
            iconColor: _blue,
            label: '상차지',
            address: '전북 전주시 덕진구 ○○비료 물류창고',
          ),
          const SizedBox(height: 8),
          _EquipmentSwitch(
            title: '상차 지게차 있음',
            subtitle: '파렛트 상차 시간을 줄일 수 있어요',
            value: loadingForklift,
            onChanged: (value) => setState(() => loadingForklift = value),
          ),
          const SizedBox(height: 10),
          const _LocationCard(
            icon: Icons.location_on,
            iconColor: Color(0xFFEF4444),
            label: '하차지',
            address: '전북 김제시 죽산면 우리 농장',
          ),
          const SizedBox(height: 8),
          _EquipmentSwitch(
            title: '하차 지게차 있음',
            subtitle:
                unloadingForklift ? '일반 윙바디 배차가 가능해요' : '리프트 또는 크레인 차량을 찾아드려요',
            value: unloadingForklift,
            onChanged: (value) => setState(() => unloadingForklift = value),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('제품 안전 확인'),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: nonHazardousConfirmed,
                    activeColor: const Color(0xFF16A34A),
                    title: const Text('일반 비료임을 제품 라벨로 확인했어요',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('위험물·유해화학물질 표기가 있는 제품은 별도 차량으로 배차합니다.',
                        style: TextStyle(fontSize: 10)),
                    onChanged: (value) =>
                        setState(() => nonHazardousConfirmed = value ?? false),
                  ),
                ),
                if (!nonHazardousConfirmed)
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Row(
                      children: [
                        Icon(Icons.support_agent,
                            color: Color(0xFFC2410C), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('담당자가 제품 라벨과 물질안전보건자료를 확인한 뒤 차량을 추천해요.',
                              style: TextStyle(
                                  color: Color(0xFF9A3412), fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF93C5FD)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recommendedVehicle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text('내일 오전 상차 · 예상 운임 $estimatedPrice',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('이 조건으로 비료 운송 요청하기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(step,
            style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
}

class _CargoChip extends StatelessWidget {
  const _CargoChip(this.label, {this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 3),
                Text(address,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 19),
        ],
      ),
    );
  }
}

class _EquipmentSwitch extends StatelessWidget {
  const _EquipmentSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(14)),
      value: value,
      onChanged: onChanged,
      title: Text(title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
    );
  }
}
