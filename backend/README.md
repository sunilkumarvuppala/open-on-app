# OpenOn Backend - Time-Locked Emotional Capsules

A production-ready FastAPI backend for managing time-locked emotional letters (capsules). Send messages that unlock at a specific future date with automatic state management and notifications.

## 🚀 Features

- **🔐 Secure Authentication**: JWT-based auth with access and refresh tokens
- **📬 Time-Locked Capsules**: Send messages that unlock at a specific future date
- **🔄 State Machine**: Capsules follow strict state transitions
- **⏰ Automated Unlocking**: Background worker automatically updates capsule states
- **📝 Drafts**: Save and edit messages before sending
- **👥 Recipients**: Manage saved contacts
- **🔔 Notifications**: Push and email notifications (extensible)
- **✅ Full Test Coverage**: Unit tests for critical business logic

## 📋 Requirements

- Python 3.11+
- Poetry (or pip)
- SQLite (default) or PostgreSQL

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

# Database (SQLite default)
DATABASE_URL=sqlite+aiosqlite:///./openon.db

# Or use PostgreSQL
# DATABASE_URL=postgresql+asyncpg://user:password@localhost/openon

# Security (CHANGE THIS IN PRODUCTION!)
SECRET_KEY=your-super-secret-key-here-change-in-production

# CORS
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]

# Capsule Settings
MIN_UNLOCK_MINUTES=1
MAX_UNLOCK_YEARS=5
EARLY_VIEW_THRESHOLD_DAYS=3

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
python -m uvicorn app.main:app --reload
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
  "full_name": "John Doe"
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
  "receiver_id": "uuid",
  "title": "Happy Birthday!",
  "body": "This is your birthday message...",
  "media_urls": ["https://example.com/image.jpg"],
  "theme": "birthday",
  "allow_early_view": false,
  "allow_receiver_reply": true
}
```

#### Seal Capsule
```http
POST /capsules/{capsule_id}/seal
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "scheduled_unlock_at": "2025-12-25T00:00:00Z"
}
```

#### List Capsules
```http
GET /capsules?box=inbox&state=ready&page=1&page_size=20
Authorization: Bearer <access_token>
```

#### Open Capsule
```http
POST /capsules/{capsule_id}/open
Authorization: Bearer <access_token>
```

### Drafts

#### Create Draft
```http
POST /drafts
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "title": "Draft Title",
  "body": "Draft content...",
  "recipient_id": "uuid"
}
```

#### List Drafts
```http
GET /drafts
Authorization: Bearer <access_token>
```

#### Update Draft
```http
PUT /drafts/{draft_id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "title": "Updated Title"
}
```

### Recipients

#### Add Recipient
```http
POST /recipients
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "user_id": "uuid"
}
```

## 🔄 Capsule State Machine

Capsules follow strict state transitions:

```
draft → sealed → unfolding → ready → opened
```

### State Descriptions

| State | Description | Can Edit? | Can View? |
|-------|-------------|-----------|-----------|
| **draft** | Being created | ✅ Sender | ✅ Sender |
| **sealed** | Unlock time set, waiting | ❌ None | ✅ Sender |
| **unfolding** | < 3 days until unlock | ❌ None | ✅ Sender, 🔓 Receiver (if early_view) |
| **ready** | Time has arrived | ❌ None | ✅ Sender, 🔓 Receiver (if early_view) |
| **opened** | Receiver has opened | ❌ None | ✅ Both |

### Rules

- **States cannot be reversed** - Once sealed, you can't go back to draft
- **Unlock times are immutable** - Cannot change after sealing
- **UTC-only timestamps** - Prevents timezone manipulation
- **Automatic transitions** - Background worker updates states every minute

## 🤖 Background Worker

The background worker runs automatically when the API starts:

- **Frequency**: Every 60 seconds (configurable)
- **Tasks**:
  - Check all sealed/unfolding capsules
  - Update states based on unlock times
  - Trigger notifications when capsules become ready
  - Log all state transitions

## 🏗️ Architecture

```
backend/
├── app/
│   ├── api/              # API route handlers
│   │   ├── auth.py       # Authentication endpoints
│   │   ├── capsules.py   # Capsule CRUD + state ops
│   │   ├── drafts.py     # Draft management
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

- **JWT Authentication**: Access and refresh tokens
- **Password Hashing**: BCrypt with salt
- **Input Validation**: Pydantic models with strict validation
- **SQL Injection Protection**: SQLAlchemy ORM
- **CORS**: Configurable allowed origins
- **Rate Limiting**: Ready to integrate (placeholder)

## 🔌 Database Abstraction

The repository pattern allows easy database switching:

```python
# Current: SQLite
DATABASE_URL=sqlite+aiosqlite:///./openon.db

# Switch to PostgreSQL
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/openon

# Or Supabase (PostgreSQL)
DATABASE_URL=postgresql+asyncpg://[YOUR_SUPABASE_URL]
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

### Database Locked Error
```bash
# SQLite is locked - check for other running instances
pkill -f uvicorn
rm openon.db-wal openon.db-shm
```

### Worker Not Running
```bash
# Check logs for worker startup
# Ensure no other instances are running
```

### JWT Token Issues
```bash
# Regenerate secret key
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

## 📄 License

MIT License - Feel free to use this project for your own applications.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Ensure all tests pass
5. Submit a pull request

## 📧 Support

For issues or questions:
- Open a GitHub issue
- Check the documentation at `/docs`
- Review the test files for usage examples

---

**Built with ❤️ using FastAPI, SQLAlchemy, and Python 3.11**
