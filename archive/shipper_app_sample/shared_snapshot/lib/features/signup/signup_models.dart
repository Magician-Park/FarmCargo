import '../auth/account_role.dart';

/// 회원가입 단계. 역할마다 단계가 다르다.
enum SignupStep {
  guide('안내'),
  account('계정'),
  identity('본인 인증'),
  phone('휴대폰'),
  terms('약관'),
  password('비밀번호'),
  vehicle('차량'),
  documents('서류'),
  idCard('신분증'),
  business('사업자'),
  complete('완료');

  const SignupStep(this.label);
  final String label;

  /// 상단 단계 표시에 넣지 않는 단계(안내 창과 완료 화면).
  bool get showsInIndicator => this != guide && this != complete;
}

extension SignupSteps on AccountRole {
  /// 안내·완료 화면을 포함한 전체 단계.
  /// 차주 순서는 요구사항 3절 ‘차주 회원가입 흐름’(사용자 결정 2026-11-04·05·09·11)을 따른다.
  List<SignupStep> get signupSteps => switch (this) {
        AccountRole.driver => const [
            SignupStep.guide,
            SignupStep.identity,
            SignupStep.terms,
            SignupStep.password,
            SignupStep.vehicle,
            SignupStep.documents,
            SignupStep.complete,
          ],
        AccountRole.shipper => const [
            SignupStep.account,
            SignupStep.phone,
            SignupStep.terms,
            SignupStep.idCard,
            SignupStep.business,
            SignupStep.complete,
          ],
      };
}

class AccountInfo {
  final String name;
  final String password;

  const AccountInfo({
    required this.name,
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

/// 차주 차량 종류와 톤급. 사용자가 정한 선택지로 한정한다(2026-11-04).
enum VehicleType {
  cargo('일반 카고(25톤)'),
  tractor('트랙터(추레라)(25톤)'),
  walkingDump('워킹 덤프(워킹카)(25톤)'),
  dumpTruck('덤프트럭(25톤)'),
  other('기타');

  const VehicleType(this.label);
  final String label;
}

/// 차주 차량 정보.
class VehicleInfo {
  final String plateNumber;
  final VehicleType type;
  final String otherType; // 기타를 고르면 직접 입력한 차종·톤급

  const VehicleInfo({
    required this.plateNumber,
    required this.type,
    this.otherType = '',
  });

  String get typeLabel => type == VehicleType.other ? otherType : type.label;
}

/// 차주가 사진으로 제출하는 서류(사용자 결정 2026-11-05: 화물운송종사자격증은 받지 않음).
enum DriverDocument {
  businessRegistration('사업자등록증'),
  bankbook('통장 사본'),
  driverLicense('운전면허증');

  const DriverDocument(this.label);
  final String label;
}

/// 차주 서류 제출 단계의 입력값.
class DriverDocuments {
  final Map<DriverDocument, String> photoPaths;
  final String taxInvoiceEmail; // 전자세금계산서 전용 이메일
  final bool consignmentAgreed; // 세금계산서 위수탁 동의

  const DriverDocuments({
    required this.photoPaths,
    required this.taxInvoiceEmail,
    required this.consignmentAgreed,
  });
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

class SignupRequest {
  final AccountRole role;
  final AccountInfo account;
  final String phone;
  final Set<TermsItem> agreedTerms;
  final VehicleInfo? vehicle; // 차주
  final DriverDocuments? driverDocuments; // 차주
  final IdCard? idCard; // 화주
  final String? businessPhotoPath; // 화주 사업자등록증 사진

  const SignupRequest({
    required this.role,
    required this.account,
    required this.phone,
    required this.agreedTerms,
    this.vehicle,
    this.driverDocuments,
    this.idCard,
    this.businessPhotoPath,
  });
}
