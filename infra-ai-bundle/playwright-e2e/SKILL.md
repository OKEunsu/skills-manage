---
name: playwright-e2e
description: "Run Playwright-based end-to-end testing for local or remote web apps with a reconnaissance-first workflow, browser automation, and CI-ready patterns."
risk: unknown
source: merged
date_added: "2026-04-16"
---

# Playwright E2E

Unified Playwright workflow for local webapp testing, browser automation, visual checks, and CI-oriented end-to-end coverage.

## Use this skill when

- Testing a local or deployed web application end-to-end
- Writing Playwright scripts for user flows, screenshots, or regression checks
- Validating browser behavior across viewports or multiple browsers
- Integrating E2E checks into CI/CD

## Do not use this skill when

- The task is pure backend or API testing with no browser interaction
- The app is so static that direct HTML inspection is enough
- The user needs a full product QA strategy rather than concrete Playwright execution

## Instructions

1. Determine the target URL first.
2. For localhost testing, detect or start the dev server before writing automation.
3. Write temporary scripts outside the skill directory, preferably in `/tmp`.
4. Inspect rendered state before choosing selectors on dynamic apps.
5. Default to visible browser execution for debugging unless headless mode is explicitly better for the task or CI.

## Workflow

### 1. Resolve the App

- If the app is local, detect an existing dev server first.
- If no server is running, start one with a helper or project command before automation.
- For dynamic pages, always wait for the rendered state, not just initial HTML.

### 2. Reconnaissance First

- Navigate to the page.
- Wait for `networkidle` or a stable app-specific signal.
- Inspect the rendered DOM, page title, screenshots, console output, and available roles/selectors.
- Only then write the final interaction flow.

### 3. Script Rules

- Put one-off scripts in `/tmp/playwright-test-*.js` or equivalent.
- Parameterize the target URL at the top of the script.
- Close the browser cleanly and save artifacts to `/tmp` when useful.
- Use robust selectors:
  - `getByRole`
  - label/text selectors
  - stable ids or data attributes

### 4. E2E Coverage Areas

- happy path flows
- auth/login
- forms and validation
- navigation and route changes
- screenshots and visual stability
- responsive viewports
- cross-browser checks when warranted

### 5. CI Integration

- Keep test setup deterministic.
- Capture traces, screenshots, and videos on failure.
- Use headless execution in CI unless the environment requires otherwise.
- Prefer a small high-signal smoke suite over broad flaky coverage.

## Common Patterns

```javascript
const TARGET_URL = process.env.TARGET_URL || 'http://localhost:3000';
```

```javascript
await page.goto(TARGET_URL);
await page.waitForLoadState('networkidle');
```

```javascript
await page.screenshot({ path: '/tmp/page.png', fullPage: true });
```

## Quality Gates

- Stable selectors chosen from rendered state
- App readiness is verified before interactions
- Failures preserve enough artifacts to debug
- Critical user flows are covered before edge cases

## Limitations

- Use this skill only when the task clearly matches the scope described above.
- Do not treat the output as a substitute for environment-specific validation, testing, or expert review.
- Stop and ask for clarification if required inputs, permissions, safety boundaries, or success criteria are missing.
