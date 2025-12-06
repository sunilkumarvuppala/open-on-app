# Backend Code Structure

This document describes the organization and structure of the backend codebase.

## 📁 Directory Structure

```
backend/
├── app/                          # Main application package
│   ├── __init__.py
│   ├── main.py                  # Application entry point
│   ├── dependencies.py          # FastAPI dependencies
│   │
│   ├── api/                     # API endpoints (REST routes)
│   │   ├── __init__.py
│   │   ├── auth.py             # User profile endpoints (Supabase handles signup/login)
│   │   ├── capsules.py          # Capsule management endpoints
│   │   └── recipients.py       # Recipient management endpoints
│   │
│   ├── core/                    # Core configuration and utilities
│   │   ├── __init__.py
│   │   ├── config.py           # Application settings
│   │   ├── security.py         # JWT, password hashing
│   │   └── logging.py          # Logging configuration
│   │
│   ├── db/                      # Database layer
│   │   ├── __init__.py
│   │   ├── base.py             # Database connection, session
│   │   ├── models.py           # SQLAlchemy ORM models
│   │   ├── repository.py       # Base repository class
│   │   └── repositories.py     # Specific repositories
│   │
│   ├── models/                  # Pydantic schemas (request/response)
│   │   ├── __init__.py
│   │   └── schemas.py          # All Pydantic models
│   │
│   ├── services/                # Business logic
│   │   ├── __init__.py
│   │   ├── state_machine.py    # Capsule state transitions
│   │   └── unlock_service.py   # Automated unlock logic
│   │
│   ├── utils/                   # Utility functions
│   │   ├── __init__.py
│   │   └── helpers.py          # Validation, sanitization, timezone
│   │
│   ├── workers/                 # Background workers
│   │   ├── __init__.py
│   │   └── scheduler.py        # APScheduler integration
│   │
│   └── notifications/           # Notification system
│       ├── __init__.py
│       └── service.py           # Notification providers
│
├── tests/                       # Test suite
│   ├── __init__.py
│   ├── conftest.py             # Test fixtures
│   ├── test_state_machine.py   # State machine tests
│   └── test_repositories.py   # Repository tests
│
├── requirements.txt            # Python dependencies
├── pyproject.toml             # Poetry configuration
├── .env                        # Environment variables (not in git)
└── README.md                   # Project documentation
```

## 📄 File Organization

### API Layer (`app/api/`)

**Purpose**: HTTP endpoints, request handling

**Files**:
- `auth.py` - User profile management (Supabase handles signup/login)
- `capsules.py` - Capsule CRUD operations
- `recipients.py` - Recipient management

**Conventions**:
- One file per resource
- Router prefix matches resource name
- All endpoints require authentication (except signup/login)

### Core Layer (`app/core/`)

**Purpose**: Application-wide configuration and security

**Files**:
- `config.py` - Settings from environment variables (includes Supabase JWT secret)
- `security.py` - Supabase JWT verification, password hashing
- `logging.py` - Logging setup

**Conventions**:
- Singleton pattern for settings
- Security functions are pure (no side effects)
- Configuration validated on startup

### Database Layer (`app/db/`)

**Purpose**: Data persistence and access

**Files**:
- `base.py` - Database engine, session factory
- `models.py` - SQLAlchemy ORM models
- `repository.py` - Base repository with CRUD
- `repositories.py` - Specific repositories per model

**Conventions**:
- Models use timezone-aware datetimes
- Repositories are async
- Foreign keys explicitly defined

### Models Layer (`app/models/`)

**Purpose**: Request/response validation

**Files**:
- `schemas.py` - All Pydantic models

**Conventions**:
- Separate schemas for create/update/response
- Validation logic in validators
- Response models use `from_attributes=True`

### Services Layer (`app/services/`)

**Purpose**: Business logic

**Files**:
- `state_machine.py` - Capsule state transition rules
- `unlock_service.py` - Automated unlock checking

**Conventions**:
- Stateless service classes
- Pure business logic (no database access)
- Testable in isolation

### Utils Layer (`app/utils/`)

**Purpose**: Reusable utility functions

**Files**:
- `helpers.py` - Validation, sanitization, timezone

**Conventions**:
- Pure functions (no side effects)
- Well-documented
- Type hints required

### Workers Layer (`app/workers/`)

**Purpose**: Background processing

**Files**:
- `scheduler.py` - APScheduler setup and jobs

