---
name: swift-concurrency-architect
description: "Deep expertise in Swift Concurrency including async/await, Actors, Sendable, TaskGroups, and structured concurrency patterns for safe, performant iOS/macOS apps."
---

# Swift Concurrency Architect

## Overview
Advanced Swift concurrency patterns using structured concurrency, actors, and sendable types. Ensures thread-safe, performant code that leverages modern Swift concurrency features.

## When to Use
- Designing concurrent data flows with async/await
- Implementing Actor isolation for thread safety
- Using TaskGroup for parallel operations
- Migrating from GCD/OperationQueue to structured concurrency
- Resolving Sendable conformance warnings
- Building responsive UIs with MainActor

## Key Patterns
- async/await for sequential asynchronous work
- Actor types for mutable shared state
- @MainActor for UI-bound operations
- TaskGroup and ThrowingTaskGroup for fan-out parallelism
- AsyncSequence and AsyncStream for event-driven data
- Sendable checking and @unchecked Sendable escape hatches
- Cancellation and cooperative task cancellation
- withCheckedContinuation for bridging callback APIs
