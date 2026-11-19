import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// 화주가 벼·쌀 운송 조건과 인증, 적재 형태를 입력하는 화면.
class GrainRequestScreen extends StatefulWidget {
  const GrainRequestScreen({super.key});

  @override
  State<GrainRequestScreen> createState() => _GrainRequestScreenState();
}

class _GrainRequestScreenState extends State<GrainRequestScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _grainTypes = ['일반 곡물', 'LMO (유전자변형)', '친환경 인증'];
  static const _packages = ['톤백', '벌크', '파렛트', '포대'];

  String grainType = _grainTypes.first;
  String packageType = _packages.first;
  int quantity = 12;
  bool loadingEquipment = false;

  String get unit => switch (packageType) {
        '톤백' => '개',
        '벌크' => '톤',
        '파렛트' => '개',
        _ => '포',
      };

  int get minimumQuantity => 1;

  String get grainGuide => switch (grainType) {
        'LMO (유전자변형)' => 'LMO 운송 승인과 밀폐 적재함을 확인한 차량만 매칭해요.',
        '친환경 인증' => '세척 확인을 마친 차량만 매칭해 친환경 인증 화물을 보호해요.',
        _ => '퇴비·축분 운반 이력이 있는 차량은 자동으로 제외해요.',
      };

  String get recommendedVehicle {
    if (grainType == 'LMO (유전자변형)') {
      return packageType == '벌크' ? 'LMO 승인 벌크 전용차' : 'LMO 승인 밀폐 적재 차량';
    }
    return switch (packageType) {
      '벌크' => '곡물 전용 덤프 · 방수포',
      '파렛트' => '5톤 윙바디 · 리프트',
      '포대' => '2.5톤 카고 · 방수포',
      _ => '5톤 카고 · 크레인',
    };
  }

  String get recommendationDetail => switch (packageType) {
        '벌크' => '$quantity톤 · 곡물 유출 방지 적재함',
        '파렛트' => '$quantity파렛트 · ${loadingEquipment ? '지게차 상차' : '리프트 상차 지원'}',
        '포대' => '$quantity포 · ${loadingEquipment ? '상차 장비 있음' : '수작업 상차 확인'}',
        _ => '톤백 $quantity개 · ${loadingEquipment ? '상차 장비 있음' : '크레인 상차 지원'}',
      };

  void _selectPackage(String value) {
    setState(() {
      packageType = value;
      quantity = switch (value) {
        '벌크' => 5,
        '파렛트' => 8,
        '포대' => 100,
        _ => 12,
      };
    });
  }

  void _submit() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon:
            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 36),
        title: const Text('곡물 운송 요청을 등록했어요'),
        content: Text(
          '$grainType · $packageType $quantity$unit 조건으로\n인증 조건에 맞는 차량을 찾기 시작합니다.',
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
              const _CargoChip('🌾 곡물(벼·쌀)', selected: true),
              const _CargoChip('💩 퇴비·축분'),
              _CargoChip(
                '🧪 비료',
                onTap: () =>
                    context.pushReplacement(AppRoutes.fertilizerRequest),
              ),
              _CargoChip(
                '🐄 사료',
                onTap: () => context.pushReplacement(AppRoutes.feedRequest),
              ),
              const _CargoChip('📦 농자재'),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('곡물 구분'),
          const SizedBox(height: 9),
          Row(
            children: _grainTypes.map((type) {
              final selected = type == grainType;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type == _grainTypes.last ? 0 : 7,
                  ),
                  child: _SelectButton(
                    key: ValueKey('grain-type-$type'),
                    label: type,
                    selected: selected,
                    onTap: () => setState(() => grainType = type),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 9),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _InfoBanner(
              key: ValueKey(grainType),
              icon: grainType == '친환경 인증'
                  ? Icons.eco_outlined
                  : grainType == 'LMO (유전자변형)'
                      ? Icons.verified_user_outlined
                      : Icons.shield_outlined,
              message: grainGuide,
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('어떻게 실려 있나요?'),
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
                '벌크' => Icons.grain_outlined,
                '파렛트' => Icons.view_in_ar_outlined,
                '포대' => Icons.shopping_bag_outlined,
                _ => Icons.inventory_2_outlined,
              };
              return _PackageButton(
                key: ValueKey('package-$item'),
                label: item,
                icon: icon,
                selected: selected,
                onTap: () => _selectPackage(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child:
                      Text('수량', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: '수량 줄이기',
                  onPressed: quantity > minimumQuantity
                      ? () => setState(() => quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 78,
                  child: Text(
                    '$quantity$unit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: '수량 늘리기',
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
            iconColor: _blue,
            label: '상차지',
            address: '전북 김제시 죽산면 ○○리 앞 농로',
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(14),
            ),
            value: loadingEquipment,
            activeTrackColor: _blue,
            title: const Text(
              '상차 장비 있음',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              packageType == '파렛트' ? '지게차 상차가 가능해요' : '지게차·크레인 등 사용 가능',
              style: const TextStyle(fontSize: 10),
            ),
            onChanged: (value) => setState(() => loadingEquipment = value),
          ),
          const SizedBox(height: 10),
          const _LocationCard(
            icon: Icons.location_on,
            iconColor: Color(0xFFEF4444),
            label: '하차지',
            address: '전북 전주시 덕진구 ○○미곡처리장',
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
                      Text(
                        recommendedVehicle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recommendationDetail,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                      ),
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
            child: const Text(
              '이 조건으로 곡물 운송 요청하기',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
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
  Widget build(BuildContext context) => Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            step,
            style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ],
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
}

class _CargoChip extends StatelessWidget {
  const _CargoChip(this.label, {this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
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
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB),
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    selected ? const Color(0xFF1D4ED8) : Colors.grey.shade700,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
}

class _PackageButton extends StatelessWidget {
  const _PackageButton({
    super.key,
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
  Widget build(BuildContext context) => Material(
        color: selected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: selected ? const Color(0xFF2563EB) : Colors.grey),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1D4ED8)
                        : Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11),
              ),
            ),
          ],
        ),
      );
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
  Widget build(BuildContext context) => Container(
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
