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

## 코드 구조

상태관리는 Riverpod, 라우팅은 go_router를 사용합니다.

```
lib/
  main.dart, app.dart          # 진입점 (ProviderScope + MaterialApp.router)
  core/
    router/app_router.dart     # 경로 정의, 로그인/역할 기반 redirect
    theme/app_theme.dart       # AppColors, AppTheme
    utils/, widgets/           # 공용 포맷터와 위젯 (InfoChip, SectionCard, AsyncValueView)
  features/
    auth/                      # 역할, 데모 로그인 상태, 로그인 화면
    orders/                    # Order/Shipment 모델, OrderRepository(+Mock), providers
    driver/                    # 차주 홈, 오더 상세
    shipper/                   # 화주 홈
```

서버 연동 시 `OrderRepository`의 구현체만 만들어 `orderRepositoryProvider`에서 교체합니다.

## 현재 상태

로그인(역할 선택, 데모 인증) → 차주 홈 → 오더 상세, 화주 홈까지 구현된 데모입니다.
서버 연동, 실제 인증, 오더 수락 로직 등은 아직 없습니다.

## 앱 식별자

- Application ID / namespace: `com.farmcargo.app` (임시값)
- 스토어 등록 전에 실제 소유 도메인 기준으로 확정해야 합니다. 변경 시
  `android/app/build.gradle.kts`와 `android/app/src/main/kotlin/` 하위 패키지 폴더·`MainActivity.kt`의 `package`를 함께 바꿉니다.

## 릴리스 서명 (TODO)

현재 release 빌드는 debug 키로 서명됩니다. 배포 전에 keystore를 만들고 `android/key.properties`를 설정해야 합니다
(`key.properties`, `*.jks`, `*.keystore`는 `.gitignore`에 포함되어 있습니다).
