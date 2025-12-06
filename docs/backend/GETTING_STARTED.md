# Backend Getting Started Guide

Get the OpenOn backend up and running in 5 minutes!

## 📋 Prerequisites

- **Python 3.11+** - Check with `python3 --version`
- **pip** or **Poetry** - Package manager
- **Supabase** (PostgreSQL) - Database (see [../supabase/LOCAL_SETUP.md](../supabase/LOCAL_SETUP.md))

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

# Database (Supabase PostgreSQL)
# Get connection string from: cd ../supabase && supabase status
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:54322/postgres

# Security (CHANGE THIS IN PRODUCTION!)
SECRET_KEY=your-super-secret-key-here-change-in-production
SUPABASE_JWT_SECRET=your-supabase-jwt-secret-here  # Get from Supabase Dashboard > Settings > API

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

**Note**: User signup and login are handled by Supabase Auth (frontend). This backend only provides profile management.

### 1. Get Current User Profile

After authenticating via Supabase Auth, use the JWT token to get your profile:

```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

**Response:**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "full_name": "Test User",
  "avatar_url": null,
  "premium_status": false,
  "is_admin": false,
  ...
}
```

### 2. Create a Recipient

```bash
curl -X POST "http://localhost:8000/recipients" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "relationship": "friend"
  }'
```

### 3. Create a Capsule

```bash
curl -X POST "http://localhost:8000/capsules" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "recipient_id": "RECIPIENT_ID",
    "title": "My First Capsule",
    "body_text": "This is a time capsule!",
    "unlocks_at": "2026-01-01T00:00:00Z"
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
# Reset Supabase database (for fresh start)
cd ../supabase
supabase db reset

# This will re-run all migrations and start fresh
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

### Connection Refused Error

**Symptom:** Frontend shows "Connection refused" error

**Solutions:**

1. **Check if backend is running:**
   ```bash
   # Check if port 8000 is in use
   lsof -i :8000
   # OR
   netstat -an | grep 8000
   ```

2. **Start the backend server** (see Step 4 above)

3. **Check API URL in frontend:**
   - iOS Simulator / Desktop: `http://localhost:8000`
   - Android Emulator: `http://10.0.2.2:8000` (automatically detected)
   - Physical Device: Use your computer's IP address
     ```bash
     # Find your IP address
     ifconfig | grep "inet " | grep -v 127.0.0.1
     # Then use: http://YOUR_IP:8000
     ```

4. **Check firewall settings:**
   - Ensure port 8000 is not blocked
   - On macOS: System Settings > Network > Firewall

### Port Already in Use

**Error:** `Address already in use`

**Solution:**
```bash
# Find and kill the process using port 8000
lsof -ti:8000 | xargs kill -9

# OR use a different port
python -m uvicorn app.main:app --reload --port 8001
# Then update frontend API config to use port 8001
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
# Check if Supabase is running
cd ../supabase
supabase status

# If not running, start it
supabase start

# Reset database if needed
supabase db reset

# Restart server
cd ../backend
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

- Check that `SUPABASE_JWT_SECRET` is set in `.env` (get from Supabase Dashboard or `supabase status`)
- Verify Supabase JWT token is included in `Authorization` header
- Ensure token is valid (Supabase handles token refresh automatically)
- Verify `SUPABASE_SERVICE_KEY` is set for signup/login endpoints

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

**Last Updated**: 2025-01-XX (Post Supabase Migration)

