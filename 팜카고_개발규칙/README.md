# 팜카고 개발 규칙

수정일: 2026-11-03
현재 위치: `E:/FarmCargo/팜카고_개발규칙`

## 기준 파일과 읽는 순서

**공통 작업·소통 규칙은 저장소 루트의 [AGENTS.md](../AGENTS.md)에 통합했다.** 이 폴더의 `CLAUDE.md`는 같은 기준 파일로 안내하는 짧은 연결 문서다.

| 파일 | 용도 |
|---|---|
| [AGENTS.md](../AGENTS.md) | 공통 규칙·웹 우선 방침·실제 저장소 구조·검증 명령 |
| [requirements.md](docs/requirements.md) | 현재 요구사항·미정 항목·개발 단계 |
| [database.md](docs/rules/database.md) | 데이터 설계·권한·동시성·변경·복구 |
| [frontend.md](docs/rules/frontend.md) | 웹 화면·입력·오류·실제 브라우저 검증 |
| [backend.md](docs/rules/backend.md) | 업무 API·서버 권한·외부 연동·실제 저장 |

## 현재 개발 방침

- 웹/PWA 버전을 먼저 개발하고 총점검한다.
- Flutter 앱·Flutter Web 개발은 잠정 중단한다. 명시적인 재개 지시 전까지 기존 앱 코드는 보존한다.
- 총점검 결과를 확인한 뒤 사용자가 앱 전환을 지시하면 전환 방식을 설계한다.
- 현재 확인한 기술·명령과 미확인한 업무 DB·백엔드는 `AGENTS.md`에서 구분한다.

## 작업 시작 요청문

```text
E:/FarmCargo/AGENTS.md와 현재 요구사항, 이번 분야의 상세 규칙을 먼저 읽어.
당분간 웹 형식으로만 개발하고 Flutter 앱·Flutter Web은 수정하지 마.
목적, 변경 범위, 검증 방법과 확인할 사항을 짧게 설명하고 진행해.
미정 사업 정책은 추측해서 구현하지 말고 질문해.
완료하면 변경 내용과 실제 검증 결과를 알려줘.
```

제품 결정의 근거는 Obsidian의 통합 근거·변경·보관 기록에 유지하고, 구현에 쓰는 현재 기준은 `requirements.md`에 갱신한다. 공통 규칙을 두 파일에 중복 관리하지 않는다.
