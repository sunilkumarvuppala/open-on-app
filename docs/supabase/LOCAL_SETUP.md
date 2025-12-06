# 🚀 Supabase Local Development Setup

Simple guide to set up and run Supabase locally for OpenOn.

## 📋 Prerequisites

### 1. Install Docker Desktop

**macOS:**
```bash
brew install --cask docker
```

**Verify:**
```bash
docker --version
```

**Start Docker Desktop** (wait for it to fully start)

### 2. Install Supabase CLI

**macOS (Recommended):**
```bash
brew install supabase/tap/supabase
```

**Verify:**
```bash
supabase --version
```

---

## 🛠️ Setup Steps

### Step 1: Initialize Supabase (if not already done)

```bash
cd supabase
supabase init
```

This creates the basic Supabase structure.

### Step 2: Start Local Supabase

```bash
supabase start
```

**What this does:**
- Downloads and starts Docker containers
- PostgreSQL database (port 54322)
- Supabase Studio (web UI on port 54323)
- Auth service (port 54321)
- Storage service
- Email testing (Inbucket on port 54324)

**First time:** Takes 2-5 minutes to download images (~500MB)

**Expected output:**
```
Started supabase local development setup.

         API URL: http://localhost:54321
     GraphQL URL: http://localhost:54321/graphql/v1
          DB URL: postgresql://postgres:postgres@localhost:54322/postgres
      Studio URL: http://localhost:54323
    Inbucket URL: http://localhost:54324
      JWT secret: super-secret-jwt-token-with-at-least-32-characters-long
        anon key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Save these credentials!** You'll need them for your Flutter app.

### Step 3: Migrations

Migrations are automatically applied when you start Supabase (they're in the `migrations/` folder).

**To manually reset and re-run all migrations:**
```bash
supabase db reset
```

**To check migration status:**
```bash
supabase migration list
```

### Step 4: Access Supabase Studio

Open in browser: **http://localhost:54323**

**What you can do:**
- View all tables
- Run SQL queries
- Test RLS policies
- View data
- Check indexes and constraints

**Login:** No login needed for local development

---

## 🔧 Useful Commands

### Start/Stop Supabase

```bash
# Start Supabase
supabase start

# Stop Supabase (keeps data)
supabase stop

# Stop and remove all data
supabase stop --no-backup

# Check status
supabase status
```

### Database Operations

```bash
# Connect to database
supabase db connect

# Reset database (runs all migrations)
supabase db reset

# Create new migration (with helper script)
./new_migration.sh migration_name

# Or use Supabase CLI directly (creates timestamped file)
supabase migration new migration_name

# List migrations
supabase migration list
```

### View Logs

```bash
# View all logs
supabase logs

# View specific service logs
supabase logs db
supabase logs api
supabase logs auth
```

### Access Services

- **Supabase Studio**: http://localhost:54323
- **API**: http://localhost:54321
- **Database**: localhost:54322
- **Email Testing (Inbucket)**: http://localhost:54324

---

## 📝 Environment Variables for Flutter

Create `.env` file in your Flutter project root:

```env
# Local Supabase (for development)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<your-anon-key-from-supabase-start>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key-from-supabase-start>

# For Android emulator, use 10.0.2.2 instead of localhost
# SUPABASE_URL=http://10.0.2.2:54321
```

**Get keys from:**
```bash
supabase status
```

---

## 🐛 Troubleshooting

### Issue: Docker not running
**Error**: `Cannot connect to Docker daemon`

**Solution**: 
- Open Docker Desktop
- Wait for it to fully start
- Try `supabase start` again

### Issue: Port already in use
**Error**: `Port 54321 is already in use`

**Solution**:
```bash
# Find what's using the port
lsof -i :54321

# Kill the process or change port in config.toml
```

### Issue: Migrations not running
**Error**: Tables don't exist after `supabase start`

**Solution**:
```bash
# Manually reset database
supabase db reset

# Or check migration files are in correct location
ls supabase/migrations/
```

### Issue: Can't connect from Flutter app
**Error**: Connection refused

**Solution**:
- **iOS Simulator**: Use `localhost:54321` ✅
- **Android Emulator**: Use `10.0.2.2:54321` (not localhost)
- **Physical Device**: Use your computer's IP address (e.g., `192.168.1.100:54321`)

---

## 🎯 Next Steps After Local Testing

Once you've tested everything locally:

1. **Create Supabase account**: https://supabase.com
2. **Create new project** in Supabase dashboard
3. **Link local to remote** (optional):
   ```bash
   supabase link --project-ref your-project-ref
   ```
4. **Push migrations to production**:
   ```bash
   supabase db push
   ```

---

## ✅ Benefits of Local Development

1. **Free**: No cloud costs during development
2. **Fast**: No network latency
3. **Offline**: Works without internet
4. **Safe**: Can't break production
5. **Fast iteration**: Reset database instantly
6. **Privacy**: Data never leaves your machine

---

**Ready to start?** Run `supabase start` in the `supabase` directory!

