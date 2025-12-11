# Backend Architecture

This document describes the architecture and design patterns used in the OpenOn backend, matching the Supabase schema.

## 🏗️ System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────┐
│                    FastAPI Application                    │
│                      (app/main.py)                        │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐  ┌───────▼────────┐  ┌───────▼────────┐
│   API Layer    │  │  Service Layer │  │  Data Layer    │
│  (app/api/)    │  │ (app/services/)│  │ (app/db/)      │
│  + Helpers     │  │ + Connection   │  │ (repositories) │
│  (helpers.py)  │  │   Service ⭐   │  │                │
└────────────────┘  └────────────────┘  └────────────────┘
        │                   │                   │
        │                   │                   │
┌───────▼───────────────────▼───────────────────▼────────┐
│              Background Workers & Schedulers               │
│              (app/workers/, app/services/)                │
└──────────────────────────────────────────────────────────┘
                            │
                    ┌───────▼───────┐
                    │   Supabase    │
                    │  PostgreSQL   │
                    │  + Auth       │
                    └───────────────┘
```

## 📦 Layer Architecture

### 1. API Layer (`app/api/`)

**Responsibility**: HTTP request handling, validation, response formatting

**Components**:
- `auth.py` - User profile endpoints (Supabase handles signup/login)
- `capsules.py` - Capsule management endpoints
- `recipients.py` - Recipient management endpoints

**Pattern**: RESTful API with FastAPI routers

**Key Features**:
- Request validation using Pydantic schemas
- Authentication via Supabase JWT tokens
- Error handling with HTTP exceptions
- Input sanitization

**Note**: Drafts feature removed - not in Supabase schema. Capsules are created directly in 'sealed' status with an unlock time.

### 2. Service Layer (`app/services/`)

**Responsibility**: Business logic, state management, orchestration

**Components**:
- `state_machine.py` - Capsule status transition logic
- `unlock_service.py` - Automated unlock checking

**Pattern**: Service-oriented architecture

**Key Features**:
- State machine pattern for capsule lifecycle
- Business rule enforcement
- Time-based automation

### 3. Data Layer (`app/db/`)

**Responsibility**: Data persistence, database operations

**Components**:
- `models.py` - SQLAlchemy ORM models (matching Supabase schema)
- `repository.py` - Base repository pattern
- `repositories.py` - Specific repositories
- `base.py` - Database connection and session management

**Pattern**: Repository pattern

**Key Features**:
- Async SQLAlchemy ORM
- Repository abstraction
- Connection pooling
- Optimized queries
- Matches Supabase PostgreSQL schema exactly

### 4. Core Layer (`app/core/`)

**Responsibility**: Configuration, security, logging

**Components**:
- `config.py` - Application settings (includes Supabase JWT secret)
- `security.py` - Supabase JWT verification, password hashing
- `logging.py` - Structured logging

**Pattern**: Configuration as code

**Key Features**:
- Environment-based configuration
- Supabase JWT token verification
- Centralized security utilities

### 5. Middleware Layer (`app/middleware/`)

**Responsibility**: Request processing, security, logging

**Components**:
- `rate_limiting.py` - Rate limiting middleware (60 requests/minute per IP)
- `request_logging.py` - Request/response logging middleware

**Pattern**: Middleware pattern

**Key Features**:
- Sliding window rate limiting
- Comprehensive request logging
- Security audit trail
- Structured logging

### 6. Utilities Layer (`app/utils/`)

**Responsibility**: Helper functions, validators

**Components**:
- `helpers.py` - Validation, sanitization, timezone handling

**Pattern**: Utility functions

**Key Features**:
- Input validation
- Text sanitization
- Timezone-aware datetime handling

## 🔄 Data Flow

### Request Flow

```
1. HTTP Request
   ↓