**Conventions**:
- Independent from API server
- Comprehensive logging
- Error handling and recovery

## 🏷️ Naming Conventions

### Files

- **snake_case**: All Python files use snake_case
- **Descriptive**: File names describe their purpose
- **Singular**: Model files are singular (e.g., `models.py`, not `models.py`)

### Classes

- **PascalCase**: All classes use PascalCase
- **Descriptive**: Class names clearly indicate purpose
- **Suffixes**:
  - `Repository` - Data access classes
  - `Service` - Business logic classes
  - `Response` - Pydantic response models
  - `Create` - Pydantic create models
  - `Update` - Pydantic update models

### Functions

- **snake_case**: All functions use snake_case
- **Verbs**: Function names start with verbs (e.g., `get_user`, `create_capsule`)
- **Async**: Async functions clearly indicate async nature

### Variables

- **snake_case**: All variables use snake_case
- **Descriptive**: Variable names are self-documenting
- **Constants**: UPPER_SNAKE_CASE for constants

## 📦 Module Organization

### Import Structure

```python
# Standard library
from datetime import datetime
from typing import Optional

# Third-party
from fastapi import APIRouter, HTTPException
from sqlalchemy import select

# Local imports
from app.core.config import settings
from app.db.models import UserProfile
from app.models.schemas import UserProfileResponse
```

### Import Order

1. Standard library
2. Third-party packages
3. Local application imports

### Circular Dependencies

- Avoided through dependency injection
- Models don't import from API layer
- Services don't import from API layer

## 🔗 Module Dependencies

```
app/main.py
  ├── app/api/* (routers)
  ├── app/core/config
  └── app/db/base

app/api/*
  ├── app/models/schemas
  ├── app/db/repositories
  ├── app/core/security
  └── app/utils/helpers

app/services/*
  ├── app/db/models
  └── app/core/config

app/db/repositories
  ├── app/db/models
  └── app/db/repository

app/db/models
  └── app/db/base
```

## 📝 Code Style

### Type Hints

- **Required**: All function signatures have type hints
- **Return types**: Explicit return types
- **Optional**: Use `Optional[T]` for nullable types

### Docstrings

- **Format**: Google style docstrings
- **Required**: All public functions and classes
- **Content**: Description, parameters, returns, raises

### Error Handling

- **HTTPException**: For API errors
- **Validation**: Pydantic for request validation
- **Logging**: Log errors before raising

### Async/Await

- **Consistent**: All I/O operations are async
- **Database**: All database operations are async
- **HTTP**: All HTTP requests are async

## 🧩 Component Responsibilities

### API Endpoints

- Validate requests
- Authenticate users
- Call services/repositories
- Format responses
- Handle errors

### Services

- Implement business logic
- Enforce business rules
- Coordinate between repositories
- No direct database access

### Repositories

- Data access only
- No business logic
- CRUD operations
- Query building

### Models

- Data structure definition
- Validation rules
- Serialization/deserialization

## 🔍 Code Examples

### API Endpoint

```python
@router.post("/capsules", response_model=CapsuleResponse)
async def create_capsule(
    capsule_data: CapsuleCreate,
    current_user: CurrentUser,
    session: DatabaseSession
) -> CapsuleResponse:
    """Create a new capsule."""
    # Validation, business logic, data access
    ...
```

### Repository Method

```python
async def get_by_sender(
    self,
    sender_id: UUID,
    status: Optional[CapsuleStatus] = None,
    skip: int = 0,
    limit: int = 100
) -> list[Capsule]:
    """Get capsules by sender."""
    query = select(Capsule).where(Capsule.sender_id == sender_id)
    ...
```

### Service Method

```python
@classmethod
def can_edit(cls, capsule: Capsule, user_id: UUID) -> tuple[bool, str]:
    """Check if user can edit capsule."""
    if capsule.status != CapsuleStatus.SEALED:
        return False, f"Cannot edit capsule in {capsule.status} status"
    ...
```

## 🎯 Best Practices

1. **Separation of Concerns**: Each layer has clear responsibilities
2. **DRY**: Don't repeat yourself - use shared utilities
3. **Type Safety**: Use type hints everywhere
4. **Error Handling**: Comprehensive error handling
5. **Logging**: Log important operations
6. **Testing**: Write tests for business logic
7. **Documentation**: Document public APIs
8. **Security**: Validate and sanitize all inputs

---

**Last Updated**: 2025-01-XX (Post Supabase Migration)

