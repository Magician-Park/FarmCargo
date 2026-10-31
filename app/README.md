# 팜카고 앱 (Flutter)

## 개발 환경

- Flutter **stable 최신** (Dart SDK 포함) — <https://docs.flutter.dev/get-started/install>
- JDK **17 이상** (Android Studio 번들 JDK 사용 권장)
- Android Studio + **Flutter / Dart 플러그인**
- 빌드 설정이 최신 툴체인을 전제로 합니다: AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0

## 처음 실행하기

1. Android Studio에서 저장소 루트가 아니라 **`app/` 폴더**를 엽니다.
2. `Settings > Languages & Frameworks > Flutter`에서 Flutter SDK 경로를 지정합니다.
   그러면 `android/local.properties`(git 제외 파일)가 자동 생성됩니다.
   터미널이라면 `flutter pub get`을 실행해도 됩니다.
3. 터미널에서 환경 점검:

   ```bash
   flutter doctor
   ```

4. 에뮬레이터 또는 실기기를 선택해 실행:

   ```bash
   flutter run
   ```

`gradlew`, `gradle-wrapper.jar`가 없다는 오류가 나면 `app/`에서 `flutter create . --platforms=android`를 실행해 복구합니다(기존 `lib/`는 덮어쓰지 않습니다).

## 검사

```bash
flutter analyze
flutter test
```

## 웹으로 실행

```bash
flutter run -d chrome
```

(`app/web/`에 Flutter Web 설정이 있습니다. 카메라 촬영은 브라우저에서는 파일 선택으로 동작할 수 있습니다.)

## 코드 구조

상태관리는 Riverpod, 라우팅은 go_router를 사용합니다.

```
lib/
  main.dart, app.dart          # 진입점 (ProviderScope + MaterialApp.router)
  core/
    router/                    # 경로 정의, 로그인/역할 기반 redirect
    theme/                     # AppColors, AppTheme
    utils/                     # 포맷터, 검증(validators), 입력 포맷터
    widgets/                   # 공용 위젯 (InfoChip, SectionCard, LabeledTextField, BottomActionBar ...)
  features/
    onboarding/                # 권한 안내, 로비(로그인/회원가입)
    auth/                      # 계정/역할, AuthRepository(+Mock), 로그인 화면
    signup/                    # 차주·화주 회원가입 (한 화면 안에서 단계 전환)
    orders/                    # Order/Shipment 모델, OrderRepository(+Mock)
    driver/                    # 차주 홈, 오더 상세
    shipper/                   # 화주 홈, 곡물·비료·사료 운송 요청 화면
```

서버 연동 시 `AuthRepository`, `OrderRepository`, `DocumentScanner`의 구현체만 만들어
각 provider에서 교체합니다. 지금은 모두 데모(Mock) 구현입니다.

## 회원가입 흐름

권한 안내 → 로비 → (회원가입) 역할 선택 → 단계별 입력 → 가입 완료 → 로비 → 로그인

| 단계 | 차주 | 화주 |
|---|---|---|
| 1 | 이름·이메일·비밀번호 | 이름·이메일·비밀번호 |
| 2 | 휴대폰 문자 인증 | 휴대폰 문자 인증 |
| 3 | 약관 동의 | 약관 동의 |
| 4 | 화물운송종사자격증 촬영·자동입력 | 주민등록증 촬영·자동입력 |
| 5 | 사업자등록증 촬영·자동입력(관할 세무서 포함) | 사업자등록증 촬영·자동입력 |

데모 구현에서는 문자가 발송되지 않고 인증번호 `123456`을 화면에 안내하며, 서류 자동입력은 고정된 샘플 값을 채웁니다.
데모 로그인 계정(앱을 다시 실행하면 가입한 계정은 사라집니다):

- 차주 `driver@farmcargo.test` / `Passw0rd!`
- 화주 `shipper@farmcargo.test` / `Passw0rd!`

## 비밀번호 재설정 흐름

로그인 → '비밀번호를 잊으셨나요?' → 가입 이메일 입력 → 재설정 링크 메일 → 링크(`/reset-password?token=...`) → 새 비밀번호 입력 → 성공 팝업 → 로그인

- 링크는 30분 유효하고 한 번만 쓸 수 있습니다. 만료됐거나 이미 쓴 링크로 재설정하면 "인증시간이 만료되었습니다." 팝업이 뜹니다.
- 가입되지 않은 이메일에도 같은 안내를 보여줍니다(가입 여부 노출 방지).
- 데모에서는 메일이 발송되지 않고 화면의 "메일의 링크 열기" 버튼으로 링크를 엽니다. 실제 메일 링크가 앱을 열려면
  Android App Links(도메인 `assetlinks.json` + 매니페스트 intent-filter) 설정이 추가로 필요합니다.

## 현재 상태

회원가입·로그인·비밀번호 재설정, 차주 홈 → 오더 상세, 화주 홈 → 곡물/비료/사료 운송 요청까지 구현된 데모입니다.
역할(차주/화주)은 로그인한 계정으로 정해지며, 한 계정은 한 역할의 화면만 볼 수 있습니다.
서버 연동, 실제 문자·메일 발송, OCR, 오더 수락 로직 등은 아직 없습니다.

## 앱 식별자

- Application ID / namespace: `com.farmcargo.app` (임시값)
- 스토어 등록 전에 실제 소유 도메인 기준으로 확정해야 합니다. 변경 시
  `android/app/build.gradle.kts`와 `android/app/src/main/kotlin/` 하위 패키지 폴더·`MainActivity.kt`의 `package`를 함께 바꿉니다.

## 릴리스 서명 (TODO)

현재 release 빌드는 debug 키로 서명됩니다. 배포 전에 keystore를 만들고 `android/key.properties`를 설정해야 합니다
(`key.properties`, `*.jks`, `*.keystore`는 `.gitignore`에 포함되어 있습니다).
