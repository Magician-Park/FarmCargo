# 팜카고

농업 화물의 요청, 배차, 운송, 정산 흐름을 설계하고 구현하는 앱 프로젝트입니다. 저장소 루트에는 Codex와 함께 다음 작업을 구체화할 수 있는 분할형 개발 워크스페이스가 포함되어 있습니다.

## 빠른 시작

Node.js 20 이상에서 별도 패키지 설치 없이 실행됩니다.

```bash
npm start
```

브라우저에서 `http://127.0.0.1:4173`을 열면 다음 화면을 볼 수 있습니다.

- 왼쪽: 개발 프롬프트 작성, 로컬 기록, 클립보드 복사
- 오른쪽: 전체 화면 설계와 클릭 가능한 PWA 데모 전환
- 가운데 구분선: 드래그하거나 방향키로 패널 너비 조절

프롬프트는 외부 서버로 전송되지 않습니다. `저장 & 복사` 후 현재 Codex 작업에 붙여넣어 개발을 이어가면 됩니다.

## 프로젝트 구조

```text
.
├── index.html                  # 개발 워크스페이스
├── workspace.css              # 워크스페이스 UI와 반응형 레이아웃
├── workspace.js               # 프롬프트 기록, 미리보기 전환, 리사이저
├── scripts/dev-server.mjs     # 무의존성 로컬 정적 서버
├── farm-cargo-mockups.html    # 전체 핵심 화면 설계
├── app-demo.html              # 클릭 가능한 PWA 시연
├── manifest.json / sw.js      # PWA 설정
└── app/
    ├── lib/                   # Flutter 실제 앱 소스
    ├── test/                  # Flutter 테스트
    └── web/                   # Flutter Web 실행 설정
```

## Flutter 앱 실행

```bash
cd app
flutter pub get
flutter run -d chrome
```

기본 진입점은 `app/lib/main.dart`이며, 현재 차주 로비에서 오더 상세로 이동하는 흐름이 구현되어 있습니다.

## 점검

```bash
npm run check
cd app && flutter analyze && flutter test
```

## 개발 기준

- `app/lib/`: 실제 제품 동작의 기준
- `farm-cargo-mockups.html`: 전체 UX와 시각 설계의 기준
- `app-demo.html`: 이해관계자용 클릭 시연의 기준
- 루트 워크스페이스: 위 세 영역을 비교하고 다음 작업을 작성하는 도구

제품 흐름이 바뀌면 Flutter 코드와 관련 시연 화면이 서로 어긋나지 않는지 함께 확인합니다.
