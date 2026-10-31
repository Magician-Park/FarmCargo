import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/labeled_text_field.dart';
import '../../auth/account_role.dart';
import '../../auth/auth_provider.dart';
import '../signup_controller.dart';

/// 휴대폰 번호 입력 -> 문자 인증번호 전송 -> 인증번호 확인.
class PhoneStep extends ConsumerStatefulWidget {
  const PhoneStep({super.key, required this.role});

  final AccountRole role;

  @override
  ConsumerState<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends ConsumerState<PhoneStep> {
  static const _validity = Duration(minutes: 3);

  final _phone = TextEditingController();
  final _code = TextEditingController();
  Timer? _timer;
  DateTime? _expiresAt;
  bool _sending = false;
  bool _verifying = false;
  String? _demoCode;
  String? _codeError;
  String? _verifiedPhone;

  bool get _codeSent => _expiresAt != null;
  Duration get _remaining {
    final left = _expiresAt?.difference(DateTime.now()) ?? Duration.zero;
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    _verifiedPhone =
        ref.read(signupControllerProvider(widget.role)).verifiedPhone;
    if (_verifiedPhone != null) _phone.text = _verifiedPhone!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    // 번호를 고치면 이전 인증은 무효.
    if (_verifiedPhone != null || _codeSent) {
      _timer?.cancel();
      setState(() {
        _verifiedPhone = null;
        _expiresAt = null;
        _demoCode = null;
        _codeError = null;
        _code.clear();
      });
    }
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final demo =
          await ref.read(authRepositoryProvider).sendPhoneCode(_phone.text);
      if (!mounted) return;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (_remaining == Duration.zero) _timer?.cancel();
      });
      setState(() {
        _expiresAt = DateTime.now().add(_validity);
        _demoCode = demo;
        _codeError = null;
        _code.clear();
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (_remaining == Duration.zero) {
      setState(() => _codeError = '인증 시간이 만료되었어요. 인증번호를 다시 받아 주세요.');
      return;
    }
    setState(() => _verifying = true);
    try {
      final ok = await ref
          .read(authRepositoryProvider)
          .verifyPhoneCode(_phone.text, _code.text);
      if (!mounted) return;
      if (ok) {
        _timer?.cancel();
        ref
            .read(signupControllerProvider(widget.role).notifier)
            .setPhoneVerified(_phone.text);
        setState(() {
          _verifiedPhone = _phone.text;
          _codeError = null;
        });
      } else {
        setState(() => _codeError = '인증번호가 일치하지 않아요.');
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  String _mmss(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final verified = _verifiedPhone != null;
    final expired = _codeSent && _remaining == Duration.zero;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: LabeledTextField(
                        label: '휴대폰 번호',
                        controller: _phone,
                        hint: '01012345678',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onChanged: _onPhoneChanged,
                        validator: (v) => isValidPhone(v)
                            ? null
                            : '010으로 시작하는 11자리 번호를 입력해 주세요.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ListenableBuilder(
                        listenable: _phone,
                        builder: (context, _) => FilledButton(
                          onPressed: isValidPhone(_phone.text) &&
                                  !_sending &&
                                  !verified
                              ? _send
                              : null,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 50)),
                          child: Text(_codeSent ? '재전송' : '인증번호 받기',
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_codeSent && !verified) ...[
                  LabeledTextField(
                    label: '인증번호 6자리',
                    controller: _code,
                    hint: '문자로 받은 번호를 입력해 주세요',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          expired ? '만료' : _mmss(_remaining),
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  if (_codeError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_codeError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  if (_demoCode != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '[데모] 실제 문자는 발송되지 않아요. 인증번호는 $_demoCode 입니다.',
                        style: const TextStyle(
                            color: AppColors.primaryDark, fontSize: 12),
                      ),
                    ),
                  ListenableBuilder(
                    listenable: _code,
                    builder: (context, _) => SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _code.text.length == 6 && !_verifying
                            ? _verify
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('인증번호 확인'),
                      ),
                    ),
                  ),
                ],
                if (verified)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      border: Border.all(color: AppColors.successText),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.successText, size: 20),
                        SizedBox(width: 8),
                        Text('휴대폰 인증이 완료되었어요',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        BottomActionBar(
          label: '다음',
          onPressed: verified
              ? () => ref
                  .read(signupControllerProvider(widget.role).notifier)
                  .submitPhone()
              : null,
        ),
      ],
    );
  }
}
