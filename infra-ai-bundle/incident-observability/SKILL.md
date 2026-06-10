---
name: incident-observability
description: "Handle production incidents with observability-first investigation, safe stabilization, distributed tracing, and post-incident follow-through."
risk: critical
source: merged
date_added: "2026-04-16"
---

# Incident Observability

Unified incident-response playbook for active production problems, trace-driven investigation, and safe recovery.

## Use this skill when

- Diagnosing a production incident or major service degradation
- Coordinating triage for multi-service failures
- Using metrics, logs, traces, or APM data to isolate a fault
- Standardizing incident response and observability practices

## Do not use this skill when

- The issue is low-risk local debugging with no operational impact
- You cannot access any runtime evidence such as logs, traces, or metrics
- The task is only retrospective documentation with no operational investigation

## Instructions

1. Establish severity, impact, blast radius, and immediate rollback options.
2. Stabilize the system before chasing deep root cause.
3. Use observability to correlate traces, metrics, logs, deploys, and dependency state.
4. Implement the smallest safe fix or rollback.
5. Validate recovery and capture follow-up actions for prevention.

## Incident Workflow

### 1. First Minutes

- assess user and business impact
- identify affected systems and recent changes
- assign an incident lead
- open communication channels
- decide whether rollback, scale-up, traffic shedding, or feature disablement is the fastest safe move

### 2. Observability-First Investigation

- metrics: error rate, latency, saturation, queue depth, burn rate
- logs: correlated errors, structured fields, request ids
- traces: failing spans, latency hotspots, upstream/downstream impact
- changes: deploys, config edits, feature flags, dependency incidents

### 3. Safe Stabilization

- prioritize restoration over perfect understanding
- use production-safe changes:
  - rollback
  - feature flag disable
  - rate limiting
  - circuit breaker changes
  - temporary scaling
- avoid verbose logging or tracing explosions without safeguards

### 4. Resolution Validation

- confirm user-facing recovery
- confirm key SLIs return to normal range
- verify dependent systems are healthy
- keep elevated monitoring during the recovery window

### 5. Follow-Through

- capture timeline, impact, and decisions
- identify root cause and contributing factors
- define preventive actions:
  - better alerts
  - trace coverage
  - runbooks
  - safer deploys
  - architectural fixes

## Safety

- Redact secrets and PII from logs and traces.
- Avoid noisy production instrumentation without limits or sampling.
- Prefer reversible mitigations during active response.

## Output Expectations

- severity and impact summary
- likely fault domain
- immediate mitigation options
- evidence from logs/metrics/traces
- recovery status
- follow-up actions

## Limitations

- Use this skill only when the task clearly matches the scope described above.
- Do not treat the output as a substitute for environment-specific validation, testing, or expert review.
- Stop and ask for clarification if required inputs, permissions, safety boundaries, or success criteria are missing.
