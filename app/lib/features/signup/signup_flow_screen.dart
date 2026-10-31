import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/navigation.dart';
import '../../core/theme/app_theme.dart';
import '../auth/account_role.dart';
import 'signup_controller.dart';
import 'signup_models.dart';
import 'step_indicator.dart';
import 'steps/account_step.dart';
import 'steps/business_step.dart';
import 'steps/complete_step.dart';
import 'steps/id_card_step.dart';
import 'steps/license_step.dart';
import 'steps/phone_step.dart';
import 'steps/terms_step.dart';

/// 차주/화주 회원가입 화면. 한 화면 안에서 단계가 바뀌고, 뒤로 가면 이전 단계로 돌아간다.
class SignupFlowScreen extends ConsumerWidget {
  const SignupFlowScreen({super.key, required this.role});

  final AccountRole role;

  static const _titles = {
    SignupStep.account: '계정 정보를 입력해 주세요',
    SignupStep.phone: '휴대폰 번호를 인증해 주세요',
    SignupStep.terms: '약관에 동의해 주세요',
    SignupStep.license: '화물운송종사자격증을 인증해 주세요',
    SignupStep.idCard: '신분증을 인증해 주세요',
    SignupStep.business: '사업자등록증을 인증해 주세요',
    SignupStep.complete: '',
  };

  void _back(BuildContext context, WidgetRef ref) {
    if (ref.read(signupControllerProvider(role)).step == SignupStep.complete) {
      context.go(AppRoutes.welcome);
      return;
    }
    final moved = ref.read(signupControllerProvider(role).notifier).back();
    if (!moved) popOrGo(context, AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupControllerProvider(role));

    ref.listen(signupControllerProvider(role).select((s) => s.error),
        (previous, error) {
      if (error == null) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      ref.read(signupControllerProvider(role).notifier).clearError();
    });

    final complete = state.step == SignupStep.complete;
    final stepLabels = [
      for (final s in state.steps)
        if (s != SignupStep.complete) s.label,
    ];

    return PopScope(
      // 단계가 있으면 시스템 뒤로가기도 이전 단계로 돌아간다.
      canPop: state.stepIndex == 0 && !state.submitting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '뒤로가기',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _back(context, ref),
          ),
          title: Text.rich(TextSpan(
            text: '회원가입',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: ' · ${role.label}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted),
              ),
            ],
          )),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (!complete) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: StepIndicator(
                      labels: stepLabels, current: state.stepIndex),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_titles[state.step]!,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              Expanded(child: _stepBody(state.step)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody(SignupStep step) => switch (step) {
        SignupStep.account => AccountStep(key: ValueKey(step), role: role),
        SignupStep.phone => PhoneStep(key: ValueKey(step), role: role),
        SignupStep.terms => TermsStep(key: ValueKey(step), role: role),
        SignupStep.license => LicenseStep(key: ValueKey(step)),
        SignupStep.idCard => IdCardStep(key: ValueKey(step)),
        SignupStep.business => BusinessStep(key: ValueKey(step), role: role),
        SignupStep.complete => CompleteStep(key: ValueKey(step)),
      };
}
