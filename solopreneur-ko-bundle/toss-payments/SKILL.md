---
name: toss-payments
description: "토스페이먼츠 V2로 카드, 간편결제, 가상계좌, 빌링 결제를 한국 서비스에 연동합니다."
---

# 토스페이먼츠 (Toss Payments)

토스페이먼츠 결제 연동 전문 스킬입니다. 한국 서비스에 카드결제, 간편결제(카카오페이, 네이버페이, 토스), 가상계좌, 자동결제(빌링)를 구현합니다.

## 사용법

```
/toss-payments [연동 목표]
```

예시:
- `/toss-payments Next.js에 카드결제 연동`
- `/toss-payments 구독 서비스 자동결제(빌링) 구현`
- `/toss-payments 가상계좌 발급 및 입금 확인`

---

## 토스페이먼츠 V2 API 기본 구조

### 결제 흐름 (단건 결제)

```
1. 클라이언트: 결제창 호출 (SDK)
   ↓
2. 토스페이먼츠: 결제 처리
   ↓
3. 클라이언트: successUrl로 리다이렉트 (paymentKey, orderId, amount 전달)
   ↓
4. 서버: 결제 승인 요청 (POST /v1/payments/confirm)
   ↓
5. 서버: DB 저장 및 주문 처리
```

### SDK 설치

```bash
npm install @tosspayments/payment-sdk
# 또는
npm install @tosspayments/tosspayments-sdk
```

### 클라이언트 결제창 호출

```typescript
import { loadTossPayments } from '@tosspayments/payment-sdk'

const tossPayments = await loadTossPayments(process.env.NEXT_PUBLIC_TOSS_CLIENT_KEY!)

await tossPayments.requestPayment('카드', {
  amount: 50000,
  orderId: `ORDER_${Date.now()}`,
  orderName: '상품명',
  customerName: '홍길동',
  customerEmail: 'user@example.com',
  successUrl: `${window.location.origin}/payment/success`,
  failUrl: `${window.location.origin}/payment/fail`,
})
```

### 서버 결제 승인 (Next.js API Route)

```typescript
// app/api/payment/confirm/route.ts
export async function POST(req: Request) {
  const { paymentKey, orderId, amount } = await req.json()

  const response = await fetch('https://api.tosspayments.com/v1/payments/confirm', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${process.env.TOSS_SECRET_KEY}:`).toString('base64')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ paymentKey, orderId, amount }),
  })

  const payment = await response.json()

  if (!response.ok) {
    return Response.json({ error: payment.message }, { status: 400 })
  }

  // DB에 결제 정보 저장
  await savePaymentToDb(payment)

  return Response.json(payment)
}
```

## 자동결제 (빌링 — 구독 서비스)

```typescript
// 1. 카드 등록 (빌링키 발급)
const billingKey = await fetch('https://api.tosspayments.com/v1/billing/authorizations/card', {
  method: 'POST',
  headers: { Authorization: `Basic ${encoded}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ customerKey, cardNumber, cardExpirationYear, cardExpirationMonth, customerBirthday }),
})

// 2. 빌링키로 자동결제
await fetch(`https://api.tosspayments.com/v1/billing/${billingKey}`, {
  method: 'POST',
  headers: { Authorization: `Basic ${encoded}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ customerKey, amount, orderId, orderName }),
})
```

## 환경변수 설정

```env
NEXT_PUBLIC_TOSS_CLIENT_KEY=test_ck_...   # 클라이언트 키 (공개)
TOSS_SECRET_KEY=test_sk_...               # 시크릿 키 (서버 전용, 절대 노출 금지)
```

## Webhook 설정 (입금 확인, 결제 상태 변경)

토스페이먼츠 대시보드 → 웹훅 등록 → 서버에서 수신:

```typescript
// app/api/webhook/toss/route.ts
export async function POST(req: Request) {
  const event = await req.json()

  switch (event.eventType) {
    case 'PAYMENT_STATUS_CHANGED':
      await handlePaymentStatusChange(event.data)
      break
    case 'VIRTUAL_ACCOUNT_DEPOSIT_CALLBACK':
      await handleVirtualAccountDeposit(event.data)
      break
  }

  return Response.json({ ok: true })
}
```

## 테스트

- 테스트 키: `test_ck_*`, `test_sk_*`
- 테스트 카드번호: `4330123412341234` (항상 성공)
- 실패 시뮬레이션: 카드번호 `4330123412341235`

## 주의사항

- `amount` 위변조 방지: 서버에서 DB의 주문금액과 반드시 대조 후 승인
- 시크릿 키는 서버에서만 사용, 클라이언트 코드에 절대 노출 금지
- 결제 취소는 `/v1/payments/{paymentKey}/cancel` 사용
- 사업자 등록 후 실제 키 발급 (토스페이먼츠 대시보드)
