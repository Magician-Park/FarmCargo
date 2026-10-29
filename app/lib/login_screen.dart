import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AccountRole { shipper, driver }

/// 목업의 역할 선택과 휴대폰 진입 흐름. 실제 인증은 서버 연동 전까지 제공하지 않는다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final ValueChanged<AccountRole> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  AccountRole _role = AccountRole.shipper;
  bool _showPhoneForm = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.onLogin(_role);
  }

  void _backToRoles() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showPhoneForm = false;
      _phoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showPhoneForm,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showPhoneForm) _backToRoles();
      },
      child: Scaffold(
        appBar: _showPhoneForm
            ? AppBar(
                title: const Text('휴대폰 로그인'),
                leading: IconButton(
                  tooltip: '역할 선택으로 돌아가기',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _backToRoles,
                ),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: _showPhoneForm ? _phoneForm() : _roleSelection(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        const Text('팜카고',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('농사짐, 이제 앱으로 부르세요',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 36),
        const Text('어떻게 이용하시나요?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _RoleCard(
          title: '짐을 보내요',
          subtitle: '화주·농가 · 곡물·퇴비·비료 운송을 요청해요',
          icon: Icons.grass_rounded,
          iconColor: const Color(0xFF15803D),
          selected: _role == AccountRole.shipper,
          onTap: () => setState(() => _role = AccountRole.shipper),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          title: '화물차로 운송해요',
          subtitle: '차주 · 오더 받고 다음 날 바로 정산받아요',
          icon: Icons.local_shipping_outlined,
          iconColor: const Color(0xFF2563EB),
          selected: _role == AccountRole.driver,
          onTap: () => setState(() => _role = AccountRole.driver),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFEE500),
            foregroundColor: const Color(0xFF191919),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('카카오 로그인은 준비 중이에요. 휴대폰 데모 로그인을 이용해 주세요.'),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_rounded, size: 20),
          label: const Text('카카오로 시작'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => setState(() => _showPhoneForm = true),
          icon: const Icon(Icons.phone_android_rounded, size: 20),
          label: const Text('휴대폰 번호로 시작'),
        ),
        const SizedBox(height: 16),
        const Text(
          '데모 앱 · 실제 인증 없이 화면을 체험할 수 있어요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      ],
    );
  }

  Widget _phoneForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(_role == AccountRole.shipper
                  ? Icons.grass_rounded
                  : Icons.local_shipping_outlined),
              label: Text(_role == AccountRole.shipper ? '화주·농가' : '차주'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('휴대폰 번호로 로그인',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('사용하시는 휴대폰 번호를 입력해 주세요.',
              style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 28),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: const InputDecoration(
              labelText: '휴대폰 번호',
              hintText: '01012345678',
              prefixIcon: Icon(Icons.phone_android_rounded),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (!RegExp(r'^010\d{8}$').hasMatch(value ?? '')) {
                return '010으로 시작하는 휴대폰 번호 11자리를 입력해 주세요.';
              }
              return null;
            },
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '현재는 데모 로그인으로 진행돼요.\n'
              '문자 인증이나 회원가입 없이 선택한 역할의 홈으로 이동합니다. '
              '입력한 번호는 저장하거나 전송하지 않습니다.',
              style: TextStyle(color: Color(0xFF1E40AF), height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _login,
            child: const Text('데모 로그인'),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          foregroundColor: const Color(0xFF1F2937),
          backgroundColor: selected ? const Color(0xFFEFF6FF) : Colors.white,
          side: BorderSide(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
