---
title: Use RoutePaths Constants For Navigation
impact: HIGH
impactDescription: Prevents broken links and route drift
tags: navigation, go-router, constants
---

## Use RoutePaths Constants For Navigation

Always use route helpers/constants instead of inline path strings.

**Incorrect:**

```dart
context.go('/main-app/courses/course/$courseId');
```

**Correct:**

```dart
context.go(RoutePaths.courseInCourses(courseId));
```

Repository note: Keep route construction in lib/app/router/route_paths.dart.
