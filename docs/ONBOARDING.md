# Developer Onboarding Guide

Welcome to the OpenOn project! This guide will help you get started quickly and understand the codebase structure.

## 🚀 Quick Start

### Prerequisites

- **Backend**: Python 3.11+, FastAPI, SQLAlchemy
- **Frontend**: Flutter 3.0+, Dart 3.0+
- **Tools**: Git, IDE (VS Code recommended)

### First Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd openon
   ```

2. **Backend Setup**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Frontend Setup**
   ```bash
   cd frontend
   flutter pub get
   ```

4. **Run the Application**
   - Backend: `cd backend && uvicorn app.main:app --reload`
   - Frontend: `cd frontend && flutter run`

## 📚 Documentation Structure

### Essential Reading (In Order)

1. **[README.md](../README.md)** - Project overview
2. **[docs/README.md](./README.md)** - Documentation navigation
3. **[docs/INDEX.md](./INDEX.md)** - Master documentation index
4. **[docs/ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture
5. **[docs/CODE_STRUCTURE.md](./CODE_STRUCTURE.md)** - Code organization
6. **[docs/SEQUENCE_DIAGRAMS.md](./SEQUENCE_DIAGRAMS.md)** - Complete user flow diagrams
7. **[docs/QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Quick reference for common tasks

### Backend Developers

1. **[docs/backend/GETTING_STARTED.md](./backend/GETTING_STARTED.md)** - Backend quick start
2. **[docs/backend/ARCHITECTURE.md](./backend/ARCHITECTURE.md)** - Backend architecture
3. **[docs/backend/CODE_STRUCTURE.md](./backend/CODE_STRUCTURE.md)** - Backend code structure
4. **[docs/backend/API_REFERENCE.md](./backend/API_REFERENCE.md)** - API endpoints
5. **[docs/backend/SECURITY.md](./backend/SECURITY.md)** - Security practices

### Frontend Developers

1. **[docs/frontend/GETTING_STARTED.md](./frontend/GETTING_STARTED.md)** - Frontend quick start
2. **[docs/frontend/DEVELOPMENT_GUIDE.md](./frontend/DEVELOPMENT_GUIDE.md)** - Development guide
3. **[docs/frontend/CORE_COMPONENTS.md](./frontend/CORE_COMPONENTS.md)** - Core components
4. **[docs/frontend/THEME_SYSTEM.md](./frontend/THEME_SYSTEM.md)** - Theming system
5. **[docs/frontend/features/](./frontend/features/)** - Feature-specific docs

## 🏗️ Project Structure

### Backend Structure

```
backend/app/
├── api/              # FastAPI routes
│   ├── auth.py       # Authentication endpoints
│   ├── capsules.py   # Capsule management
│   └── recipients.py # Recipient management
├── core/             # Core functionality
│   ├── config.py     # Configuration (settings)
│   ├── security.py   # JWT, password hashing
│   └── logging.py    # Logging system
├── db/               # Database layer
│   ├── models.py     # SQLAlchemy models
│   ├── repositories.py # Repository pattern
│   └── repository.py # Base repository
├── models/           # Pydantic schemas
│   └── schemas.py    # Request/response models
├── services/         # Business logic
│   ├── state_machine.py # Capsule state machine
│   └── unlock_service.py # Unlock logic
└── utils/            # Utilities
    └── helpers.py    # Helper functions
