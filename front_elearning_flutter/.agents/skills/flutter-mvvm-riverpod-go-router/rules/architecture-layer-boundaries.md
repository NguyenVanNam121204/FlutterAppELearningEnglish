---
title: Keep Strict Layer Boundaries
impact: CRITICAL
impactDescription: Prevents architecture erosion and duplicated logic
tags: architecture, mvvm, layering
---

## Keep Strict Layer Boundaries

Views render UI, viewmodels handle business logic, repositories map remote data,
and services execute technical operations.

**Incorrect:**

```dart
// In a screen widget
final response = await Dio().get('/api/user/courses');
setState(() { /* parse and mutate UI state here */ });
```

**Correct:**

```dart
// Screen
final state = ref.watch(homeViewModelProvider);

// ViewModel
final result = await _homeRepository.getSuggestedCourses();

// Repository
final response = await _apiService.get(ApiConstants.systemCourses);
return Success(_mapCourses(response.data));
```

Repository note: This project uses lib/app/providers.dart as the DI registry.
