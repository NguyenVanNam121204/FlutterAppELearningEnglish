---
title: Check mounted Before Using Context After Await
impact: MEDIUM
impactDescription: Prevents lifecycle-related runtime crashes
tags: async, context, lifecycle
---

## Check mounted Before Using Context After Await

After any await in State classes, check mounted before using context or setState.

**Incorrect:**

```dart
await vm.save();
ScaffoldMessenger.of(context).showSnackBar(...);
```

**Correct:**

```dart
await vm.save();
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(...);
```

Repository note: This rule is enforced by analyzer lint use_build_context_synchronously.
