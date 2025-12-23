# Developer Guide - Complete Reference

## Overview

This guide provides comprehensive information for developers working on the OpenOn codebase. It covers architecture, patterns, best practices, and common tasks.

**Last Updated**: January 2025  
**Status**: Production Ready

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Architecture Overview](#architecture-overview)
3. [Code Patterns](#code-patterns)
4. [Development Workflow](#development-workflow)
5. [Testing Guidelines](#testing-guidelines)
6. [Common Tasks](#common-tasks)
7. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

- **Backend**: Python 3.11+, FastAPI, PostgreSQL
- **Frontend**: Flutter 3.0+, Dart 3.0+
- **Database**: Supabase (PostgreSQL)
- **Tools**: Git, IDE (VS Code recommended)

### Initial Setup

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd openon
   ```

2. **Backend Setup**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Frontend Setup**
   ```bash
   cd frontend
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Database Setup**
   ```bash
   cd supabase
   supabase start
   supabase db reset
   ```

### Documentation Reading Order

1. [ONBOARDING.md](./ONBOARDING.md) - Complete onboarding
2. [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
3. [CHANGES_2025.md](./CHANGES_2025.md) - Recent changes
4. [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Quick reference
5. Component-specific documentation

---

## Architecture Overview

### System Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
└────────┬────────┘
         │ HTTP/REST
         ▼
┌─────────────────┐
│  FastAPI        │
│  (Backend)      │
└────────┬────────┘
         │ SQL
         ▼
┌─────────────────┐
│  PostgreSQL     │
│  (Supabase)     │
└─────────────────┘
```

### Layer Architecture

**Backend**:
- **API Layer**: HTTP endpoints (`app/api/`)
- **Service Layer**: Business logic (`app/services/`) ⭐ NEW
- **Data Layer**: Database access (`app/db/`)
- **Core Layer**: Utilities (`app/core/`)

**Frontend**:
- **Presentation Layer**: Screens and widgets (`features/`)
- **Business Logic**: Providers and repositories (`core/`)
- **Data Layer**: Models and API clients (`core/data/`)
- **Core Layer**: Constants and utilities (`core/`)

---

## Code Patterns

### Backend Patterns

#### 1. Service Layer Pattern

**When to Use**: Complex business logic that needs to be reused

**Example**:
```python
# backend/app/services/connection_service.py
class ConnectionService:
    def __init__(self, session: AsyncSession):
        self.session = session
    
    async def check_existing_connection(self, user1, user2) -> bool:
        # Business logic here
        pass
```

**Usage in Endpoints**:
```python
@router.post("/connections/requests")
async def send_request(
    data: RequestSchema,
    session: DatabaseSession
):
    connection_service = ConnectionService(session)
    if await connection_service.check_existing_connection(user1, user2):
        raise HTTPException(...)
```

#### 2. Helper Functions Pattern

**When to Use**: Reusable response building or common operations

**Example**:
```python
# backend/app/api/connection_helpers.py
async def build_connection_request_response(
    session: AsyncSession,
    request_row: tuple,
    profile_user_id: UUID
) -> ConnectionRequestResponse:
    # Build standardized response
    pass
```

#### 3. Constants Pattern

**Always Use**: Never hardcode values

**Example**:
```python
# ❌ Bad
if count >= 5:
    raise HTTPException(...)

# ✅ Good
from app.core.constants import MAX_DAILY_CONNECTION_REQUESTS
if count >= MAX_DAILY_CONNECTION_REQUESTS:
    raise HTTPException(...)
```

### Frontend Patterns

#### 1. Polling Mixin Pattern

**When to Use**: Real-time data that needs periodic updates

**Example**:
```dart
class MyRepository with StreamPollingMixin {
  Stream<List<Item>> watchItems() {
    return createPollingStream<List<Item>>(
      loadData: _loadItemsData,
      pollInterval: const Duration(seconds: 5),
    );
  }
  
  Future<List<Item>> _loadItemsData() async {
    // Load data logic
    return items;
  }
}
```

#### 2. Provider Pattern

**Always Use**: For state management

**Example**:
```dart
final itemsProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.watchItems();
});

// In widget
final itemsAsync = ref.watch(itemsProvider);
itemsAsync.when(
  data: (items) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => ErrorWidget(e),
);
```

#### 3. Constants Pattern

**Always Use**: Never hardcode values

**Example**:
```dart
// ❌ Bad
Container(height: 50.0, padding: EdgeInsets.all(16.0))

// ✅ Good
Container(
  height: AppConstants.userAvatarSize,
  padding: EdgeInsets.all(AppTheme.spacingMd),
)
```

---

## Development Workflow

### Adding a New Feature

1. **Plan**: Review architecture and patterns
2. **Database**: Create migrations if needed
3. **Backend**: Create service, API endpoints, schemas
4. **Frontend**: Create models, repository, providers, UI
5. **Test**: Test all flows
6. **Document**: Update documentation

### Code Review Checklist

- [ ] Uses constants (no hardcoded values)
- [ ] Follows established patterns
- [ ] Proper error handling
- [ ] Input validation
- [ ] Security checks
- [ ] Documentation updated

### Git Workflow

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Update documentation
5. Create pull request
6. Code review
7. Merge to main

---

## Testing Guidelines

### Backend Testing

**Unit Tests**:
- Test service layer methods
- Test helper functions
- Test validation logic

**Integration Tests**:
- Test API endpoints
- Test database operations
- Test authentication

### Frontend Testing

**Widget Tests**:
- Test UI components
- Test user interactions
- Test error states

**Integration Tests**:
- Test user flows
- Test API integration
- Test state management

---

## Common Tasks

### Adding a New API Endpoint

1. **Create Schema** (`app/models/schemas.py`):
   ```python
   class MyRequest(BaseModel):
       field: str
   ```

2. **Create Endpoint** (`app/api/my_resource.py`):
   ```python
   @router.post("/my-resource")
   async def create_resource(
       data: MyRequest,
       current_user: CurrentUser,
       session: DatabaseSession
   ):
       # Implementation
   ```

3. **Register Router** (`app/main.py`):
   ```python
   app.include_router(my_resource_router)
   ```

### Adding a New Frontend Feature

1. **Create Models** (`core/models/`):
   ```dart
   @freezed
   class MyModel with _$MyModel {
     const factory MyModel({...}) = _MyModel;
   }
   ```

2. **Create Repository** (`core/data/`):
   ```dart
   abstract class MyRepository {
     Future<List<MyModel>> getItems();
   }
   ```

3. **Create Provider** (`core/providers/`):
   ```dart
   final myItemsProvider = FutureProvider<List<MyModel>>((ref) {
     final repo = ref.watch(myRepositoryProvider);
     return repo.getItems();
   });
   ```

4. **Create UI** (`features/my_feature/`):
   ```dart
   class MyFeatureScreen extends ConsumerWidget {
     // UI implementation
   }
   ```

---

## Troubleshooting

### Common Issues

**Backend**:
- **Import Errors**: Check Python path and virtual environment
- **Database Errors**: Check connection string and migrations
- **Auth Errors**: Check JWT secret and token validation

**Frontend**:
- **Build Errors**: Run `flutter pub get` and `build_runner`
- **State Errors**: Check provider dependencies
- **UI Errors**: Check theme and color scheme

### Debugging Tips

1. **Check Logs**: Review application logs
2. **Verify Data**: Check database directly
3. **Test Endpoints**: Use curl or Postman
4. **Check State**: Use Riverpod DevTools
5. **Review Documentation**: Check relevant docs

---

## Best Practices

### Backend

1. ✅ Always use constants
2. ✅ Use service layer for business logic
3. ✅ Validate all inputs
4. ✅ Handle errors properly
5. ✅ Use type hints
6. ✅ Write docstrings

### Frontend

1. ✅ Always use AppConstants
2. ✅ Use providers for state
3. ✅ Handle loading/error states
4. ✅ Use theme-aware colors
5. ✅ Decompose widgets
6. ✅ Handle async properly

---

## Related Documentation

- [Architecture](./ARCHITECTURE.md)
- [Changes](./CHANGES_2025.md)
- [Architecture Improvements](./ARCHITECTURE_IMPROVEMENTS.md)
- [Quick Reference](./QUICK_REFERENCE.md)
- [Refactoring](./REFACTORING.md)

---

**Last Updated**: January 2025  
**Maintained By**: Development Team  
**Status**: Production Ready ✅
