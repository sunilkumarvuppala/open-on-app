# Architecture Improvements Documentation

## Overview

This document details all architectural improvements and new patterns introduced in 2025. These improvements enhance code quality, maintainability, and follow industry best practices.

**Last Updated**: January 2025  
**Status**: Production Ready

---

## Table of Contents

1. [Service Layer Pattern](#service-layer-pattern)
2. [Helper Functions Pattern](#helper-functions-pattern)
3. [Polling Mixin Pattern](#polling-mixin-pattern)
4. [Constants Centralization](#constants-centralization)
5. [Error Handling Improvements](#error-handling-improvements)
6. [Code Organization](#code-organization)

---

## Service Layer Pattern

### Overview

The Service Layer pattern separates business logic from API endpoints, making code more maintainable and testable.

### Implementation

**Location**: `backend/app/services/connection_service.py`

**Purpose**: Encapsulate connection-related business logic

**Key Methods**:
```python
class ConnectionService:
    async def check_existing_connection(user_id_1, user_id_2) -> bool
    async def check_pending_request(from_user_id, to_user_id) -> bool
    async def check_cooldown(from_user_id, to_user_id) -> bool
    async def check_rate_limit(user_id) -> tuple[bool, int]
    async def create_connection(user_id_1, user_id_2) -> None
```

### Benefits

1. **Reusability**: Business logic can be reused across endpoints
2. **Testability**: Easy to unit test business logic independently
3. **Maintainability**: Single source of truth for business rules
4. **Separation of Concerns**: API layer focuses on HTTP, service layer on business logic

### Usage Example

**Before** (Duplicate logic in endpoints):
```python
# In send_connection_request endpoint
connection_check = await session.execute(
    text("SELECT 1 FROM connections WHERE ..."),
    {"user1": user1, "user2": user2}
)
if connection_check.scalar():
    raise HTTPException(...)

# In another endpoint - same logic repeated
connection_check = await session.execute(
    text("SELECT 1 FROM connections WHERE ..."),
    {"user1": user1, "user2": user2}
)
```

**After** (Using service layer):
```python
# In send_connection_request endpoint
connection_service = ConnectionService(session)
if await connection_service.check_existing_connection(user1, user2):
    raise HTTPException(...)

# In another endpoint - reuse same method
if await connection_service.check_existing_connection(user1, user2):
    raise HTTPException(...)
```

### Files

- `backend/app/services/connection_service.py` - Connection business logic
- `backend/app/services/state_machine.py` - Capsule state machine
- `backend/app/services/unlock_service.py` - Unlock logic

---

## Helper Functions Pattern

### Overview

Helper functions provide reusable utilities for common operations, reducing code duplication.

### Implementation

**Location**: `backend/app/api/connection_helpers.py`

**Purpose**: Reusable functions for building API responses

**Key Functions**:
```python
async def build_connection_request_response(
    session: AsyncSession,
    request_row: tuple,
    profile_user_id: Optional[UUID] = None
) -> ConnectionRequestResponse
```

### Benefits

1. **Consistency**: Standardized response format
2. **Reduced Duplication**: Single implementation for response building
3. **Maintainability**: Changes in one place affect all usages

### Usage Example

**Before** (Duplicate response building):
```python
# In endpoint 1
profile_result = await session.execute(...)
profile_row = profile_result.fetchone()
return ConnectionRequestResponse(
    id=row[0],
    from_user_id=row[1],
    # ... many fields
    from_user_first_name=profile_row[0] if profile_row else None,
    # ... more fields
)

# In endpoint 2 - same code repeated
profile_result = await session.execute(...)
profile_row = profile_result.fetchone()
return ConnectionRequestResponse(
    # ... same code
)
```

**After** (Using helper):
```python
# In endpoint 1
return await build_connection_request_response(session, row, profile_user_id)

# In endpoint 2
return await build_connection_request_response(session, row, profile_user_id)
```

### Files

- `backend/app/api/connection_helpers.py` - Connection response helpers

---

## Polling Mixin Pattern

### Overview

The Polling Mixin pattern provides a reusable implementation for polling-based streams, ensuring consistent behavior and proper resource management.

### Implementation

**Location**: `frontend/lib/core/data/stream_polling_mixin.dart`

**Purpose**: Unified polling pattern for real-time data updates

**Key Methods**:
```dart
mixin StreamPollingMixin {
  Stream<T> createPollingStream<T>({
    required Future<T> Function() loadData,
    Duration pollInterval = const Duration(seconds: 5),
  })
}
```

### Benefits

1. **Consistency**: Same polling pattern across all repositories
2. **Resource Management**: Automatic timer cleanup
3. **Error Handling**: Unified error handling
4. **Reduced Duplication**: Single implementation for polling

### Usage Example

**Before** (Duplicate polling logic):
```dart
// In watchIncomingRequests
final controller = StreamController<List<ConnectionRequest>>.broadcast();
_loadIncomingRequests(controller);
Timer? timer;
timer = Timer.periodic(const Duration(seconds: 5), (t) {
  if (controller.isClosed) {
    t.cancel();
    return;
  }
  _loadIncomingRequests(controller);
});
controller.onCancel = () {
  timer?.cancel();
};
return controller.stream;

// In watchOutgoingRequests - same code repeated
final controller = StreamController<List<ConnectionRequest>>.broadcast();
_loadOutgoingRequests(controller);
// ... same timer logic
```

**After** (Using mixin):
```dart
class ApiConnectionRepository with StreamPollingMixin {
  @override
  Stream<List<ConnectionRequest>> watchIncomingRequests() {
    return createPollingStream<List<ConnectionRequest>>(
      loadData: _loadIncomingRequestsData,
      pollInterval: _pollInterval,
    );
  }
  
  @override
  Stream<List<ConnectionRequest>> watchOutgoingRequests() {
    return createPollingStream<List<ConnectionRequest>>(
      loadData: _loadOutgoingRequestsData,
      pollInterval: _pollInterval,
    );
  }
}
```

### Features

- Automatic timer cleanup on stream cancellation
- Proper error handling and propagation
- Configurable poll interval
- Efficient resource management

### Files

- `frontend/lib/core/data/stream_polling_mixin.dart` - Polling mixin
- `frontend/lib/core/data/api_repositories.dart` - Uses mixin

---

## Constants Centralization

### Overview

All magic numbers and hardcoded values are centralized in configuration files for easy maintenance and consistency.

### Backend Constants

**Location**: `backend/app/core/constants.py`

**Constants Defined**:
```python
# Connection constraints
MAX_CONNECTION_MESSAGE_LENGTH = 500
MAX_DECLINED_REASON_LENGTH = 500
MAX_DAILY_CONNECTION_REQUESTS = 5
CONNECTION_COOLDOWN_DAYS = 7

# Query limits
DEFAULT_QUERY_LIMIT = 50
MAX_QUERY_LIMIT = 100
MIN_QUERY_LIMIT = 1

# URL limits
MAX_URL_LENGTH = 500
```

### Frontend Constants

**Location**: `frontend/lib/core/constants/app_constants.dart`

**Constants Defined**:
- UI dimensions (heights, widths, padding)
- Animation durations
- Validation limits
- Particle counts
- Default values

### Benefits

1. **Maintainability**: Change in one place affects all usages
2. **Consistency**: Same values used throughout codebase
3. **Documentation**: Constants serve as documentation
4. **Type Safety**: Compile-time checking

### Migration

**Before**:
```python
message = sanitize_text(text, max_length=500)
if daily_count >= 5:
    raise HTTPException(...)
```

**After**:
```python
from app.core.constants import MAX_CONNECTION_MESSAGE_LENGTH, MAX_DAILY_CONNECTION_REQUESTS

message = sanitize_text(text, max_length=MAX_CONNECTION_MESSAGE_LENGTH)
if daily_count >= MAX_DAILY_CONNECTION_REQUESTS:
    raise HTTPException(...)
```

---

## Error Handling Improvements

### Overview

Comprehensive error handling with consistent patterns across all layers.

### Backend Error Handling

**Patterns**:
1. **Try-Except Blocks**: Proper exception handling
2. **Session Rollback**: Automatic rollback on errors
3. **Specific Error Messages**: User-friendly messages
4. **Detailed Logging**: Server-side detailed logs

**Example**:
```python
try:
    result = await session.execute(...)
    await session.commit()
    return response
except IntegrityError as e:
    await session.rollback()
    logger.error(f"Database integrity error: {e}")
    raise HTTPException(status_code=400, detail="Duplicate entry")
except DatabaseError as e:
    await session.rollback()
    logger.error(f"Database error: {e}")
    raise HTTPException(status_code=500, detail="Database error occurred")
```

### Frontend Error Handling

**Patterns**:
1. **AsyncValue**: Proper error handling in Riverpod
2. **Custom Exceptions**: Type-safe error handling
3. **User-Friendly Messages**: Clear error messages
4. **Error Logging**: Detailed logging for debugging

**Example**:
```dart
final connectionsAsync = ref.watch(connectionsProvider);
connectionsAsync.when(
  data: (connections) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);
```

---

## Code Organization

### Backend Organization

**Structure**:
```
backend/app/
├── api/              # API endpoints (HTTP layer)
│   ├── connections.py
│   └── connection_helpers.py  # ⭐ NEW
├── services/         # Business logic layer
│   └── connection_service.py  # ⭐ NEW
├── core/             # Core utilities
│   ├── constants.py  # ⭐ NEW
│   └── permissions.py
└── db/               # Data access layer
    └── repositories.py
```

**Principles**:
- API layer: HTTP concerns only
- Service layer: Business logic
- Data layer: Database access
- Core layer: Shared utilities

### Frontend Organization

**Structure**:
```
frontend/lib/
├── core/
│   ├── data/
│   │   ├── stream_polling_mixin.dart  # ⭐ NEW
│   │   └── api_repositories.dart
│   └── constants/
│       └── app_constants.dart
└── features/
    ├── people/       # ⭐ NEW
    └── connections/  # ⭐ NEW
```

**Principles**:
- Feature-based organization
- Shared code in core
- Clear separation of concerns
- Reusable patterns

---

## Design Patterns Summary

### Backend Patterns

1. **Repository Pattern**: Data access abstraction
2. **Service Layer Pattern**: Business logic separation ⭐ NEW
3. **Dependency Injection**: FastAPI Depends()
4. **Helper Functions**: Reusable utilities ⭐ NEW

### Frontend Patterns

1. **Repository Pattern**: Data access abstraction
2. **Provider Pattern**: Riverpod state management
3. **Mixin Pattern**: Reusable polling ⭐ NEW
4. **Widget Composition**: Reusable UI components

---

## Migration Impact

### Code Metrics

**Before Refactoring**:
- Duplicate validation logic: 5+ instances
- Duplicate polling logic: 3 instances
- Hardcoded values: 20+ instances
- Inconsistent error handling

**After Refactoring**:
- Duplicate validation logic: 0 (service layer)
- Duplicate polling logic: 0 (mixin)
- Hardcoded values: 0 (constants)
- Consistent error handling

### Maintainability

- **Easier to Test**: Service layer and mixins are easily testable
- **Easier to Modify**: Changes in one place affect all usages
- **Easier to Understand**: Clear patterns and organization
- **Easier to Extend**: New features follow established patterns

---

## Best Practices Established

### Backend

1. ✅ Service layer for complex business logic
2. ✅ Helper functions for common operations
3. ✅ Constants in dedicated file
4. ✅ Consistent error handling
5. ✅ Proper type hints
6. ✅ Comprehensive docstrings

### Frontend

1. ✅ Mixins for reusable patterns
2. ✅ Constants in AppConstants
3. ✅ Consistent error handling
4. ✅ Proper async patterns
5. ✅ Widget decomposition
6. ✅ Theme-aware components

---

## Related Documentation

- [Connections Feature](./frontend/features/CONNECTIONS.md)
- [Changes Documentation](./CHANGES_2025.md)
- [Backend Architecture](./backend/ARCHITECTURE.md)
- [Refactoring Guide](./REFACTORING.md)

---

**Last Updated**: January 2025  
**Maintained By**: Development Team  
**Status**: Production Ready ✅
