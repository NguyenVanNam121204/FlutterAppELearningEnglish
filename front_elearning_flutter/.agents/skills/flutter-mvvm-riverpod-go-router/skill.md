---
name: flutter-mvvm-riverpod-go-router
description: |
  Flutter app guidelines for MVVM + Riverpod + go_router + Dio + Result pattern.
  Use for feature implementation, refactors, bug fixing, and architecture reviews
  in this repository. Prioritizes layer boundaries, provider-based DI, immutable
  state, and consistent routing.
license: MIT
metadata:
  author: project-team
  version: "1.1.0"
---

# Flutter MVVM Skills

Practical rules for this codebase. These rules are optimized for AI agents and
human contributors to keep implementation consistent with existing architecture.

## When To Apply

Apply this skill when you are:

- Adding or changing Flutter screens and widgets
- Implementing new API calls
- Refactoring viewmodels, repositories, or providers
- Updating go_router navigation flow
- Fixing bugs in loading/error/empty handling

## Rule Categories By Priority

| Priority | Category | Impact | Prefix |
| --- | --- | --- | --- |
| 1 | Architecture Boundaries | CRITICAL | architecture- |
| 2 | Data Flow and Error Handling | CRITICAL | data- |
| 3 | State and ViewModel | HIGH | state- |
| 4 | Routing and Navigation | HIGH | navigation- |
| 5 | UI Composition | HIGH | ui- |
| 6 | Reliability and Async Safety | MEDIUM | reliability- |

## Quick Reference

### 1. Architecture (CRITICAL)

- architecture-layer-boundaries
- architecture-providers-single-registry

### 2. Data Flow (CRITICAL)

- data-repository-result-pattern

### 3. State (HIGH)

- state-immutable-copywith
- state-viewmodel-only-business-logic

### 4. Navigation (HIGH)

- navigation-route-path-constants
- navigation-router-redirect-source-of-truth

### 5. UI (HIGH)

- ui-loading-error-empty-consistency

### 6. Reliability (MEDIUM)

- reliability-context-mounted-after-await
- reliability-no-blocking-in-build

## How To Use

Read specific rule files for implementation details and examples:

- rules/architecture-layer-boundaries.md
- rules/data-repository-result-pattern.md
- rules/navigation-route-path-constants.md

Each rule file includes:

- Why the rule matters
- Incorrect example
- Correct example
- Notes for this repository

## Full Rule Set

See the rules directory for all rules.

## Repository Reality Notes

- Core DI providers (Dio, services, repositories, feature viewmodels) live in
  `lib/app/providers.dart`.
- Screen-scoped read-only providers are allowed as private providers inside a
  screen file when the state is local to that screen lifecycle.
