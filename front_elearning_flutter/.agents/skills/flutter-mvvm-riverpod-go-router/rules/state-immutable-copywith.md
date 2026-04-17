---
title: Keep State Immutable With copyWith
impact: HIGH
impactDescription: Predictable updates and easier debugging
tags: state, immutable, viewmodel
---

## Keep State Immutable With copyWith

State objects should be immutable and replaced with copyWith updates.

**Incorrect:**

```dart
state.items.add(item);
state.isLoading = false;
```

**Correct:**

```dart
final updated = [...state.items, item];
state = state.copyWith(items: updated, isLoading: false);
```

Repository note: If state includes sets/maps, create new instances before update.
