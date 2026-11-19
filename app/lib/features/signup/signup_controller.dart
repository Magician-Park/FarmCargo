import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/account_role.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_repository.dart';
import 'signup_models.dart';

/// 차주 회원가입 진행 중 입력값. 이전 단계로 돌아가도 값이 유지된다.
class SignupState {
  final SignupStep step;
  final String? name;
  final String? password;
  final String? verifiedPhone;
  final Set<TermsItem> agreedTerms;
  final VehicleInfo? vehicle;
  final DriverDocuments? driverDocuments;
  final bool submitting;
  final String? error;

  const SignupState({
    this.step = SignupStep.guide,
    this.name,
    this.password,
    this.verifiedPhone,
    this.agreedTerms = const {},
    this.vehicle,
    this.driverDocuments,
    this.submitting = false,
    this.error,
  });

  List<SignupStep> get steps => SignupStep.values;
  int get stepIndex => steps.indexOf(step);

  /// 상단 단계 표시에 나오는 단계 이름과 현재 위치.
  List<SignupStep> get indicatorSteps =>
      [for (final s in steps) if (s.showsInIndicator) s];
  int get indicatorIndex => indicatorSteps.indexOf(step);

  SignupState copyWith({
    SignupStep? step,
    String? name,
    String? password,
    String? verifiedPhone,
    Set<TermsItem>? agreedTerms,
    VehicleInfo? vehicle,
    DriverDocuments? driverDocuments,
    bool? submitting,
    String? error,
    bool clearError = false,
    bool clearVerifiedPhone = false,
  }) =>
      SignupState(
        step: step ?? this.step,
        name: name ?? this.name,
        password: password ?? this.password,
        verifiedPhone:
            clearVerifiedPhone ? null : (verifiedPhone ?? this.verifiedPhone),
        agreedTerms: agreedTerms ?? this.agreedTerms,
        vehicle: vehicle ?? this.vehicle,
        driverDocuments: driverDocuments ?? this.driverDocuments,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
      );
}

class SignupController extends Notifier<SignupState> {
  @override
  SignupState build() => const SignupState();

  void _goTo(int offset) {
    final steps = state.steps;
    state = state.copyWith(
      step: steps[state.stepIndex + offset],
      clearError: true,
    );
  }

  /// 이전 단계로 돌아간다. 첫 단계이면 false(화면을 닫아야 함).
  bool back() {
    if (state.stepIndex == 0 || state.submitting) return false;
    _goTo(-1);
    return true;
  }

  /// 가입 조건 안내를 확인했다.
  void confirmGuide() => _goTo(1);

  /// 이름 입력과 휴대폰 인증을 마쳤다.
  void submitIdentity(String name) {
    state = state.copyWith(name: name);
    _goTo(1);
  }

  /// 휴대폰 인증 다음 단계에서 비밀번호를 정한다(2026-11-05).
  void submitPassword(String password) {
    state = state.copyWith(password: password);
    _goTo(1);
  }

  void setPhoneVerified(String phone) =>
      state = state.copyWith(verifiedPhone: phone);

  void clearPhoneVerified() => state = state.copyWith(clearVerifiedPhone: true);

  void submitTerms(Set<TermsItem> agreed) {
    state = state.copyWith(agreedTerms: agreed);
    _goTo(1);
  }

  void submitVehicle(VehicleInfo vehicle) {
    state = state.copyWith(vehicle: vehicle);
    _goTo(1);
  }

  /// 마지막 단계. 서류 사진·세금계산서 이메일·위수탁 동의를 받아 가입을 신청한다.
  Future<void> submitDriverDocuments(DriverDocuments documents) async {
    state = state.copyWith(
        driverDocuments: documents, submitting: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).register(SignupRequest(
            role: AccountRole.driver,
            account: AccountInfo(name: state.name!, password: state.password!),
            phone: state.verifiedPhone!,
            agreedTerms: state.agreedTerms,
            vehicle: state.vehicle!,
            driverDocuments: documents,
          ));
      state = state.copyWith(submitting: false);
      _goTo(1);
    } on DuplicatePhoneException catch (e) {
      // 휴대폰 번호가 아이디라 중복이면 본인 인증 단계에서 다른 번호로 다시 인증한다.
      state = state.copyWith(
        submitting: false,
        step: SignupStep.identity,
        clearVerifiedPhone: true,
        error: e.message,
      );
    } on AuthException catch (e) {
      // 그 밖의 가입 오류는 첫 입력 단계로 돌아가 다시 시도하게 한다.
      state = state.copyWith(
          submitting: false, step: SignupStep.identity, error: e.message);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final signupControllerProvider =
    NotifierProvider.autoDispose<SignupController, SignupState>(
        SignupController.new);
