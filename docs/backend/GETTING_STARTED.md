# Backend Getting Started Guide

Get the OpenOn backend up and running in 5 minutes!

## 📋 Prerequisites

- **Python 3.11+** - Check with `python3 --version`
- **pip** or **Poetry** - Package manager
- **SQLite** (default) or **PostgreSQL** - Database

## 🚀 Quick Setup

### Step 1: Navigate to Backend Directory

```bash
cd backend
```

### Step 2: Install Dependencies

**Option A: Using pip (Recommended for quick start)**

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

**Option B: Using Poetry**

```bash
poetry install
```

### Step 3: Configure Environment

Create a `.env` file in the `backend/` directory:

```env
# App Configuration
DEBUG=true
APP_NAME=OpenOn API
APP_VERSION=1.0.0

# Database (SQLite default - no setup needed)
DATABASE_URL=sqlite+aiosqlite:///./openon.db

# Or use PostgreSQL
# DATABASE_URL=postgresql+asyncpg://user:password@localhost/openon

# Security (CHANGE THIS IN PRODUCTION!)
SECRET_KEY=your-super-secret-key-here-change-in-production

# CORS (allow frontend to connect)
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]

# Capsule Settings
MIN_UNLOCK_MINUTES=1
MAX_UNLOCK_YEARS=5
EARLY_VIEW_THRESHOLD_DAYS=3

# Background Worker
WORKER_CHECK_INTERVAL_SECONDS=60

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60
```

> **Note**: For development, you can use the default `SECRET_KEY`, but **always change it in production**!

### Step 4: Run the Server

```bash
# Development mode (with auto-reload)
uvicorn app.main:app --reload

# Or with Poetry
poetry run uvicorn app.main:app --reload
```

The API will be available at:
- **API Base**: http://localhost:8000
- **Interactive Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## ✅ Verify Installation

### Test Health Endpoint

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

### Test API Documentation

Open http://localhost:8000/docs in your browser. You should see the interactive API documentation.

## 🎯 First API Calls

### 1. Create a User

```bash
curl -X POST "http://localhost:8000/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "SecurePass123",
    "first_name": "Test",
    "last_name": "User"
  }'
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### 2. Login

```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "SecurePass123"
  }'
```

### 3. Get Current User Info

```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4. Create a Capsule

```bash
curl -X POST "http://localhost:8000/capsules" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "receiver_id": "USER_ID",
    "title": "My First Capsule",
    "body": "This is a time capsule!",
    "theme": "birthday"
  }'
```

## 🧪 Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app

# Run specific test file
pytest tests/test_state_machine.py -v

# Run with verbose output
pytest -v
```

## 📁 Project Structure

```
backend/
├── app/
│   ├── api/              # API endpoints
│   ├── core/             # Core configuration
│   ├── db/               # Database models & repositories
│   ├── models/           # Pydantic schemas
│   ├── services/         # Business logic
│   ├── utils/            # Utility functions
│   ├── workers/          # Background workers
│   └── main.py           # Application entry point
├── tests/                # Test suite
├── requirements.txt      # Python dependencies
├── pyproject.toml       # Poetry configuration
└── .env                  # Environment variables
```

## 🔧 Common Commands

### Development

```bash
# Start development server
uvicorn app.main:app --reload

# Start on different port
uvicorn app.main:app --reload --port 8001

# Run with specific log level
uvicorn app.main:app --reload --log-level debug
```

### Database

```bash
# Delete database (for fresh start)
rm openon.db

# Database will be automatically created on first run
```

### Testing

```bash
# Run all tests
pytest

# Run specific test
pytest tests/test_state_machine.py::test_valid_transitions

# Run with coverage report
pytest --cov=app --cov-report=html
```

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Find process using port 8000
lsof -i :8000

# Kill the process or use different port
uvicorn app.main:app --reload --port 8001
```

### Import Errors

```bash
# Make sure virtual environment is activated
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows

# Reinstall dependencies
pip install -r requirements.txt
```

### Database Errors

```bash
# Delete and recreate database
rm openon.db

# Restart server (database auto-creates)
uvicorn app.main:app --reload
```

### Module Not Found

```bash
# Make sure you're in the backend directory
cd backend

# Check Python path
python -c "import sys; print(sys.path)"

# Reinstall in development mode
pip install -e .
```

### Authentication Errors

- Check that `SECRET_KEY` is set in `.env`
- Verify token is included in `Authorization` header
- Ensure token hasn't expired (default: 30 minutes)

## 📚 Next Steps

1. **Explore the API**: Visit http://localhost:8000/docs
2. **Read Architecture**: See [ARCHITECTURE.md](./ARCHITECTURE.md)
3. **Understand Code**: See [CODE_STRUCTURE.md](./CODE_STRUCTURE.md)
4. **API Reference**: See [API_REFERENCE.md](./API_REFERENCE.md)
5. **Security Guide**: See [SECURITY.md](./SECURITY.md)

## 🎉 You're Ready!

Your OpenOn backend is now running! The background worker automatically checks for capsules to unlock every 60 seconds.

**Happy coding! 🚀**

---

**Last Updated**: 2025

