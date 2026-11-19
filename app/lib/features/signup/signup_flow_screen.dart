import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/router/navigation.dart';
import '../../core/theme/app_theme.dart';
import 'signup_controller.dart';
import 'signup_models.dart';
import 'step_indicator.dart';
import 'steps/complete_step.dart';
import 'steps/documents_step.dart';
import 'steps/guide_step.dart';
import 'steps/identity_step.dart';
import 'steps/password_step.dart';
import 'steps/terms_step.dart';
import 'steps/vehicle_step.dart';

/// 차주 회원가입 화면. 한 화면 안에서 단계가 바뀌고, 뒤로 가면 이전 단계로 돌아간다.
class SignupFlowScreen extends ConsumerWidget {
  const SignupFlowScreen({super.key});

  static const _titles = {
    SignupStep.guide: '',
    SignupStep.identity: '이름과 휴대폰 번호를 인증해 주세요',
    SignupStep.terms: '약관에 동의해 주세요',
    SignupStep.password: '비밀번호를 정해 주세요',
    SignupStep.vehicle: '차량 정보를 입력해 주세요',
    SignupStep.documents: '서류를 제출해 주세요',
    SignupStep.complete: '',
  };

  void _back(BuildContext context, WidgetRef ref) {
    if (ref.read(signupControllerProvider).step == SignupStep.complete) {
      context.go(AppRoutes.welcome);
      return;
    }
    final moved = ref.read(signupControllerProvider.notifier).back();
    if (!moved) popOrGo(context, AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupControllerProvider);

    ref.listen(signupControllerProvider.select((s) => s.error),
        (previous, error) {
      if (error == null) return;
      // 하단 고정 버튼을 가리지 않도록 버튼 위에 띄운다.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      ));
      ref.read(signupControllerProvider.notifier).clearError();
    });

    final showHeader = state.step.showsInIndicator;
    final stepLabels = [for (final s in state.indicatorSteps) s.label];

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
                text: ' · 차주',
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
              if (showHeader) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: StepIndicator(
                      labels: stepLabels, current: state.indicatorIndex),
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
        SignupStep.guide => GuideStep(key: ValueKey(step)),
        SignupStep.identity => IdentityStep(key: ValueKey(step)),
        SignupStep.terms => TermsStep(key: ValueKey(step)),
        SignupStep.password => PasswordStep(key: ValueKey(step)),
        SignupStep.vehicle => VehicleStep(key: ValueKey(step)),
        SignupStep.documents => DocumentsStep(key: ValueKey(step)),
        SignupStep.complete => CompleteStep(key: ValueKey(step)),
      };
}
