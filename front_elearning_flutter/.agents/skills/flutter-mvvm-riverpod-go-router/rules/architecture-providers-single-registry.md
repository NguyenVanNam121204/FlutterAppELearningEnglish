---
title: Register Dependencies In One Provider Registry
impact: CRITICAL
impactDescription: Ensures consistent DI and testability
tags: riverpod, providers, dependency-injection
---

## Register Dependencies In One Provider Registry

Create and wire services, repositories, and viewmodels in lib/app/providers.dart.
Do not instantiate concrete dependencies directly in UI code.

**Incorrect:**

```dart
final repo = HomeRepository(ApiService(Dio()));
```

**Correct:**

```dart
final repo = ref.read(homeRepositoryProvider);
final vm = ref.read(homeViewModelProvider.notifier);
```

Repository note: Keep provider naming with Provider suffix for consistency.
