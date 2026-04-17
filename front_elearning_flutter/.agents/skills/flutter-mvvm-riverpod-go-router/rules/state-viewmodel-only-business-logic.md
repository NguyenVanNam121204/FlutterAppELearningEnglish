---
title: Keep Business Logic In ViewModel
impact: HIGH
impactDescription: Prevents fat widgets and duplicate logic
tags: mvvm, viewmodel, ui
---

## Keep Business Logic In ViewModel

Widgets should trigger actions and render state, not implement domain logic.

**Incorrect:**

```dart
onPressed: () async {
  final res = await ref.read(repoProvider).enrollCourse(id);
  if (res is Success) { /* mutate multiple providers */ }
}
```

**Correct:**

```dart
onPressed: () => ref.read(courseVmProvider.notifier).enroll(id);
```

Repository note: UI-only side effects (snackbar/navigation) can stay in screen,
but decision logic should come from state or vm result.
