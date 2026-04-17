---
title: Use Result Pattern In Repositories
impact: CRITICAL
impactDescription: Standardized success/failure handling across features
tags: repository, result, error-handling
---

## Use Result Pattern In Repositories

Repository methods should return Result<T> and map errors to AppError.

**Incorrect:**

```dart
Future<List<Course>> getCourses() async {
  final res = await _api.get('/courses');
  return (res.data as List).map(Course.fromJson).toList();
}
```

**Correct:**

```dart
Future<Result<List<Course>>> getCourses() async {
  try {
    final res = await _api.get('/courses');
    return Success(_asList(res.data).map(Course.fromJson).toList());
  } on DioException catch (e) {
    return Failure(_mapDioException(e));
  } catch (_) {
    return const Failure(AppError(message: 'Unable to load courses.'));
  }
}
```

Repository note: Keep parser helpers (_asMap, _asList, _toInt, _toDouble) near repository.
