import '../auth/account_role.dart';

/// 회원가입 단계. 역할마다 서류 단계가 다르다.
enum SignupStep {
  account('계정'),
  phone('휴대폰'),
  terms('약관'),
  license('자격증'),
  idCard('신분증'),
  business('사업자'),
  complete('완료');

  const SignupStep(this.label);
  final String label;
}

extension SignupSteps on AccountRole {
  /// 가입 완료 화면을 포함한 전체 단계.
  List<SignupStep> get signupSteps => [
        SignupStep.account,
        SignupStep.phone,
        SignupStep.terms,
        this == AccountRole.driver ? SignupStep.license : SignupStep.idCard,
        SignupStep.business,
        SignupStep.complete,
      ];
}

class AccountInfo {
  final String name;
  final String email;
  final String password;

  const AccountInfo({
    required this.name,
    required this.email,
    required this.password,
  });
}

enum TermsItem {
  age14('만 14세 이상입니다.', required: true),
  service('서비스 이용 약관', required: true),
  brokerage('화물운송 주선약관', required: true),
  privacyCollect('개인정보 수집 및 이용 동의', required: true),
  privacyThirdParty('개인정보 제3자 제공 동의', required: true),
  location('위치기반서비스 이용약관', required: false),
  privacyOptional('개인정보 수집 및 이용 동의', required: false),
  marketing('마케팅정보 앱푸시, SMS 수신 동의', required: false);

  const TermsItem(this.label, {required this.required});
  final String label;
  final bool required;

  /// '팜카고 이용약관 및 동의사항' 묶음에 속하는 항목.
  static const serviceGroup = [
    service,
    brokerage,
    privacyCollect,
    privacyThirdParty,
  ];

  static final requiredItems = values.where((t) => t.required).toSet();
}

/// 화물운송종사자격증.
class FreightLicense {
  final String name;
  final String birthDate; // yyyy-MM-dd
  final String licenseNumber;
  final String acquiredDate; // yyyy-MM-dd

  const FreightLicense({
    required this.name,
    required this.birthDate,
    required this.licenseNumber,
    required this.acquiredDate,
  });

  static const empty = FreightLicense(
      name: '', birthDate: '', licenseNumber: '', acquiredDate: '');
}

/// 주민등록증.
class IdCard {
  final String name;
  final String residentNumber; // ######-#######
  final String address;
  final String issuedDate; // yyyy-MM-dd

  const IdCard({
    required this.name,
    required this.residentNumber,
    required this.address,
    required this.issuedDate,
  });

  static const empty =
      IdCard(name: '', residentNumber: '', address: '', issuedDate: '');
}

/// 사업자등록증.
class BusinessRegistration {
  final String registrationNumber; // ###-##-#####
  final String companyName; // 상호
  final String representativeName; // 성명
  final String birthDate;
  final String openedDate; // 개업 연월일
  final String address; // 사업장 소재지
  final String businessType; // 사업의 종류(업태/종목)
  final String issueReason; // 발급사유
  final String coRepresentative; // 공동사업자
  final bool? isConsolidatedTax; // 사업자 단위 과세 적용사업자 여부. null이면 미선택
  final String taxInvoiceEmail; // 전자세금계산서 전용 전자우편주소
  final String issuedDate;
  final String taxOffice; // 관할 세무서 (차주만)

  const BusinessRegistration({
    required this.registrationNumber,
    required this.companyName,
    required this.representativeName,
    required this.birthDate,
    required this.openedDate,
    required this.address,
    required this.businessType,
    required this.issueReason,
    required this.coRepresentative,
    required this.isConsolidatedTax,
    required this.taxInvoiceEmail,
    required this.issuedDate,
    required this.taxOffice,
  });

  static const empty = BusinessRegistration(
    registrationNumber: '',
    companyName: '',
    representativeName: '',
    birthDate: '',
    openedDate: '',
    address: '',
    businessType: '',
    issueReason: '',
    coRepresentative: '',
    isConsolidatedTax: null,
    taxInvoiceEmail: '',
    issuedDate: '',
    taxOffice: '',
  );
}

class SignupRequest {
  final AccountRole role;
  final AccountInfo account;
  final String phone;
  final Set<TermsItem> agreedTerms;
  final FreightLicense? license; // 차주
  final IdCard? idCard; // 화주
  final BusinessRegistration business;

  const SignupRequest({
    required this.role,
    required this.account,
    required this.phone,
    required this.agreedTerms,
    required this.license,
    required this.idCard,
    required this.business,
  });
}
