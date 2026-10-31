import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/account_role.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_repository.dart';
import 'signup_models.dart';

/// 회원가입 진행 중 입력값. 이전 단계로 돌아가도 값이 유지된다.
class SignupState {
  final AccountRole role;
  final SignupStep step;
  final AccountInfo? account;
  final String? verifiedPhone;
  final Set<TermsItem> agreedTerms;
  final FreightLicense? license;
  final IdCard? idCard;
  final BusinessRegistration? business;
  final bool submitting;
  final String? error;

  const SignupState({
    required this.role,
    this.step = SignupStep.account,
    this.account,
    this.verifiedPhone,
    this.agreedTerms = const {},
    this.license,
    this.idCard,
    this.business,
    this.submitting = false,
    this.error,
  });

  List<SignupStep> get steps => role.signupSteps;
  int get stepIndex => steps.indexOf(step);

  SignupState copyWith({
    SignupStep? step,
    AccountInfo? account,
    String? verifiedPhone,
    Set<TermsItem>? agreedTerms,
    FreightLicense? license,
    IdCard? idCard,
    BusinessRegistration? business,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) =>
      SignupState(
        role: role,
        step: step ?? this.step,
        account: account ?? this.account,
        verifiedPhone: verifiedPhone ?? this.verifiedPhone,
        agreedTerms: agreedTerms ?? this.agreedTerms,
        license: license ?? this.license,
        idCard: idCard ?? this.idCard,
        business: business ?? this.business,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
      );
}

class SignupController extends Notifier<SignupState> {
  SignupController(this.role);

  final AccountRole role;

  @override
  SignupState build() => SignupState(role: role);

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

  void submitAccount(AccountInfo info) {
    state = state.copyWith(account: info);
    _goTo(1);
  }

  void setPhoneVerified(String phone) =>
      state = state.copyWith(verifiedPhone: phone);

  void submitPhone() => _goTo(1);

  void submitTerms(Set<TermsItem> agreed) {
    state = state.copyWith(agreedTerms: agreed);
    _goTo(1);
  }

  void submitLicense(FreightLicense license) {
    state = state.copyWith(license: license);
    _goTo(1);
  }

  void submitIdCard(IdCard idCard) {
    state = state.copyWith(idCard: idCard);
    _goTo(1);
  }

  /// 마지막 입력 단계. 서버에 가입을 요청하고 성공하면 완료 화면으로 간다.
  Future<void> submitBusiness(BusinessRegistration business) async {
    state =
        state.copyWith(business: business, submitting: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).register(SignupRequest(
            role: role,
            account: state.account!,
            phone: state.verifiedPhone!,
            agreedTerms: state.agreedTerms,
            license: state.license,
            idCard: state.idCard,
            business: business,
          ));
      state = state.copyWith(submitting: false);
      _goTo(1);
    } on AuthException catch (e) {
      // 이메일/휴대폰 중복 등은 계정 단계로 돌아가 고치게 한다.
      state = state.copyWith(
          submitting: false, step: SignupStep.account, error: e.message);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final signupControllerProvider = NotifierProvider.autoDispose
    .family<SignupController, SignupState, AccountRole>(SignupController.new);
