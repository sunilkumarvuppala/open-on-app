# Supabase Configuration

This directory contains Supabase configuration files and migrations.

> **📚 For complete documentation, see [docs/supabase/README.md](../docs/supabase/README.md)**

## Quick Reference

```bash
# Start Supabase
cd supabase
supabase start

# Stop Supabase
supabase stop

# Reset database
supabase db reset

# Check status
supabase status
```

## Directory Structure

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
└── README.md               # This file (quick reference)
```

## Documentation

All Supabase documentation is in `docs/supabase/`:

- **[docs/supabase/README.md](../docs/supabase/README.md)** - Documentation overview
- **[docs/supabase/GETTING_STARTED.md](../docs/supabase/GETTING_STARTED.md)** - Quick start guide
- **[docs/supabase/LOCAL_SETUP.md](../docs/supabase/LOCAL_SETUP.md)** - Complete setup guide
- **[docs/supabase/DATABASE_SCHEMA.md](../docs/supabase/DATABASE_SCHEMA.md)** - Database schema reference

