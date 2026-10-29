# 팜카고 Flutter 앱

농업 화물 배차 앱의 실제 제품 코드입니다. 차주 로비와 추천 오더 상세, 화주 홈과 비료·사료 운송 요청 흐름이 구현되어 있습니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

## 점검

```bash
flutter analyze
flutter test
```

## 주요 파일

- `lib/main.dart`: 앱 진입점과 공통 테마
- `lib/lobby_screen.dart`: 차주 홈과 추천 오더 목록
- `lib/detail_screen.dart`: 선택한 오더의 상세 정보
- `lib/order.dart`: 오더 모델과 개발용 샘플 데이터
- `lib/shipper_home_screen.dart`: 농가·화주 홈과 운송 요청 진입
- `lib/fertilizer_request_screen.dart`: 비료 종류·포장·장비·안전 조건 입력
- `lib/feed_request_screen.dart`: 사료 종류·적재·교차오염·농장 방역 조건 입력
