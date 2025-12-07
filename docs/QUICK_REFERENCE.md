# Quick Reference Guide

> **📖 For complete onboarding**: See [ONBOARDING.md](./ONBOARDING.md)  
> **🚀 For quick setup**: See [QUICK_START.md](./QUICK_START.md)  
> **📋 For detailed refactoring information**: See [REFACTORING_2025.md](./REFACTORING_2025.md)

A quick reference for common tasks and patterns in the OpenOn codebase.

## 📋 Table of Contents

1. [Backend Quick Reference](#backend-quick-reference)
2. [Frontend Quick Reference](#frontend-quick-reference)
3. [Common Patterns](#common-patterns)
4. [File Locations](#file-locations)

---

## Backend Quick Reference

### Configuration Constants

**Location**: `backend/app/core/config.py`

```python
from app.core.config import settings

# Pagination
settings.default_page_size      # 20
settings.max_page_size          # 100
settings.min_page_size          # 1

# Search
settings.default_search_limit   # 10
settings.max_search_limit       # 50
settings.min_search_query_length # 2

# User Constraints
settings.min_username_length    # 3
settings.max_username_length   # 100
settings.max_email_length       # 254

# Password
settings.min_password_length    # 8
settings.max_password_length    # 128
settings.bcrypt_rounds         # 12

# Content
settings.max_content_length     # 10000
settings.max_title_length       # 255
```

### Input Sanitization

```python
from app.utils.helpers import sanitize_text

# Always sanitize user inputs
username = sanitize_text(user_data.username.strip(), max_length=settings.max_username_length)
email = sanitize_text(user_data.email.lower().strip(), max_length=settings.max_email_length)
```

### Repository Pattern

```python
from app.db.repositories import UserRepository

user_repo = UserRepository(session)
user = await user_repo.get_by_id(user_id)
users = await user_repo.search_users(query="search", limit=10)
```

### Error Handling

```python
from fastapi import HTTPException, status

# Existence check
if not resource:
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Resource not found"
    )

# Permission check
can_action, message = StateMachine.can_action(resource, user_id)
if not can_action:
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=message
    )
```

### API Endpoint Pattern

```python
@router.post("/endpoint", response_model=ResponseSchema)
async def endpoint(
    data: RequestSchema,
    current_user: CurrentUser,
    session: DatabaseSession
) -> ResponseSchema:
    # 1. Sanitize inputs
    sanitized = sanitize_text(data.field, max_length=settings.max_length)
    
    # 2. Validate
    if not validate(sanitized):
        raise HTTPException(status_code=400, detail="Invalid input")
    
    # 3. Check permissions
    can_action, message = StateMachine.can_action(resource, current_user.id)
    if not can_action:
        raise HTTPException(status_code=403, detail=message)
    
    # 4. Process
    result = await repo.create(...)
    
    # 5. Return
    return ResponseSchema.model_validate(result)
```

---

## Frontend Quick Reference

### Constants

**Location**: `frontend/lib/core/constants/app_constants.dart`

```dart
import 'package:openon_app/core/constants/app_constants.dart';

// UI Dimensions
AppConstants.bottomNavHeight      // 60.0
AppConstants.fabSize              // 56.0
AppConstants.userAvatarSize       // 48.0

// Animation Durations
AppConstants.animationDurationShort   // 200ms
AppConstants.animationDurationMedium   // 300ms
AppConstants.animationDurationLong    // 500ms

// Validation
AppConstants.maxContentLength     // 10000
AppConstants.maxTitleLength        // 200
AppConstants.minPasswordLength     // 8

// Opacity
AppConstants.opacityLow            // 0.1
AppConstants.opacityMedium         // 0.3
AppConstants.opacityHigh           // 0.6
```

### State Management (Riverpod)

```dart
// Watch provider
final userAsync = ref.watch(currentUserProvider);

// Read provider (one-time)
final user = ref.read(currentUserProvider);

// Create provider
final myProvider = Provider((ref) => MyClass());

// Future provider
final dataProvider = FutureProvider((ref) async {
  return await fetchData();
});

// State provider
final counterProvider = StateProvider((ref) => 0);
```

### Error Handling

```dart
import 'package:openon_app/core/errors/app_exceptions.dart';

try {
  await apiClient.get('/endpoint');
} on NetworkException catch (e) {
  // Handle network error
  showError(e.message);
} on ValidationException catch (e) {
  // Handle validation error
  showError(e.message);
} on AppException catch (e) {
  // Handle other app errors
  showError(e.message);
}
```

### Widget Pattern

```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);
    
    return dataAsync.when(
      data: (data) => _buildContent(data),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorDisplay(message: error.toString()),
    );
  }
  
  Widget _buildContent(Data data) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      child: Text(data.title),
    );
  }
}
```

### API Client Usage

```dart
import 'package:openon_app/core/data/api_client.dart';

final apiClient = ApiClient();

// GET
final data = await apiClient.get('/endpoint', queryParams: {'key': 'value'});

// POST
final result = await apiClient.post('/endpoint', {'field': 'value'});

// PUT
final updated = await apiClient.put('/endpoint', {'field': 'newValue'});

// DELETE
await apiClient.delete('/endpoint');
```

---

## Common Patterns

### Backend: Pagination

```python
@router.get("", response_model=ListResponse)
async def list_items(
    page: int = Query(settings.default_page, ge=1),
    page_size: int = Query(settings.default_page_size, ge=settings.min_page_size, le=settings.max_page_size)
):
    skip = (page - 1) * page_size
    items = await repo.get_all(skip=skip, limit=page_size)
    total = await repo.count()
    return ListResponse(items=items, total=total, page=page, page_size=page_size)
```

### Frontend: Loading States

```dart
final dataAsync = ref.watch(dataProvider);

dataAsync.when(
  data: (data) => ListView.builder(
    itemCount: data.length,
    itemBuilder: (context, index) => ItemWidget(data[index]),
  ),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, stack) => ErrorDisplay(
    message: 'Failed to load data',
    onRetry: () => ref.invalidate(dataProvider),
  ),
)
```

### Frontend: Theme-Aware Colors

```dart
final colorScheme = ref.watch(selectedColorSchemeProvider);
final isDeepBlueTheme = colorScheme.id == 'deep_blue';

Text(
  'Hello',
  style: TextStyle(
    color: isDeepBlueTheme 
        ? Colors.white 
        : AppTheme.textGrey,
  ),
)
```

---

## File Locations

### Backend

| Purpose | Location |
|---------|----------|
| Configuration | `backend/app/core/config.py` |
| API Routes | `backend/app/api/` |
| Repositories | `backend/app/db/repositories.py` |
| Models | `backend/app/db/models.py` |
| Schemas | `backend/app/models/schemas.py` |
| Services | `backend/app/services/` |
| Utilities | `backend/app/utils/helpers.py` |
| Security | `backend/app/core/security.py` |

### Frontend

| Purpose | Location |
|---------|----------|
| Constants | `frontend/lib/core/constants/app_constants.dart` |
| API Client | `frontend/lib/core/data/api_client.dart` |
| Models | `frontend/lib/core/models/models.dart` |
| Providers | `frontend/lib/core/providers/providers.dart` |
| Router | `frontend/lib/core/router/app_router.dart` |
| Theme | `frontend/lib/core/theme/` |
| Common Widgets | `frontend/lib/core/widgets/common_widgets.dart` |
| Features | `frontend/lib/features/` |

---

## Common Commands

### Backend

```bash
# Run server
uvicorn app.main:app --reload

# Run tests
pytest

# Check code
ruff check .
mypy app/
```

### Frontend

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Analyze code
flutter analyze

# Format code
dart format lib/
```

---

**Last Updated**: January 2025

