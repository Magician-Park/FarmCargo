import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// 사료의 적재 형태와 방역·오염 조건에 맞는 차량을 배차하는 화주 요청 화면.
class FeedRequestScreen extends StatefulWidget {
  const FeedRequestScreen({super.key});

  @override
  State<FeedRequestScreen> createState() => _FeedRequestScreenState();
}

class _FeedRequestScreenState extends State<FeedRequestScreen> {
  static const _green = Color(0xFF16A34A);
  static const _feedTypes = ['배합사료', '조사료', '단미사료', 'TMR 사료'];
  static const _packages = ['파렛트 포대', '톤백', '벌크 사일로', '랩핑 곤포'];

  String feedType = _feedTypes.first;
  String packageType = _packages.first;
  int quantity = 10;
  bool pickupForklift = true;
  bool deliveryForklift = false;
  bool moistureProtection = true;
  bool disinfectionRequired = true;

  String get unit => switch (packageType) {
        '파렛트 포대' => '파렛트',
        '톤백' => '백',
        '벌크 사일로' => '톤',
        _ => '롤',
      };

  String get recommendedVehicle => switch (packageType) {
        '벌크 사일로' => '사료 벌크 전용차 · 송풍기',
        '랩핑 곤포' => '5톤 카고 · 크레인',
        _ => deliveryForklift ? '5톤 윙바디' : '5톤 윙바디 · 리프트',
      };

  String get estimatedPrice =>
      packageType == '벌크 사일로' ? '220,000원' : '175,000원';

  void _submit() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: _green, size: 36),
        title: const Text('사료 운송 요청을 등록했어요'),
        content: Text(
          '$feedType · $packageType $quantity$unit 조건으로\n방역 요건을 갖춘 차량을 찾기 시작합니다.',
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
          const Row(
            children: [
              Text('무엇을 보내시나요?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Spacer(),
              Text('1 / 4',
                  style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _CargoChip('🌾 곡물'),
              const _CargoChip('💩 퇴비'),
              _CargoChip('🧪 비료',
                  onTap: () =>
                      context.pushReplacement(AppRoutes.fertilizerRequest)),
              const _CargoChip('🐄 사료', selected: true),
              const _CargoChip('📦 농자재'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.health_and_safety_outlined,
                    color: Color(0xFF15803D), size: 21),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('깨끗하고 건조한 차량만 매칭해요',
                          style: TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 3),
                      Text('퇴비·축분 운반 이력 차량은 제외하고 농장 방역 조건도 함께 확인합니다.',
                          style: TextStyle(
                              color: Color(0xFF15803D), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('사료 종류'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _feedTypes
                .map((type) => ChoiceChip(
                      label: Text(type),
                      selected: feedType == type,
                      onSelected: (_) => setState(() => feedType = type),
                    ))
                .toList(),
          ),
          const SizedBox(height: 7),
          const Text('축종과 제품명은 차주에게 전달되는 요청 메모에서 추가할 수 있어요.',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 22),
          const _SectionTitle('적재 형태'),
          const SizedBox(height: 9),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: .84,
            children: _packages.map((item) {
              final selected = packageType == item;
              final icon = switch (item) {
                '파렛트 포대' => Icons.view_in_ar_outlined,
                '톤백' => Icons.inventory_2_outlined,
                '벌크 사일로' => Icons.grain_outlined,
                _ => Icons.circle_outlined,
              };
              return _PackageCard(
                label: item,
                icon: icon,
                selected: selected,
                onTap: () => setState(() {
                  packageType = item;
                  quantity = item == '벌크 사일로' ? 8 : 10;
                }),
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
                  onPressed:
                      quantity > 1 ? () => setState(() => quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 85,
                  child: Text('$quantity$unit',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => setState(() => quantity++),
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
            iconColor: Color(0xFF2563EB),
            label: '상차지',
            address: '충남 천안시 ○○사료 물류센터',
          ),
          const SizedBox(height: 8),
          _ConditionSwitch(
            title: '상차 지게차 있음',
            subtitle: '파렛트·톤백 상차가 가능해요',
            value: pickupForklift,
            onChanged: (value) => setState(() => pickupForklift = value),
          ),
          const SizedBox(height: 10),
          const _LocationCard(
            icon: Icons.location_on,
            iconColor: Color(0xFFEF4444),
            label: '하차지',
            address: '전북 김제시 죽산면 한우 농장',
          ),
          const SizedBox(height: 8),
          _ConditionSwitch(
            title: '하차 지게차 있음',
            subtitle:
                deliveryForklift ? '일반 윙바디로 하차할 수 있어요' : '리프트 또는 크레인 차량이 필요해요',
            value: deliveryForklift,
            onChanged: (value) => setState(() => deliveryForklift = value),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('사료 보호·농장 방역'),
          const SizedBox(height: 9),
          _ConditionSwitch(
            title: '습기·빗물 차단 차량',
            subtitle: '윙바디 또는 방수포 상태가 확인된 차량만 매칭',
            value: moistureProtection,
            onChanged: (value) => setState(() => moistureProtection = value),
          ),
          const SizedBox(height: 8),
          _ConditionSwitch(
            title: '차량 소독필증 필요',
            subtitle: '축산농장 진입 전 최근 소독 완료 여부를 확인해요',
            value: disinfectionRequired,
            onChanged: (value) => setState(() => disinfectionRequired = value),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_available, color: Color(0xFFC2410C), size: 19),
                SizedBox(width: 9),
                Expanded(
                  child: Text('농장 진입 가능 시간: 내일 09:00–11:00 · 도착 30분 전 연락',
                      style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
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
                const Icon(Icons.auto_awesome, color: Color(0xFF86EFAC)),
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
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('이 조건으로 사료 운송 요청하기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
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
            color: selected ? _FeedRequestScreenState._green : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? _FeedRequestScreenState._green
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

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? _FeedRequestScreenState._green
                  : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? _FeedRequestScreenState._green : Colors.grey),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: selected
                          ? const Color(0xFF15803D)
                          : Colors.grey.shade700,
                      fontSize: 10,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal)),
            ),
          ],
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

class _ConditionSwitch extends StatelessWidget {
  const _ConditionSwitch({
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
      activeTrackColor: _FeedRequestScreenState._green,
      title: Text(title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
    );
  }
}
