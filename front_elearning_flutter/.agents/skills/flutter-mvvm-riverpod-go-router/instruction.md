# Instruction For Agents

Use this instruction when working inside this Flutter repository.

## Goal

Deliver code that matches the existing architecture:

- MVVM style separation
- Riverpod for state and dependency injection
- go_router for navigation
- Dio-based API access through repositories
- Result wrapper for success/failure handling

## Mandatory Workflow

1. Identify affected layer(s): view, viewmodel, repository, service, router.
2. Keep responsibilities isolated by layer.
3. Register new dependencies in lib/app/providers.dart.
4. Use route constants from lib/app/router/route_paths.dart.
5. Return Result<T> from repositories, never throw raw exceptions to UI.
6. Update UI state only through immutable state objects and copyWith.
7. Validate changes with analyzer/tests when possible.

## Hard Rules

- Do not call API directly from screens or widgets.
- Do not instantiate repositories/services directly in UI.
- Do not hardcode route strings when RoutePaths helper exists.
- Do not bypass Result pattern in repository layer.
- Do not mutate state collections in-place if they are part of state object.

## UX Rules

- Keep loading, empty, and error states explicit.
- Keep micro-interactions subtle and meaningful.
- Keep labels and messages consistent across screens.

## Code Review Checklist

- Layer boundary respected
- Provider wiring correct
- Routing and redirect behavior preserved
- Failure handling and user feedback present
- Async context safety (`mounted` checks) handled

## Output Expectations

When implementing tasks, include:

- Files changed
- Why each change is in that layer
- Any follow-up validation steps
