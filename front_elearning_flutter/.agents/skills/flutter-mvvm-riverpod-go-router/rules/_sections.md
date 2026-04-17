# Sections

This file defines section ordering and impact.

## 1. Architecture Boundaries (architecture)

Impact: CRITICAL
Description: Keeps clean layer responsibilities and maintainable code.

## 2. Data Flow and Errors (data)

Impact: CRITICAL
Description: Enforces stable API handling via Result wrapper.

## 3. State and ViewModel (state)

Impact: HIGH
Description: Preserves predictable state updates and testability.

## 4. Routing and Navigation (navigation)

Impact: HIGH
Description: Prevents route drift and redirect regressions.

## 5. UI Composition (ui)

Impact: HIGH
Description: Improves reuse, readability, and consistent UX states.

## 6. Reliability and Async Safety (reliability)

Impact: MEDIUM
Description: Avoids runtime crashes and lifecycle-related bugs.
