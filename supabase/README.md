# OpenOn Supabase Backend

Complete Supabase backend for OpenOn time-locked letters app.

## 🚀 Quick Start

### Prerequisites

1. **Docker Desktop** - [Install](https://www.docker.com/products/docker-desktop)
2. **Supabase CLI** - `brew install supabase/tap/supabase`

### Setup

```bash
cd supabase
supabase init      # First time only
supabase start     # Start local Supabase
```

**Access:**
- **Studio (Web UI)**: http://localhost:54323
- **API**: http://localhost:54321
- **Database**: postgresql://postgres:postgres@localhost:54322/postgres

### Get Credentials

```bash
supabase status
```

Save the `anon key` and `service_role key` for your Flutter app.

## 📁 Structure

```
supabase/
├── config.toml              # Supabase CLI configuration
├── migrations/              # Database migrations (ordered)
│   ├── 01_enums_and_tables.sql
│   ├── 02_indexes.sql
│   ├── 03_views.sql
│   ├── 04_functions.sql
│   ├── 05_triggers.sql
│   ├── 06_rls_policies.sql
│   ├── 07_storage.sql
│   └── 09_scheduled_jobs.sql
├── DATABASE_SCHEMA.md       # Complete database schema reference
└── LOCAL_SETUP.md           # Detailed setup guide
```
<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
grep

## 🔧 Common Commands

```bash
# Start Supabase
supabase start

# Stop Supabase
supabase stop

# Reset database (re-run all migrations)
supabase db reset

# Create new migration
supabase migration new migration_name

# Connect to database
supabase db connect

# View logs
supabase logs

# Check status
supabase status
```

## 📚 Documentation

- **[LOCAL_SETUP.md](./LOCAL_SETUP.md)** - Complete local development guide
- **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Complete database schema reference (tables, enums, relationships, functions, triggers, RLS)

## 🗄️ Database Schema

### Tables

- `user_profiles` - User profile data (extends auth.users)
- `recipients` - User contacts/recipients
- `capsules` - Time-locked letters
- `themes` - Visual themes for letters
- `animations` - Reveal animations
- `notifications` - User notifications
- `user_subscriptions` - Premium subscriptions
- `audit_logs` - Action logging

### Enums

- `capsule_status` - `sealed`, `ready`, `opened`, `expired`
- `notification_type` - Various notification types
- `subscription_status` - Subscription states
- `recipient_relationship` - `friend`, `family`, `partner`, etc.

## 🔐 Security

- Row-Level Security (RLS) enabled on all tables
- Policies ensure users can only access their own data
- Anonymous capsules hide sender information
- Service role functions for admin operations

## 🚀 Deployment

1. Create Supabase project: https://supabase.com
2. Link local project:
   ```bash
   supabase link --project-ref your-project-ref
   ```
3. Push migrations:
   ```bash
   supabase db push
   ```

## 📖 More Information

See [LOCAL_SETUP.md](./LOCAL_SETUP.md) for detailed setup instructions and troubleshooting.
