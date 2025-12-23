# OpenOn Development Setup Guide

Complete guide for setting up both Backend (Python/FastAPI) and Supabase for local development.

## 📋 Overview

You have **two separate backends** that work independently:

1. **Python Backend** (`backend/`) - FastAPI REST API
2. **Supabase Backend** (`supabase/`) - PostgreSQL database with RLS, triggers, and functions

## 🐍 Python Backend Setup

### Requirements
- Python 3.11+
- pip

### Setup Steps

1. **Create and activate virtual environment** (ONE venv for backend)
   ```bash
   cd backend
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the backend**
   ```bash
   uvicorn app.main:app --reload
   ```

### Virtual Environment
- **Location**: `backend/venv/`
- **Purpose**: Isolates Python dependencies for the FastAPI backend
- **Contains**: FastAPI, SQLAlchemy, Pydantic, and all Python packages

---

## 🗄️ Supabase Setup

### Requirements
- Node.js and npm (for Supabase CLI)
- Docker (Supabase runs in Docker containers)

### Setup Steps

1. **Install Supabase CLI** (NOT in Python venv)
   
   **macOS (Recommended):**
   ```bash
   brew install supabase/tap/supabase
   ```
   
   **Verify:**
   ```bash
   supabase --version
   ```

2. **Install PostgreSQL client** (optional, for direct DB access)
   ```bash
   # macOS
   brew install postgresql
   
   # Linux
   sudo apt-get install postgresql-client
   ```

3. **Initialize and start Supabase**
   ```bash
   cd supabase
   supabase init      # First time only
   supabase start     # Start local Supabase
   ```
   
   This will:
   - Start local Supabase instance (Docker containers)
   - Automatically apply all migrations
   - Start Supabase Studio (web UI) at http://localhost:54323
   
   **Get credentials:**
   ```bash
   supabase status
   ```
   
   Save the `anon key` and `service_role key` for your Flutter app.

### Virtual Environment
- **NOT NEEDED**: Supabase doesn't use Python
- **CLI Tool**: Installed globally via npm (`npm install -g supabase`)
- **Runtime**: Runs in Docker containers (managed by Supabase CLI)

---

## ✅ Summary: Do You Need 2 venvs?

### Answer: **NO, you only need 1 Python venv**

| Component | Language | Virtual Environment | Installation |
|-----------|----------|---------------------|--------------|
| **Backend** | Python | ✅ **YES** - `backend/venv/` | `pip install -r requirements.txt` |
| **Supabase** | Node.js/SQL | ❌ **NO** - Uses npm/Docker | `npm install -g supabase` |

### Why Only One venv?

1. **Backend (Python)**: 
   - Uses Python packages (FastAPI, SQLAlchemy, etc.)
   - Needs Python venv to isolate dependencies
   - Located in `backend/venv/`

2. **Supabase**:
   - CLI is a Node.js tool (installed via npm)
   - Runs in Docker containers (no Python needed)
   - Database is PostgreSQL (no Python needed)
   - No Python code, so no Python venv needed

---

## 🚀 Quick Start (Both Backends)

### Terminal 1: Start Supabase
```bash
cd supabase
supabase init      # First time only
supabase start     # Start local Supabase
```

### Terminal 2: Start Python Backend
```bash
cd backend
source venv/bin/activate  # Activate Python venv
uvicorn app.main:app --reload
```

### Terminal 3: Start Flutter Frontend
```bash
cd frontend
flutter run
```

---

## 📝 Important Notes

1. **Python venv is ONLY for backend**: 
   - Activate it when working with Python backend
   - Not needed for Supabase operations

2. **Supabase CLI is global**:
   - Installed once via npm
   - Works from any directory
   - No venv needed

3. **Docker is required for Supabase**:
   - Supabase runs in Docker containers
   - Make sure Docker is running before `supabase start`

4. **Both can run simultaneously**:
   - Supabase: Database on port 54322
   - Python Backend: API on port 8000
   - They can work together or independently

---

## 🔧 Troubleshooting

### Python Backend Issues
```bash
# If dependencies are missing
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

### Supabase Issues
```bash
# If Supabase CLI not found (macOS)
brew install supabase/tap/supabase

# If Docker not running
# Start Docker Desktop, then:
cd supabase
supabase start
```

---

## 📚 Additional Resources

- **Backend**: See `backend/README.md`
- **Supabase**: See `docs/supabase/LOCAL_SETUP.md`
- **Frontend**: See `docs/frontend/GETTING_STARTED.md`

