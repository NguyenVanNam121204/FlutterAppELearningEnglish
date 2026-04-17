# Flutter MVVM Agent Guide

Version 1.0.0

This compiled guide is optimized for AI-assisted implementation in this
repository.

## Abstract

Use these rules to keep code aligned with the project architecture:

- MVVM boundaries
- Riverpod provider-based dependency injection
- go_router with centralized redirect logic
- Repository-level Result pattern and AppError mapping
- Consistent async safety and UI state handling

## Table Of Contents

1. Architecture Boundaries (CRITICAL)
2. Data Flow and Errors (CRITICAL)
3. State and ViewModel (HIGH)
4. Routing and Navigation (HIGH)
5. UI Composition (HIGH)
6. Reliability and Async Safety (MEDIUM)

## 1. Architecture Boundaries (CRITICAL)

- Keep strict separation between views, viewmodels, repositories, and services.
- Register dependencies in one provider registry.

Rules:

- rules/architecture-layer-boundaries.md
- rules/architecture-providers-single-registry.md

## 2. Data Flow and Errors (CRITICAL)

- Repositories return Result<T>.
- Map API responses and exceptions in repository layer.

Rules:

- rules/data-repository-result-pattern.md

## 3. State and ViewModel (HIGH)

- Keep state immutable with copyWith updates.
- Place business logic in viewmodels.

Rules:

- rules/state-immutable-copywith.md
- rules/state-viewmodel-only-business-logic.md

## 4. Routing and Navigation (HIGH)

- Use RoutePaths constants and helper builders.
- Keep redirect behavior in app router.

Rules:

- rules/navigation-route-path-constants.md
- rules/navigation-router-redirect-source-of-truth.md

## 5. UI Composition (HIGH)

- Keep loading, error, and empty states explicit and consistent.

Rules:

- rules/ui-loading-error-empty-consistency.md

## 6. Reliability and Async Safety (MEDIUM)

- Check mounted after await before context usage.
- Keep side effects out of build methods.

Rules:

- rules/reliability-context-mounted-after-await.md
- rules/reliability-no-blocking-in-build.md

## References

- Flutter docs: https://docs.flutter.dev
- Riverpod docs: https://riverpod.dev
- go_router docs: https://pub.dev/packages/go_router
- Dio docs: https://pub.dev/packages/dio
