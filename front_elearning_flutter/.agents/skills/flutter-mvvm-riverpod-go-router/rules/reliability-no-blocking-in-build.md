---
title: Avoid Blocking Work In build
impact: MEDIUM
impactDescription: Prevents jank and repeated side effects
tags: performance, build, reliability
---

## Avoid Blocking Work In build

Do not perform async side effects or expensive computation directly in build.

**Incorrect:**

```dart
@override
Widget build(BuildContext context) {
  ref.read(vmProvider.notifier).load();
  return ...;
}
```

**Correct:**

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() => ref.read(vmProvider.notifier).load());
}
```

Repository note: If one-time post-render behavior is needed, guard callbacks to
avoid repeated execution on every rebuild.
