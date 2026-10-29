# 팜카고 저장소 작업 안내

## 제품

팜카고는 농가·화주와 화물차주를 연결하는 농업 화물 배차 앱이다. 주요 흐름은 역할 선택, 최소 회원가입, 본인·차량 인증, 운송 요청, 추천 오더, 배차 상세, 운송 진행, 정산이다.

## 코드 표면

- `app/lib/`: Flutter 실제 앱. 제품 기능을 구현할 때 우선 수정한다.
- `farm-cargo-mockups.html`: 16개 핵심 화면의 전체 설계 보드.
- `app-demo.html`: 브라우저에서 클릭할 수 있는 PWA 데모.
- `index.html`, `workspace.css`, `workspace.js`: 프롬프트와 데모를 나란히 보여주는 로컬 개발 워크스페이스.
- `scripts/dev-server.mjs`: 외부 패키지가 필요 없는 로컬 서버.

## 작업 원칙

1. 기존 한국어 제품 문구와 농업 화물 도메인 맥락을 유지한다.
2. 실제 앱 기능은 Flutter 코드에 구현하고, 필요하면 목업과 클릭 데모도 함께 갱신한다.
3. 디자인은 현재 브랜드 파랑(`#2563EB`), 밝은 회색 배경, 큰 터치 영역, 쉬운 한국어 표현을 따른다.
4. 루트 프롬프트 입력 UI는 로컬 메모/복사 도구다. API 키나 Codex 실행을 브라우저에 직접 노출하지 않는다.
5. 기존 미추적 Flutter 플랫폼 파일은 사용자 작업으로 간주해 삭제하거나 덮어쓰지 않는다.

## 검증

- 웹 워크스페이스: `npm run check`, 이후 `npm start`
- Flutter: `cd app && flutter analyze && flutter test`
- 화면 흐름 변경 시 `farm-cargo-mockups.html`과 `app-demo.html`의 관련 경로도 확인한다.
