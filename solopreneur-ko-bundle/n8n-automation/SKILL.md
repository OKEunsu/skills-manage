---
name: n8n-automation
description: "n8n으로 이메일, 데이터 수집, 알림, CRM 연동 같은 반복 업무 워크플로를 자동화합니다."
---

# n8n Automation

n8n 워크플로우 자동화 전문 스킬입니다. 반복 업무(이메일, 데이터 수집, 알림, CRM 연동)를 코드 없이 또는 최소 코드로 자동화합니다.

## 사용법

```
/n8n-automation [목표 설명]
```

예시:
- `/n8n-automation 새 고객이 가입하면 Slack 알림 + Google Sheets 기록`
- `/n8n-automation Gmail 수신 → 카테고리 분류 → Notion 데이터베이스 저장`

---

## n8n 핵심 개념

- **Node**: 워크플로우의 단위 작업 (HTTP 요청, DB 쿼리, 조건 분기 등)
- **Workflow**: Node를 연결한 자동화 흐름
- **Trigger**: 워크플로우를 시작하는 이벤트 (Webhook, Cron, 이메일 수신 등)
- **Credential**: API 키, OAuth 인증 정보 관리
- **Expression**: `{{ $json.field }}` 형태로 이전 노드 데이터 참조

## 주요 Trigger 패턴

| 트리거 | 용도 |
|--------|------|
| Webhook | 외부 서비스에서 POST 요청 받기 |
| Schedule | Cron 기반 주기 실행 |
| Gmail Trigger | 이메일 수신 감지 |
| Postgres Trigger | DB 변경 감지 |

## 1인 기업 자동화 레시피

### 신규 고객 온보딩
```
Webhook (결제 완료) → 고객 DB 저장 → 환영 이메일 발송 → Slack 알림
```

### 콘텐츠 수집 파이프라인
```
RSS Feed / HTTP → 키워드 필터 → Notion DB 저장 → 요약 생성
```

### 리드 관리
```
폼 제출 → CRM 등록 → 담당자 Slack 알림 → 7일 후 팔로업 이메일 예약
```

### 재무 모니터링
```
Cron (매일 9시) → API 잔액 조회 → 임계값 이하 시 SMS/Slack 경고
```

## 구현 가이드

### 1단계: 요구사항 파악
- 트리거 이벤트가 무엇인지 확인
- 연동할 서비스 목록 정리
- 에러 처리 시나리오 정의

### 2단계: 워크플로우 설계
```json
{
  "nodes": [
    { "type": "trigger", "name": "시작 조건" },
    { "type": "transform", "name": "데이터 가공" },
    { "type": "action", "name": "목적지 전송" }
  ]
}
```

### 3단계: 자주 쓰는 Node 조합
- **HTTP Request** + **Set** + **IF** → 조건부 API 호출
- **Code** Node (JavaScript) → 복잡한 데이터 변환
- **Error Trigger** → 실패 시 알림 전송

## Self-hosted 설치 (Docker)

```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

## 주의사항

- Webhook URL은 외부에서 접근 가능한 주소여야 함 (ngrok, Cloudflare Tunnel 등)
- Credential은 n8n 내부 암호화 저장소 사용 — 코드에 하드코딩 금지
- 워크플로우 실행 로그는 n8n UI의 Executions 탭에서 확인
- 프로덕션 환경에서는 `EXECUTIONS_DATA_PRUNE=true` 설정 권장
