---
title: Keep Redirect Logic Centralized In Router
impact: HIGH
impactDescription: Avoids navigation inconsistency after auth changes
tags: go-router, redirect, auth
---

## Keep Redirect Logic Centralized In Router

Use app_router redirect as the source of truth for auth gating.

**Incorrect:**

```dart
// Login screen forces direct route after login
context.go('/some-page');
```

**Correct:**

```dart
// Login updates auth state; router redirect decides destination
await ref.read(authViewModelProvider.notifier).login(...);
```

Repository note: Avoid conflicting imperative navigation right after auth success.
