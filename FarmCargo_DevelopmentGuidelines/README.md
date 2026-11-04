# 팜카고 개발 규칙

수정일: 2026-11-03
현재 위치: `E:/FarmCargo/FarmCargo_DevelopmentGuidelines`

## 기준 파일과 읽는 순서

**공통 작업·소통 규칙은 저장소 루트의 [AGENTS.md](../AGENTS.md)에 통합했다.** 이 폴더의 `CLAUDE.md`는 같은 기준 파일로 안내하는 짧은 연결 문서다.

| 파일 | 용도 |
|---|---|
| [AGENTS.md](../AGENTS.md) | 공통 규칙·개발 방침(웹 베타 → 앱 출시)·실제 저장소 구조·검증 명령 |
| [requirements.md](docs/requirements.md) | 현재 요구사항·미정 항목·개발 단계 |
| [database.md](docs/rules/database.md) | 데이터 설계·권한·동시성·변경·복구 |
| [frontend.md](docs/rules/frontend.md) | Flutter 화면(웹 베타·앱 출시)·입력·오류·실제 브라우저/기기 검증 |
| [backend.md](docs/rules/backend.md) | 업무 API·서버 권한·외부 연동·실제 저장 |

## 현재 개발 방침

- 최종 목표는 Android·iOS 스토어에 출시하는 앱이다. 베타 테스트가 끝날 때까지는 Flutter Web으로 배포해 브라우저에서 테스트한다.
- 웹과 앱은 같은 Flutter 코드(`app/`)로 만든다. HTML 데모(`app-demo.html` 등)는 설계·시연 프로토타입이다.
- 웹에서 확인한 것이 앱에서도 동작한다고 보장하지 않는다. 카메라·위치·푸시·권한·파일 등은 실기기에서 따로 검증한다.
- 현재 확인한 기술·명령과 미확인한 업무 DB·백엔드·스토어 출시 조건은 `AGENTS.md`에서 구분한다.

## 작업 시작 요청문

```text
E:/FarmCargo/AGENTS.md와 현재 요구사항, 이번 분야의 상세 규칙을 먼저 읽어.
Flutter 하나로 웹 베타를 개발하고 최종은 앱으로 출시한다. 웹에서만 되는 코드는 인터페이스 뒤에 둬.
목적, 변경 범위, 검증 방법과 확인할 사항을 짧게 설명하고 진행해.
미정 사업 정책은 추측해서 구현하지 말고 질문해.
완료하면 변경 내용과 실제 검증 결과를 알려줘.
```

제품 결정의 근거는 Obsidian의 통합 근거·변경·보관 기록에 유지하고, 구현에 쓰는 현재 기준은 `requirements.md`에 갱신한다. 공통 규칙을 두 파일에 중복 관리하지 않는다.
