# Starting the Backend Server

## Quick Start

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Activate virtual environment (if using one):**
   ```bash
   # If using venv
   source venv/bin/activate
   
   # OR if using .venv
   source .venv/bin/activate
   
   # OR if using Poetry
   poetry shell
   ```

3. **Install dependencies (if not already installed):**
   ```bash
   pip install -r requirements.txt
   # OR with Poetry
   poetry install
   ```

4. **Create .env file (if not exists):**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

5. **Start the server:**
   ```bash
   # Development mode (with auto-reload)
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   
   # OR using the run script
   ./run.sh
   ```

6. **Verify it's running:**
   - Open browser: http://localhost:8000/docs
   - You should see the FastAPI interactive documentation

## Common Issues

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

2. **Start the backend server** (see Quick Start above)

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

### Database Errors

**Error:** Database locked or connection errors

**Solution:**
```bash
# Stop all running instances
pkill -f uvicorn

# Remove SQLite lock files (if using SQLite)
rm -f openon.db-wal openon.db-shm

# Restart server
python -m uvicorn app.main:app --reload
```

## Production Mode

For production, use multiple workers:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## Testing the API

Once the server is running, test it:

```bash
# Health check
curl http://localhost:8000/health

# Sign up (example)
curl -X POST http://localhost:8000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "TestPass123",
    "full_name": "Test User"
  }'
```

## Environment Variables

Make sure your `.env` file has:

```env
DEBUG=true
DATABASE_URL=sqlite+aiosqlite:///./openon.db
SECRET_KEY=your-secret-key-here
CORS_ORIGINS=["http://localhost:3000","http://localhost:8000"]
```

## Troubleshooting Checklist

- [ ] Backend server is running (`uvicorn` process is active)
- [ ] Port 8000 is accessible
- [ ] `.env` file exists and is configured
- [ ] Dependencies are installed (`pip install -r requirements.txt`)
- [ ] Database is initialized (first run creates it automatically)
- [ ] Frontend API URL matches backend address
- [ ] No firewall blocking port 8000
- [ ] CORS settings allow frontend origin

