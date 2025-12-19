# OpenOn Backend - Time-Locked Emotional Capsules

A production-ready FastAPI backend for managing time-locked emotional letters (capsules). Send messages that unlock at a specific future date with automatic state management and notifications.

## 🚀 Features

- **🔐 Secure Authentication**: JWT-based auth with Supabase Auth integration
- **📬 Time-Locked Capsules**: Send messages that unlock at a specific future date
- **🔄 State Machine**: Capsules follow strict state transitions
- **⏰ Automated Unlocking**: Background worker automatically updates capsule states
- **👥 Recipients**: Manage saved contacts with relationships
- **🔔 Notifications**: Push and email notifications (extensible)
- **✅ Full Test Coverage**: Unit tests for critical business logic

## 📋 Requirements

- Python 3.11+
- Poetry (or pip)
- Supabase (PostgreSQL) - See [docs/supabase/LOCAL_SETUP.md](../docs/supabase/LOCAL_SETUP.md) for setup

## 🛠️ Installation

### Using Poetry (Recommended)

```bash
cd backend
poetry install
```

### Using pip

```bash
cd backend
pip install -r requirements.txt
```

## 🔧 Configuration

Create a `.env` file in the `backend/` directory:

```env
# App
DEBUG=true

# Database (Supabase PostgreSQL)
# Get connection string from: supabase status
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:54322/postgres

# Security (CHANGE THIS IN PRODUCTION!)
SECRET_KEY=your-super-secret-key-here-change-in-production

# Supabase Configuration
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_KEY=your-service-role-key-from-supabase-status
SUPABASE_JWT_SECRET=your-jwt-secret-from-supabase-status

# CORS
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]

# Capsule Settings
MIN_UNLOCK_MINUTES=1
MAX_UNLOCK_YEARS=5

# Worker
WORKER_CHECK_INTERVAL_SECONDS=60

# Notifications (optional)
FCM_API_KEY=your-fcm-key
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_PORT=587
```

## 🚀 Running the Application

### Development Mode

```bash
# With Poetry
poetry run uvicorn app.main:app --reload

# With Python
python3 -m uvicorn app.main:app --reload
```

The API will be available at:
- **API**: http://localhost:8000
- **Interactive Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Production Mode

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## 🧪 Running Tests

```bash
# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=app --cov-report=html

# Run specific test file
poetry run pytest tests/test_state_machine.py -v
```

## 📚 Documentation

> **📖 Complete Backend Documentation**: See [docs/backend/INDEX.md](../docs/backend/INDEX.md) for full documentation index

## 📚 API Documentation

### Authentication

#### Sign Up
```http
POST /auth/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "username": "username",
  "password": "SecurePass123",
  "first_name": "John",
  "last_name": "Doe"
}
```

#### Log In
```http
POST /auth/login
Content-Type: application/json

{
  "username": "username",
  "password": "SecurePass123"
}
```

#### Get Current User
```http
GET /auth/me
Authorization: Bearer <access_token>
```

### Capsules

#### Create Capsule
```http
POST /capsules
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "recipient_id": "uuid",
  "title": "Happy Birthday!",
  "body_text": "This is your birthday message...",
  "unlocks_at": "2025-12-25T00:00:00Z",
  "is_anonymous": false,
  "is_disappearing": false
}
```

#### List Capsules
```http
GET /capsules?box=inbox&status=ready&page=1&page_size=20
Authorization: Bearer <access_token>
```

#### Open Capsule
```http
POST /capsules/{capsule_id}/open
Authorization: Bearer <access_token>
```

### Recipients

**Note**: Drafts feature has been removed. Capsules are created directly in 'sealed' status with an unlock time.

