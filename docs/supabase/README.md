# Supabase Documentation

> **Supabase/database documentation overview.**  
> For documentation overview, see [../README.md](../README.md).  
> For master navigation, see [../INDEX.md](../INDEX.md).

Complete Supabase backend documentation for OpenOn time-locked letters app.

## 📚 Documentation Structure

```
docs/supabase/
├── README.md (this file)          # Overview and navigation
├── GETTING_STARTED.md              # Quick start guide
├── LOCAL_SETUP.md                  # Complete local development setup
└── DATABASE_SCHEMA.md              # Complete database schema reference
```

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

## 📖 Documentation Guide

### For New Developers
1. **[GETTING_STARTED.md](./GETTING_STARTED.md)** - Quick start and setup
2. **[LOCAL_SETUP.md](./LOCAL_SETUP.md)** - Complete local development guide
3. **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Database schema reference

### For Database Developers
1. **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Complete schema documentation
2. **[LOCAL_SETUP.md](./LOCAL_SETUP.md)** - Development environment setup

### For Backend Integration
1. **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Understand data models
2. **[GETTING_STARTED.md](./GETTING_STARTED.md)** - Connection strings and credentials

## 🔧 Common Commands

```bash
# Start Supabase
cd supabase
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

## 📁 Project Structure

```
supabase/                          # Root Supabase directory (config files)
├── config.toml                   # Supabase CLI configuration
├── migrations/                 # Database migrations (ordered)
│   ├── 01_enums_and_tables.sql
│   ├── 02_indexes.sql
│   ├── 03_views.sql
│   ├── 04_functions.sql
│   ├── 05_triggers.sql
│   ├── 06_rls_policies.sql
│   ├── 07_storage.sql
│   └── 09_scheduled_jobs.sql
└── README.md                    # Quick reference (points to docs/)

docs/supabase/                    # Documentation directory
├── README.md (this file)         # Documentation overview
├── GETTING_STARTED.md            # Quick start guide
├── LOCAL_SETUP.md                # Complete setup guide
└── DATABASE_SCHEMA.md            # Schema reference
```

## 🗄️ Database Schema Overview

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

- **[GETTING_STARTED.md](./GETTING_STARTED.md)** - Quick start guide
- **[LOCAL_SETUP.md](./LOCAL_SETUP.md)** - Detailed setup instructions and troubleshooting
- **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** - Complete database schema reference

---

**Note**: The actual Supabase configuration files (migrations, config.toml) are in the root `supabase/` directory. This `docs/supabase/` directory contains all documentation.

**Last Updated**: January 2025

