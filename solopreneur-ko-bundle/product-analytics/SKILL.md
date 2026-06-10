---
name: product-analytics
description: "PostHog, GA4, Mixpanel로 제품 이벤트 추적, 퍼널, 리텐션, A/B 테스트 분석을 구현합니다."
---

# Product Analytics

제품 분석 전문 스킬입니다. PostHog, Google Analytics 4(GA4), Mixpanel을 활용해 유저 행동 추적, 퍼널 분석, 리텐션 측정, A/B 테스트를 구현합니다.

## 사용법

```
/product-analytics [목표]
```

예시:
- `/product-analytics Next.js에 PostHog 설치 및 주요 이벤트 추적`
- `/product-analytics 결제 전환 퍼널 분석 설정`
- `/product-analytics GA4 eCommerce 이벤트 구현`

---

## 도구 선택 가이드

| 도구 | 추천 상황 | 특징 |
|------|---------|------|
| **PostHog** | SaaS, B2B, 셀프호스팅 원할 때 | 오픈소스, 세션 리플레이, 피처 플래그 포함 |
| **GA4** | 마케팅 채널 분석, SEO 연동 | 무료, Google Ads 연동 |
| **Mixpanel** | 유저 행동 심층 분석 | 강력한 코호트 분석 |

1인 기업 기본 추천: **PostHog** (무료 tier 100만 이벤트/월)

---

## PostHog 설치 (Next.js)

```bash
npm install posthog-js
```

```typescript
// lib/posthog.ts
import posthog from 'posthog-js'

export function initPostHog() {
  if (typeof window !== 'undefined') {
    posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
      api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://us.i.posthog.com',
      capture_pageview: false,   // App Router에서 수동 처리
      capture_pageleave: true,
    })
  }
}
```

```typescript
// app/providers.tsx
'use client'
import { usePathname, useSearchParams } from 'next/navigation'
import { useEffect } from 'react'
import posthog from 'posthog-js'

export function PostHogPageView() {
  const pathname = usePathname()
  const searchParams = useSearchParams()

  useEffect(() => {
    posthog.capture('$pageview', { $current_url: window.location.href })
  }, [pathname, searchParams])

  return null
}
```

### 유저 식별

```typescript
// 로그인 후
posthog.identify(userId, {
  email: user.email,
  name: user.name,
  plan: user.plan,
  created_at: user.createdAt,
})

// 로그아웃 후
posthog.reset()
```

### 핵심 이벤트 추적

```typescript
// 결제 완료
posthog.capture('payment_completed', {
  amount: 50000,
  currency: 'KRW',
  plan: 'pro',
  payment_method: 'card',
})

// 기능 사용
posthog.capture('feature_used', {
  feature_name: 'export_pdf',
  user_plan: 'free',
})

// 온보딩 단계
posthog.capture('onboarding_step_completed', {
  step: 3,
  step_name: 'profile_setup',
})
```

---

## GA4 설치 (Next.js)

```bash
npm install @next/third-parties
```

```typescript
// app/layout.tsx
import { GoogleAnalytics } from '@next/third-parties/google'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>{children}</body>
      <GoogleAnalytics gaId={process.env.NEXT_PUBLIC_GA4_ID!} />
    </html>
  )
}
```

### GA4 eCommerce 이벤트

```typescript
import { sendGAEvent } from '@next/third-parties/google'

// 구매 완료
sendGAEvent('event', 'purchase', {
  transaction_id: orderId,
  value: 50000,
  currency: 'KRW',
  items: [{ item_id: 'plan_pro', item_name: 'Pro Plan', price: 50000 }],
})
```

---

## 측정해야 할 핵심 지표 (1인 기업)

### 활성화 (Activation)
- 가입 → 첫 핵심 기능 사용까지 시간
- 온보딩 완료율

### 리텐션 (Retention)
- D1, D7, D30 재방문율
- 주간 활성 유저 (WAU)

### 수익 (Revenue)
- 무료 → 유료 전환율
- MRR, Churn Rate
- LTV (고객 생애 가치)

### 추천 퍼널

```
방문 → 가입 → 핵심기능사용 → 결제 → 재결제
  ↓       ↓         ↓           ↓        ↓
 100%    X%        X%          X%       X%
```

---

## 환경변수

```env
NEXT_PUBLIC_POSTHOG_KEY=phc_...
NEXT_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
NEXT_PUBLIC_GA4_ID=G-XXXXXXXXXX
```

## 주의사항

- 개인정보보호법 준수: 개인정보 처리방침에 분석 도구 명시 필수
- 쿠키 동의 배너: EU 사용자 대상 서비스는 GDPR 필요, 한국은 현재 선택적
- 서버사이드 이벤트: 결제 완료 같은 중요 이벤트는 서버에서 PostHog Node SDK로 추가 전송 권장