#### Add Recipient
```http
POST /recipients
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "relationship": "friend",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

## 🔄 Capsule State Machine

Capsules follow strict state transitions:

```
sealed → ready → opened
```

### State Descriptions

| State | Description | Can Edit? | Can View? |
|-------|-------------|-----------|-----------|
| **sealed** | Created with unlock time set, waiting | ✅ Sender (only if sealed) | ✅ Sender |
| **ready** | Unlock time has passed, ready to open | ❌ None | ✅ Sender, 🔓 Recipient |
| **opened** | Recipient has opened | ❌ None | ✅ Both |
| **expired** | Past expiration or soft-deleted | ❌ None | ❌ None |

### Rules

- **Capsules are created in 'sealed' status** - No draft state
- **Unlock times are immutable** - Cannot change after creation
- **UTC-only timestamps** - Prevents timezone manipulation
- **Automatic transitions** - Background worker updates states every minute
- **Can only edit if sealed** - Once ready or opened, cannot modify

## 🤖 Background Worker

The background worker runs automatically when the API starts:

- **Frequency**: Every 60 seconds (configurable)
- **Tasks**:
  - Check all sealed capsules
  - Update states from 'sealed' to 'ready' when unlock time arrives
  - Trigger notifications when capsules become ready
  - Log all state transitions

## 🏗️ Architecture

```
backend/
├── app/
│   ├── api/              # API route handlers
│   │   ├── auth.py       # Authentication endpoints
│   │   ├── capsules.py   # Capsule CRUD + state ops
│   │   └── recipients.py # Recipient management
│   ├── core/             # Core configuration
│   │   ├── config.py     # Settings management
│   │   ├── security.py   # JWT + password hashing
│   │   └── logging.py    # Logging setup
│   ├── db/               # Database layer
│   │   ├── base.py       # DB connection + session
│   │   ├── models.py     # SQLAlchemy models
│   │   ├── repository.py # Base repository
│   │   └── repositories.py # Specific repositories
│   ├── models/           # Pydantic schemas
│   │   └── schemas.py    # Request/response models
│   ├── services/         # Business logic
│   │   ├── state_machine.py  # Capsule state logic
│   │   └── unlock_service.py # Time-lock checking
│   ├── workers/          # Background tasks
│   │   └── scheduler.py  # APScheduler worker
│   ├── notifications/    # Notification system
│   │   └── service.py    # Push/email service
│   ├── utils/            # Utilities
│   │   └── helpers.py    # Timezone, validation
│   ├── dependencies.py   # FastAPI dependencies
│   └── main.py           # Application entry point
├── tests/
│   ├── conftest.py       # Test fixtures
│   ├── test_state_machine.py
│   └── test_repositories.py
└── pyproject.toml        # Project dependencies
```

## 🔒 Security Features

- **JWT Authentication**: Supabase Auth integration
- **Password Hashing**: BCrypt with salt
- **Input Validation**: Pydantic models with strict validation
- **SQL Injection Protection**: SQLAlchemy ORM
- **CORS**: Configurable allowed origins
- **Rate Limiting**: Ready to integrate (placeholder)

## 🔌 Database Configuration

The backend uses Supabase (PostgreSQL) for all environments:

```python
# Local Supabase (default)
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:54322/postgres

# Production Supabase
DATABASE_URL=postgresql+asyncpg://postgres:[PASSWORD]@[HOST]:5432/postgres
```

## 📊 Performance Optimizations

- **Async/Await**: Full async support for concurrent requests
- **Connection Pooling**: SQLAlchemy async connection pool
- **Database Indexes**: Optimized queries on frequently accessed fields
- **Lazy Loading**: Efficient relationship loading

## 🔔 Notification System

Extensible notification system with swappable providers:

```python
# Default: Mock provider (logs to console)
# Production: FCM, APNs, or custom provider

from app.notifications.service import get_notification_service

service = get_notification_service()
await service.notify_capsule_ready(receiver_id, email, title, sender)
```

## 🚀 Deployment

### Docker (Coming Soon)

```bash
docker build -t openon-backend .
docker run -p 8000:8000 openon-backend
```

### Systemd Service

```ini
[Unit]
Description=OpenOn Backend
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/openon/backend
ExecStart=/opt/openon/backend/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

## 📝 Development Guidelines

### Code Style

- **Formatting**: Black (line length: 100)
- **Linting**: Ruff
- **Type Checking**: MyPy (strict mode)

```bash
poetry run black app/
poetry run ruff check app/
poetry run mypy app/
```

### Adding New Features

1. Add database model in `app/db/models.py`
2. Create repository in `app/db/repositories.py`
3. Add Pydantic schemas in `app/models/schemas.py`
4. Implement API routes in `app/api/`
5. Write tests in `tests/`

## 🐛 Troubleshooting

### Database Connection Error
```bash
# Check if Supabase is running
cd ../supabase
supabase status

# If not running, start it
supabase start
```

### Worker Not Running
```bash
# Check logs for worker startup
# Ensure no other instances are running
```

### JWT Token Issues
```bash
# Check SUPABASE_JWT_SECRET matches Supabase project
# Get from: supabase status
```

## 📄 License

MIT License - Feel free to use this project for your own applications.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
2. Write tests for new features
3. Ensure all tests pass
4. Submit a pull request

## 📧 Support

For issues or questions:
- Open a GitHub issue
- Check the documentation at `/docs`
- Review the test files for usage examples

---

**Built with ❤️ using FastAPI, SQLAlchemy, and Python 3.11**