2. FastAPI Router (app/api/*)
   ↓
3. Dependency Injection (Supabase JWT auth, database session)
   ↓
4. Request Validation (Pydantic schemas)
   ↓
5. Service Layer (business logic)
   ↓
6. Repository Layer (data access)
   ↓
7. Supabase PostgreSQL (SQLAlchemy ORM)
   ↓
8. Response (Pydantic schemas)
   ↓
9. HTTP Response
```

### Capsule Status Flow (Supabase)

```
SEALED → READY → OPENED
  │        │        │
  │        │        └─ Terminal state
  │        └─ Can be opened
  └─ Unlock time set (can be edited before opening)
```

**Status Values**:
- `sealed`: Capsule created with unlock time set
- `ready`: Unlock time has passed, recipient can open
- `opened`: Recipient has opened the capsule (terminal)
- `expired`: Soft-deleted or expired (disappearing messages)

## 🎨 Design Patterns

### 1. Repository Pattern

**Purpose**: Abstract data access layer

**Implementation**:
- `BaseRepository` - Generic CRUD operations
- Specific repositories (`UserProfileRepository`, `CapsuleRepository`, `RecipientRepository`, etc.)

**Benefits**:
- Testability (easy to mock)
- Database independence
- Centralized data access logic

**Files**:
- `backend/app/db/repository.py` - Base repository
- `backend/app/db/repositories.py` - Specific repositories

### 2. Dependency Injection

**Purpose**: Loose coupling, testability

**Implementation**:
- FastAPI's `Depends()` for dependencies
- `CurrentUser` - Authenticated user from Supabase JWT
- `DatabaseSession` - Database session injection

**Benefits**:
- Easy testing
- Clear dependencies
- Automatic lifecycle management

### 3. State Machine Pattern

**Purpose**: Enforce valid status transitions

**Implementation**:
- `CapsuleStateMachine` class
- Valid transition definitions
- Permission checks per status

**Benefits**:
- Prevents invalid states
- Clear business rules
- Type-safe status management

### 4. Service Layer Pattern ⭐ NEW

**Purpose**: Separate business logic from API layer

**Implementation**:
- Service classes for complex operations
- Background workers for automation
- **ConnectionService** - Encapsulates connection business logic

**Example**:
```python
# backend/app/services/connection_service.py
class ConnectionService:
    async def check_existing_connection(self, user_id_1, user_id_2) -> bool:
        # Business logic for checking connections
        pass
    
    async def create_connection(self, user_id_1, user_id_2) -> None:
        # Business logic for creating connections with auto-recipient creation
        pass
```

**Benefits**:
- Reusable business logic
- Easier testing
- Clear separation of concerns
- Eliminates code duplication across endpoints

**Files**:
- `backend/app/services/connection_service.py` - Connection business logic
- `backend/app/services/state_machine.py` - Capsule state machine
- `backend/app/services/unlock_service.py` - Unlock logic

## 🔐 Security Architecture

### Authentication Flow (Supabase)

```
1. User signs up/logs in via Supabase Auth
   ↓
2. Supabase returns JWT token
   ↓
3. Client includes token in requests
   ↓
4. FastAPI validates Supabase JWT token
   ↓
5. Extract user_id from token (sub claim)
   ↓
6. Look up UserProfile in database
   ↓
7. Inject UserProfile into endpoint
```

### Authorization

- **Owner-based**: Users can only access their own resources
- **Status-based**: Operations depend on capsule status
- **Role-based**: Admin flag in UserProfile for elevated permissions

### Input Validation

- **Pydantic schemas**: Request/response validation
- **Custom validators**: Business rule validation
- **Sanitization**: Text cleaning and normalization

## ⚡ Performance Architecture

### Async Operations

- **Async/await**: All I/O operations are async
- **Database**: Async SQLAlchemy with PostgreSQL
- **HTTP**: Async FastAPI

### Database Optimization

- **Indexes**: On frequently queried fields (see Supabase migrations)
- **Connection pooling**: Reuse database connections
- **Query optimization**: Efficient queries, no N+1 problems
- **Partial indexes**: For filtered queries (e.g., premium users)

### Background Processing

- **APScheduler**: Background job scheduling
- **Worker process**: Independent from API server
- **Scheduled tasks**: Automatic status updates (sealed → ready)

## 🔄 Background Worker Architecture

```
┌─────────────────────────────────────┐
│      APScheduler Worker              │
│  (app/workers/scheduler.py)         │
└─────────────────────────────────────┘
              │
              │ Every 60 seconds
              ▼
┌─────────────────────────────────────┐
│    Unlock Service                    │
│  (app/services/unlock_service.py)    │
└─────────────────────────────────────┘
              │
              │ Check capsules
              ▼
┌─────────────────────────────────────┐
│    Capsule Repository                │
│  (app/db/repositories.py)            │
└─────────────────────────────────────┘
              │
              │ Update status (sealed → ready)
              ▼
┌─────────────────────────────────────┐
│    Supabase PostgreSQL               │
│  (Triggers handle opened status)     │
└─────────────────────────────────────┘
```

## 📊 Database Schema (Supabase)

### Entity Relationships

```
UserProfile (extends Supabase Auth)
 ├── sent_capsules (Capsule[])
 └── recipients (Recipient[])

Capsule
 ├── sender_profile (UserProfile)
 ├── recipient (Recipient)
 ├── theme (Theme, optional)
 └── animation (Animation, optional)

Recipient
 └── owner_profile (UserProfile)

Theme
 └── capsules (Capsule[])

Animation
 └── capsules (Capsule[])
```

### Key Tables

- **user_profiles**: Extends Supabase Auth with app-specific data
- **capsules**: Time-locked letters with status tracking
- **recipients**: Saved contacts with relationship types
- **themes**: Visual themes for letters
- **animations**: Reveal animations
- **notifications**: User notifications
- **user_subscriptions**: Premium subscription tracking
- **audit_logs**: Action logging for security

### Key Constraints

- **Foreign Keys**: Enforced at database level (references auth.users)
- **Indexes**: On frequently queried fields (see migrations)
- **Timezone-aware**: All timestamps in UTC
- **Soft Deletes**: `deleted_at` for disappearing messages
- **RLS Policies**: Row-level security for data access

## 🧪 Testing Architecture

### Test Structure

```
tests/
 ├── conftest.py          # Test fixtures
 ├── test_state_machine.py # State machine tests
 └── test_repositories.py  # Repository tests
```

### Testing Patterns

- **Unit tests**: Test individual components
- **Integration tests**: Test component interactions
- **Fixtures**: Reusable test data

## 🚀 Deployment Architecture

### Development

```
uvicorn app.main:app --reload
```

### Production

```
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### Background Worker

```
# Runs automatically with main app (via lifespan)
```

## 📈 Scalability Considerations

### Current Design

- **Stateless API**: Can scale horizontally
- **Database**: Supabase PostgreSQL (scalable)
- **Async**: Handles concurrent requests efficiently
- **Connection Pooling**: Efficient database connections

### Future Enhancements

- **Caching**: Redis for frequently accessed data
- **Message Queue**: For background job processing
- **Load Balancing**: Multiple API instances
- **Database Replication**: Read replicas via Supabase

## 🔗 Integration Points

### Frontend Integration

- **REST API**: Standard HTTP/JSON
- **CORS**: Configured for frontend origins
- **Authentication**: Supabase JWT tokens

### External Services

- **Supabase Auth**: User authentication and management
- **Supabase Storage**: Media file storage
- **Notifications**: Extensible provider system
- **Email**: SMTP configuration ready

## 📝 Key Architectural Decisions

1. **FastAPI**: Modern, fast, async framework
2. **SQLAlchemy**: Mature ORM with async support
3. **Pydantic**: Type-safe validation
4. **Repository Pattern**: Clean data access
5. **State Machine**: Enforce business rules
6. **Async Everything**: Better performance
7. **UTC Timestamps**: Avoid timezone issues
8. **Configuration as Code**: Environment-based settings
9. **Supabase Integration**: Auth, Database, Storage
10. **JWT Authentication**: Stateless, scalable

## 🔄 Migration from Old Schema

### Key Changes

1. **Authentication**: Now uses Supabase Auth (no custom user table)
2. **User Model**: Replaced with `UserProfile` (extends Supabase Auth)
3. **Capsules**: `receiver_id` → `recipient_id`, `state` → `status`, `scheduled_unlock_at` → `unlocks_at`
4. **Status Flow**: Simplified from 5 states to 4 (removed `draft` and `unfolding`)
5. **Drafts**: Removed (not in Supabase schema)
6. **Recipients**: Added `relationship` enum and `avatar_url`
7. **New Models**: Theme, Animation, Notification, UserSubscription, AuditLog

### Backward Compatibility

- Legacy Pydantic models kept for reference (not used)
- Old API endpoints removed (signup/login handled by Supabase)
- Frontend needs updates to match new API structure

---

**Last Updated**: 2025-01-XX (Post Supabase Migration)
