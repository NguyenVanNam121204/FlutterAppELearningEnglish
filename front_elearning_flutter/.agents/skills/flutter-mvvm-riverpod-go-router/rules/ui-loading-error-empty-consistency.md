---
title: Standardize Loading Error Empty States
impact: HIGH
impactDescription: Improves UX consistency and maintainability
tags: ui, ux, states
---

## Standardize Loading Error Empty States

Each async screen should handle loading, error, and empty states explicitly.

**Incorrect:**

```dart
if (items.isEmpty) return const SizedBox.shrink();
```

**Correct:**

```dart
return asyncItems.when(
  loading: () => const LoadingStateView(),
  error: (e, _) => ErrorStateView(message: '$e'),
  data: (items) {
    if (items.isEmpty) {
      return const EmptyStateView(message: 'No data');
    }
    return ListView(...);
  },
);
```

Repository note: Reuse existing common state widgets under views/widgets/common.
