# Supabase Local Development Guide

Complete guide for local Supabase development setup.

## 🚀 Quick Start

### Prerequisites

1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Install PostgreSQL Client** (optional, for direct DB access)
   ```bash
   # macOS
   brew install postgresql
   
   # Linux
   sudo apt-get install postgresql-client
   ```

### Initial Setup

1. **Run Setup Script**
   ```bash
   cd supabase
   ./scripts/setup.sh
   ```

   This will:
   - Initialize Supabase project (if needed)
   - Start local Supabase instance
   - Apply all migrations
   - Verify setup

2. **Get Connection Details**
   ```bash
   supabase status
   ```

### Daily Development

1. **Start Supabase** (if not running)
   ```bash
   supabase start
   ```

2. **Apply New Migrations**
   ```bash
   ./scripts/migrate.sh
   ```

3. **Run Tests**
   ```bash
   ./scripts/test.sh
   ```

4. **Reset Database** (if needed)
   ```bash
   ./scripts/reset.sh
   ```

## 📁 Project Structure

```
supabase/
├── config.toml              # Supabase CLI configuration
├── migrations/              # Database migrations (ordered by timestamp)
│   ├── 20250101000000_initial_schema.sql
│   ├── 20250101000001_indexes.sql
│   ├── 20250101000002_views.sql
│   ├── 20250101000003_functions.sql
│   ├── 20250101000004_triggers.sql
│   ├── 20250101000005_rls_policies.sql
│   ├── 20250101000006_storage.sql
│   ├── 20250101000007_seed_data.sql
│   └── 20250101000008_scheduled_jobs.sql
├── scripts/
│   ├── setup.sh            # Initial setup script
│   ├── migrate.sh          # Apply migrations
│   ├── test.sh             # Run tests
│   └── reset.sh            # Reset database
└── .gitignore              # Git ignore rules
```

## 🔧 Available Scripts

### `setup.sh`
Initial setup script that:
- Checks for Supabase CLI
- Initializes project (if needed)
- Starts Supabase locally
- Applies all migrations
- Verifies setup

**Usage:**
```bash
./scripts/setup.sh
```

### `migrate.sh`
Migration script that:
- Checks Supabase status
- Applies all pending migrations
- Verifies database state
- Reports any issues

**Usage:**
```bash
./scripts/migrate.sh
```

### `test.sh`
Test script that verifies:
- All tables exist
- All enums exist
- All functions exist
- All views exist
- RLS is enabled
- Indexes exist
- Storage buckets exist
- Seed data is loaded
- Triggers exist
- Scheduled jobs exist

**Usage:**
```bash
./scripts/test.sh
```

### `reset.sh`
Reset script that:
- Confirms with user
- Resets local database
- Reapplies all migrations

**Usage:**
```bash
./scripts/reset.sh
```

## 🗄️ Database Access

### Connection Details

After starting Supabase, get connection details:
```bash
supabase status
```

Default local connection:
```
Host: 127.0.0.1
Port: 54322
Database: postgres
User: postgres
Password: postgres
```

### Direct Database Access

```bash
# Using psql
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres

# Using Supabase CLI
supabase db psql
```

## 🌐 Local Services

After starting Supabase, these services are available:

- **API**: http://localhost:54321
- **Studio**: http://localhost:54323
- **Inbucket** (Email): http://localhost:54324
- **Database**: localhost:54322

## 📝 Creating New Migrations

1. **Create migration file**
   ```bash
   supabase migration new your_migration_name
   ```

2. **Edit the migration file** in `migrations/` directory

3. **Apply migration**
   ```bash
   ./scripts/migrate.sh
   ```

4. **Test migration**
   ```bash
   ./scripts/test.sh
   ```

## 🧪 Testing

### Manual Testing

1. **Access Supabase Studio**
   - URL: http://localhost:54323
   - Explore tables, run queries, test RLS

2. **Test RLS Policies**
   ```sql
   -- Test as authenticated user
   SET ROLE authenticated;
   SET request.jwt.claim.sub = 'user-uuid-here';
   
   -- Try to access data
   SELECT * FROM public.capsules;
   ```

3. **Test Functions**
   ```sql
   SELECT public.update_capsule_status();
   SELECT public.delete_expired_disappearing_messages();
   ```

### Automated Testing

Run the test script:
```bash
./scripts/test.sh
```

## 🔄 Migration Workflow

1. **Create migration**
   ```bash
   supabase migration new add_new_feature
   ```

2. **Write SQL** in the migration file

3. **Test locally**
   ```bash
   ./scripts/migrate.sh
   ./scripts/test.sh
   ```

4. **Commit migration** to version control

5. **Apply to production** (via Supabase Dashboard or CLI)

## 🐛 Troubleshooting

### Supabase won't start

```bash
# Stop and restart
supabase stop
supabase start
```

### Migrations fail

```bash
# Reset database
./scripts/reset.sh
```

### Connection issues

```bash
# Check status
supabase status

# Verify database is running
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -c "SELECT 1;"
```

### RLS policy errors

Check policies in Supabase Studio:
- Go to Authentication > Policies
- Verify policies are enabled
- Check policy conditions

## 📚 Additional Resources

- [Supabase CLI Docs](https://supabase.com/docs/reference/cli)
- [Local Development](https://supabase.com/docs/guides/cli/local-development)
- [Database Migrations](https://supabase.com/docs/guides/cli/local-development#database-migrations)

