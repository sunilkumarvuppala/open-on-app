# Backend Architecture

This document describes the architecture and design patterns used in the OpenOn backend.

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
└────────────────┘  └────────────────┘  └────────────────┘
        │                   │                   │
        │                   │                   │
┌───────▼───────────────────▼───────────────────▼────────┐
│              Background Workers & Schedulers               │
│              (app/workers/, app/services/)                │
└──────────────────────────────────────────────────────────┘
                            │
                    ┌───────▼───────┐
                    │   Database    │
                    │ (SQLite/PostgreSQL) │
                    └───────────────┘
```

## 📦 Layer Architecture

### 1. API Layer (`app/api/`)

**Responsibility**: HTTP request handling, validation, response formatting

**Components**:
- `auth.py` - Authentication endpoints
- `capsules.py` - Capsule management endpoints
- `drafts.py` - Draft management endpoints
- `recipients.py` - Recipient management endpoints

**Pattern**: RESTful API with FastAPI routers

**Key Features**:
- Request validation using Pydantic schemas
- Authentication via dependency injection
- Error handling with HTTP exceptions
- Input sanitization

### 2. Service Layer (`app/services/`)

**Responsibility**: Business logic, state management, orchestration

**Components**:
- `state_machine.py` - Capsule state transition logic
- `unlock_service.py` - Automated unlock checking

**Pattern**: Service-oriented architecture

**Key Features**:
- State machine pattern for capsule lifecycle
- Business rule enforcement
- Time-based automation

### 3. Data Layer (`app/db/`)

**Responsibility**: Data persistence, database operations

**Components**:
- `models.py` - SQLAlchemy ORM models
- `repository.py` - Base repository pattern
- `repositories.py` - Specific repositories
- `base.py` - Database connection and session management

**Pattern**: Repository pattern

**Key Features**:
- Async SQLAlchemy ORM
- Repository abstraction
- Connection pooling
- Optimized queries

### 4. Core Layer (`app/core/`)

**Responsibility**: Configuration, security, logging

**Components**:
- `config.py` - Application settings
- `security.py` - JWT authentication, password hashing
- `logging.py` - Structured logging

**Pattern**: Configuration as code

**Key Features**:
- Environment-based configuration
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

### 5. Utilities Layer (`app/utils/`)

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
3. Dependency Injection (auth, database session)
   ↓
4. Request Validation (Pydantic schemas)
   ↓
5. Service Layer (business logic)
   ↓
6. Repository Layer (data access)
   ↓
7. Database (SQLAlchemy ORM)
   ↓
8. Response (Pydantic schemas)
   ↓
9. HTTP Response
```

### Capsule State Flow

```
DRAFT → SEALED → UNFOLDING → READY → OPENED
  │        │         │         │        │
  │        │         │         │        └─ Final state
  │        │         │         └─ Can be opened
  │        │         └─ < 3 days until unlock
  │        └─ Unlock time set
  └─ Editable
```

## 🎨 Design Patterns

### 1. Repository Pattern

**Purpose**: Abstract data access layer

**Implementation**:
- `BaseRepository` - Generic CRUD operations
- Specific repositories (`UserRepository`, `CapsuleRepository`, etc.)

**Benefits**:
- Testability (easy to mock)
- Database independence
- Centralized data access logic

### 2. Dependency Injection

**Purpose**: Loose coupling, testability

**Implementation**:
- FastAPI's `Depends()` for dependencies
- `CurrentUser` - Authenticated user injection
- `DatabaseSession` - Database session injection

**Benefits**:
- Easy testing
- Clear dependencies
- Automatic lifecycle management

### 3. State Machine Pattern

**Purpose**: Enforce valid state transitions

**Implementation**:
- `CapsuleStateMachine` class
- Valid transition definitions
- Permission checks per state

**Benefits**:
- Prevents invalid states
- Clear business rules
- Type-safe state management

### 4. Service Layer Pattern

**Purpose**: Separate business logic from API layer

**Implementation**:
- Service classes for complex operations
- Background workers for automation

**Benefits**:
- Reusable business logic
- Easier testing
- Clear separation of concerns

## 🔐 Security Architecture

### Authentication Flow

```
1. User provides credentials
   ↓
2. Validate credentials
   ↓
3. Generate JWT tokens (access + refresh)
   ↓
4. Return tokens to client
   ↓
5. Client includes token in requests
   ↓
6. FastAPI validates token
   ↓
7. Extract user from token
   ↓
8. Inject user into endpoint
```

### Authorization

- **Owner-based**: Users can only access their own resources
- **State-based**: Operations depend on capsule state
- **Role-based**: Ready for future role expansion

### Input Validation

- **Pydantic schemas**: Request/response validation
- **Custom validators**: Business rule validation
- **Sanitization**: Text cleaning and normalization

## ⚡ Performance Architecture

### Async Operations

- **Async/await**: All I/O operations are async
- **Database**: Async SQLAlchemy
- **HTTP**: Async FastAPI

### Database Optimization

- **Indexes**: On frequently queried fields
- **Connection pooling**: Reuse database connections
- **Query optimization**: Efficient queries, no N+1 problems

### Background Processing

- **APScheduler**: Background job scheduling
- **Worker process**: Independent from API server
- **Scheduled tasks**: Automatic state updates

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
              │ Update states
              ▼
┌─────────────────────────────────────┐
│    Notification Service              │
│  (app/notifications/service.py)      │
└─────────────────────────────────────┘
```

## 📊 Database Schema

### Entity Relationships

```
User
 ├── sent_capsules (Capsule[])
 ├── received_capsules (Capsule[])
 ├── drafts (Draft[])
 └── recipients (Recipient[])

Capsule
 ├── sender (User)
 └── receiver (User)

Draft
 └── owner (User)

Recipient
 └── owner (User)
```

### Key Constraints

- **Foreign Keys**: Enforced at database level
- **Unique Constraints**: Email, username
- **Indexes**: On frequently queried fields
- **Timezone-aware**: All timestamps in UTC

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
python -m app.workers.scheduler
```

## 📈 Scalability Considerations

### Current Design

- **Stateless API**: Can scale horizontally
- **Database**: Can switch to PostgreSQL
- **Async**: Handles concurrent requests efficiently

### Future Enhancements

- **Caching**: Redis for frequently accessed data
- **Message Queue**: For background job processing
- **Load Balancing**: Multiple API instances
- **Database Replication**: Read replicas

## 🔗 Integration Points

### Frontend Integration

- **REST API**: Standard HTTP/JSON
- **CORS**: Configured for frontend origins
- **Authentication**: JWT tokens

### External Services

- **Notifications**: Extensible provider system
- **Storage**: Ready for media storage integration
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

---

**Last Updated**: 2025