```

### Frontend Structure

```
frontend/lib/
├── core/             # Core functionality
│   ├── constants/    # AppConstants
│   ├── data/         # API client, repositories
│   ├── models/       # Data models
│   ├── providers/    # Riverpod providers
│   ├── router/       # Navigation
│   ├── theme/        # Theming system
│   ├── utils/        # Utilities
│   └── widgets/      # Common widgets
├── features/         # Feature modules
│   ├── auth/         # Authentication
│   ├── home/         # Home screen
│   ├── capsule/      # Capsule viewing
│   ├── create_capsule/ # Letter creation
│   ├── recipients/   # Recipient management
│   ├── profile/      # Profile & settings
│   └── receiver/     # Receiver inbox
└── animations/       # Animation system
```

## 🔑 Key Concepts

### Backend Concepts

1. **Repository Pattern**: Data access layer abstraction
2. **State Machine**: Capsule lifecycle management
3. **Settings**: All constants in `app.core.config.Settings`
4. **Input Sanitization**: All inputs sanitized via `sanitize_text()`
5. **Access Control**: State machine enforces permissions

### Frontend Concepts

1. **Riverpod**: State management solution
2. **AppConstants**: All magic numbers centralized
3. **Feature-based Structure**: Each feature is self-contained
4. **Theme System**: Dynamic theming with color schemes
5. **Animation System**: Optimized custom painters

## 📝 Coding Standards

### Backend Standards

1. **Use Settings Constants**
   ```python
   # ❌ Bad
   limit = 100
   
   # ✅ Good
   from app.core.config import settings
   limit = settings.default_page_size
   ```

2. **Sanitize All Inputs**
   ```python
   # ✅ Always sanitize
   username = sanitize_text(user_data.username.strip(), max_length=settings.max_username_length)
   ```

3. **Use Repository Pattern**
   ```python
   # ✅ Use repositories
   user_repo = UserRepository(session)
   user = await user_repo.get_by_id(user_id)
   ```

4. **Error Handling**
   ```python
   # ✅ Consistent error handling
   if not resource:
       raise HTTPException(
           status_code=status.HTTP_404_NOT_FOUND,
           detail="Resource not found"
       )
   ```

### Frontend Standards

1. **Use AppConstants**
   ```dart
   // ❌ Bad
   const duration = Duration(milliseconds: 200);
   
   // ✅ Good
   const duration = AppConstants.animationDurationShort;
   ```

2. **Widget Decomposition**
   ```dart
   // ✅ Break down large widgets
   class _CapsuleCard extends ConsumerWidget {
     // Focused, reusable widget
   }
   ```

3. **Error Handling**
   ```dart
   // ✅ Use custom exceptions
   try {
     await apiClient.get('/endpoint');
   } on NetworkException catch (e) {
     // Handle network error
   } on ValidationException catch (e) {
     // Handle validation error
   }
   ```

4. **State Management**
   ```dart
   // ✅ Use Riverpod providers
   final userAsync = ref.watch(currentUserProvider);
   ```

## 🛠️ Development Workflow

### Making Changes

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes following standards**
   - Use constants (settings/AppConstants)
   - Follow existing patterns
   - Add proper error handling
   - Write clear code

3. **Test your changes**
   - Backend: Run tests, test API endpoints
   - Frontend: Test on device/emulator

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: description of changes"
   git push origin feature/your-feature-name
   ```

### Code Review Checklist

- [ ] Uses constants (no hardcoded values)
- [ ] Follows existing patterns
- [ ] Proper error handling
- [ ] Input validation/sanitization (backend)
- [ ] Security considerations
- [ ] Performance considerations
- [ ] Documentation updated if needed

## 🔍 Common Tasks

### Adding a New API Endpoint

1. **Create route in `backend/app/api/`**
   ```python
   @router.post("/new-endpoint")
   async def new_endpoint(
       data: NewSchema,
       current_user: CurrentUser,
       session: DatabaseSession
   ):
       # Implementation
   ```

2. **Add schema in `backend/app/models/schemas.py`**
   ```python
   class NewSchema(BaseModel):
       field: str = Field(..., max_length=settings.max_field_length)
   ```

3. **Add repository method if needed**
   ```python
   async def new_method(self, ...):
       # Implementation
   ```

### Adding a New Frontend Feature

1. **Create feature folder**
   ```
   frontend/lib/features/new_feature/
   ├── new_feature_screen.dart
   └── new_feature_providers.dart
   ```

2. **Add route in `frontend/lib/core/router/app_router.dart`**
   ```dart
   GoRoute(
     path: '/new-feature',
     builder: (context, state) => const NewFeatureScreen(),
   ),
   ```

3. **Add providers if needed**
   ```dart
   final newFeatureProvider = FutureProvider((ref) async {
     // Implementation
   });
   ```

## 🐛 Debugging

### Backend Debugging

1. **Check logs**
   ```bash
   # Logs are in console
   # Check for error messages
   ```

2. **Test API endpoints**
   ```bash
   # Use Swagger UI
   http://localhost:8000/docs
   ```

3. **Database inspection**
   ```bash
   # Supabase Studio (Web UI)
   # Open: http://localhost:54323
   # Or connect via psql:
   cd supabase
   supabase db connect
   ```

### Frontend Debugging

1. **Flutter DevTools**
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

2. **Debug Console**
   - Check for error messages
   - Use `Logger.debug()` for debugging

3. **Hot Reload**
   - Press `r` in terminal for hot reload
   - Press `R` for hot restart

## 📖 Learning Resources

### Backend

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [Pydantic Documentation](https://docs.pydantic.dev/)

### Frontend

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

### Project-Specific

- **[REFACTORING.md](./REFACTORING.md)** - Consolidated refactoring documentation (read when needed)
- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Common patterns and tasks

## ❓ Getting Help

1. **Check Documentation**
   - Start with [docs/README.md](./README.md)
   - Search for relevant topic

2. **Review Existing Code**
   - Look at similar implementations
   - Follow existing patterns

3. **Ask Questions**
   - Team chat/email
   - Code review comments

## ✅ Onboarding Checklist

- [ ] Repository cloned and set up
- [ ] Backend running locally
- [ ] Frontend running locally
- [ ] Read architecture documentation
- [ ] Read refactoring documentation
- [ ] Understand code structure
- [ ] Familiar with coding standards
- [ ] Can make and test changes
- [ ] Understand development workflow

---

**Welcome to the team!** 🎉

If you have questions, don't hesitate to ask. The codebase is well-documented and follows best practices.

