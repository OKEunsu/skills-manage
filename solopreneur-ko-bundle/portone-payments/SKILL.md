---
name: portone-payments
description: "포트원 V2로 토스페이먼츠, KG이니시스, NHN KCP, 카카오페이, 네이버페이 등 PG 결제를 통합 연동합니다."
---

# 포트원 (PortOne / iamport) 결제 연동

포트원 V2 결제 연동 전문 스킬입니다. 토스페이먼츠, KG이니시스, NHN KCP, 카카오페이, 네이버페이 등 한국 주요 PG사를 단일 API로 연동합니다.

## 사용법

```
/portone-payments [연동 목표]
```

예시:
- `/portone-payments Next.js + 토스페이먼츠 PG 연동`
- `/portone-payments 카카오페이 단독 결제 구현`
- `/portone-payments 구독 정기결제 빌링 구현`

---

## 포트원 V2 기본 구조

포트원은 여러 PG사를 하나의 API로 추상화합니다.

```
클라이언트 SDK → 포트원 → PG사 (토스/카카오/네이버/이니시스 등)
                    ↓
              서버 결제검증 API
```

### SDK 설치

```bash
npm install @portone/browser-sdk   # 클라이언트
npm install @portone/server-sdk    # 서버 (Node.js)
```

### 환경변수

```env
NEXT_PUBLIC_PORTONE_STORE_ID=store-...       # 상점 ID (공개)
PORTONE_API_SECRET=...                        # API 시크릿 (서버 전용)
NEXT_PUBLIC_PORTONE_CHANNEL_KEY=channel-key-...  # PG사별 채널 키
```

### 클라이언트 결제 요청

```typescript
import * as PortOne from '@portone/browser-sdk/v2'

const response = await PortOne.requestPayment({
  storeId: process.env.NEXT_PUBLIC_PORTONE_STORE_ID!,
  channelKey: process.env.NEXT_PUBLIC_PORTONE_CHANNEL_KEY!,
  paymentId: `payment-${Date.now()}`,
  orderName: '상품명',
  totalAmount: 50000,
  currency: 'KRW',
  payMethod: 'CARD',   // CARD | EASY_PAY | VIRTUAL_ACCOUNT | TRANSFER
  customer: {
    customerId: 'user-123',
    fullName: '홍길동',
    email: 'user@example.com',
  },
})

if (response?.code) {
  // 결제 실패
  console.error(response.message)
  return
}

// 서버 검증 요청
await fetch('/api/payment/verify', {
  method: 'POST',
  body: JSON.stringify({ paymentId: response.paymentId }),
})
```

### 서버 결제 검증 (Next.js)

```typescript
// app/api/payment/verify/route.ts
import PortOne from '@portone/server-sdk'

const portone = PortOne.PortOneClient(process.env.PORTONE_API_SECRET!)

export async function POST(req: Request) {
  const { paymentId } = await req.json()

  const payment = await portone.payment.getPayment({ paymentId })

  // 주문 금액 대조 (위변조 방지)
  const order = await getOrderFromDb(paymentId)
  if (payment.amount.total !== order.amount) {
    return Response.json({ error: '금액 불일치' }, { status: 400 })
  }

  if (payment.status === 'PAID') {
    await confirmOrder(paymentId)
    return Response.json({ success: true })
  }

  return Response.json({ error: '결제 미완료' }, { status: 400 })
}
```

## 간편결제 설정

```typescript
// 카카오페이
payMethod: 'EASY_PAY',
easyPay: { easyPayProvider: 'KAKAOPAY' }

// 네이버페이
payMethod: 'EASY_PAY',
easyPay: { easyPayProvider: 'NAVERPAY' }

// 토스페이
payMethod: 'EASY_PAY',
easyPay: { easyPayProvider: 'TOSSPAY' }
```

## 정기결제 (빌링)

```typescript
// 1. 빌링키 발급
const billing = await PortOne.requestBillingKeyIssue({
  storeId: process.env.NEXT_PUBLIC_PORTONE_STORE_ID!,
  channelKey: process.env.NEXT_PUBLIC_PORTONE_CHANNEL_KEY!,
  billingKeyMethod: 'CARD',
  customer: { customerId: 'user-123' },
})

// 2. 서버에서 빌링키로 자동결제
await portone.payment.payWithBillingKey({
  paymentId: `sub-${Date.now()}`,
  billingKey: billing.billingKey,
  orderName: '월간 구독',
  amount: { total: 9900 },
  currency: 'KRW',
})
```

## Webhook 처리

포트원 콘솔에서 Webhook URL 등록 후:

```typescript
// app/api/webhook/portone/route.ts
export async function POST(req: Request) {
  const { type, data } = await req.json()

  if (type === 'Transaction.Paid') {
    await confirmOrder(data.paymentId)
  } else if (type === 'Transaction.VirtualAccountIssued') {
    await notifyVirtualAccount(data)
  }

  return Response.json({ ok: true })
}
```

## 포트원 vs 토스페이먼츠 선택 기준

| 상황 | 추천 |
|------|------|
| 여러 PG사 지원 필요 | 포트원 |
| 토스 단독, 심플한 연동 | 토스페이먼츠 직접 |
| 카카오/네이버페이 포함 | 포트원 |
| 해외 결제 포함 | 포트원 (일부 PG) |

## 주의사항

- V1(`iamport`)와 V2(`portone`) API가 다름 — 신규 프로젝트는 V2 사용
- 결제 금액은 반드시 서버에서 DB 대조 후 검증
- 테스트 환경: 포트원 콘솔에서 테스트 채널 키 별도 발급
- 실서비스: 사업자 등록 필수, PG사별 심사 필요
