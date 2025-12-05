# Supabase Production Setup Guide

Complete production-ready Supabase setup for OpenOn with local development, testing, and migration management.

## 📋 Overview

This setup provides:
- ✅ Complete database schema with migrations
- ✅ Row-level security (RLS) policies
- ✅ Automated triggers and functions
- ✅ Storage bucket configuration
- ✅ Local development environment
- ✅ Testing scripts
- ✅ Migration management
- ✅ Verification scripts

## 🚀 Quick Start

### 1. Install Prerequisites

```bash
# Install Supabase CLI
npm install -g supabase

# Install PostgreSQL client (optional)
# macOS: brew install postgresql
# Linux: sudo apt-get install postgresql-client
```

### 2. Initial Setup

```bash
cd supabase
./scripts/setup.sh
```

This will:
- Initialize Supabase project
- Start local Supabase instance
- Apply all migrations
- Verify setup

### 3. Verify Installation

```bash
./scripts/verify.sh
```

## 📁 Structure

```
supabase/
├── config.toml                    # Supabase CLI configuration
├── migrations/                     # Database migrations (ordered)
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
│   ├── setup.sh                   # Initial setup
│   ├── migrate.sh                 # Apply migrations
│   ├── test.sh                    # Run tests
│   ├── verify.sh                  # Verify database state
│   └── reset.sh                   # Reset database
├── README_LOCAL_DEV.md            # Local development guide
└── PRODUCTION_SETUP.md            # This file
```

## 🔧 Available Scripts

### Setup Script (`setup.sh`)
Initial setup and verification.

```bash
./scripts/setup.sh
```

### Migration Script (`migrate.sh`)
Applies all pending migrations and verifies state.

```bash
./scripts/migrate.sh
```

### Test Script (`test.sh`)
Runs comprehensive tests to verify database setup.

```bash
./scripts/test.sh
```

### Verify Script (`verify.sh`)
Comprehensive verification that all changes are applied.

```bash
./scripts/verify.sh
```

### Reset Script (`reset.sh`)
Resets local database and reapplies all migrations.

```bash
./scripts/reset.sh
```

## 🗄️ Database Schema

### Tables
- `user_profiles` - User profile information
- `recipients` - User's contact list
- `capsules` - Time-locked letters
- `themes` - Letter themes
- `animations` - Opening animations
- `notifications` - User notifications
- `user_subscriptions` - Premium subscriptions
- `audit_logs` - Audit trail

### Enums
- `capsule_status` - sealed, ready, opened, expired
- `notification_type` - Various notification types
- `subscription_status` - Subscription states

### Views
- `recipient_safe_capsules_view` - Safe view for recipients (hides anonymous senders)
- `inbox_view` - User's inbox
- `outbox_view` - User's outbox

### Functions
- `update_capsule_status()` - Updates capsule status based on time
- `handle_capsule_opened()` - Handles capsule opening logic
- `notify_capsule_unlocked()` - Sends unlock notifications
- `create_audit_log()` - Creates audit log entries
- `update_updated_at()` - Updates timestamp
- `delete_expired_disappearing_messages()` - Deletes expired messages
- `send_unlock_soon_notifications()` - Sends unlock soon notifications

### Triggers
- Status updates on capsule changes
- Automatic notifications
- Audit logging
- Timestamp updates

### Storage Buckets
- `avatars` - User avatars (public)
- `capsule_assets` - Capsule attachments (private)
- `animations` - Animation assets (public)
- `themes` - Theme assets (public)

## 🔒 Security

### Row-Level Security (RLS)
All tables have RLS enabled with policies for:
- Users can only access their own data
- Recipients can view received capsules
- Senders can view sent capsules
- Anonymous capsules hide sender information
- Admins can manage themes and animations

### Storage Policies
- Users can upload/manage own avatars
- Users can upload capsule assets for own capsules
- Recipients can view assets of received capsules
- Public access to themes and animations

## 🧪 Testing

### Automated Tests
Run comprehensive tests:
```bash
./scripts/test.sh
```

Tests verify:
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

### Manual Testing
Access Supabase Studio: http://localhost:54323

## 🔄 Migration Workflow

### Creating New Migrations

1. **Create migration**
   ```bash
   supabase migration new your_feature_name
   ```

2. **Edit migration file** in `migrations/` directory

3. **Test locally**
   ```bash
   ./scripts/migrate.sh
   ./scripts/test.sh
   ```

4. **Commit to version control**

5. **Apply to production** via Supabase Dashboard

### Ensuring All Changes Are Applied

Run the verification script:
```bash
./scripts/verify.sh
```

This checks:
- All migrations are applied
- All tables, functions, views exist
- RLS is properly configured
- Storage buckets are set up
- Seed data is loaded

## 🌐 Local Services

After starting Supabase:
- **API**: http://localhost:54321
- **Studio**: http://localhost:54323
- **Inbucket** (Email): http://localhost:54324
- **Database**: localhost:54322

## 📚 Documentation

- [Local Development Guide](./README_LOCAL_DEV.md) - Detailed local dev setup
- [API Specification](./API_SPECIFICATION.md) - Complete API docs
- [Backend Structure](./BACKEND_STRUCTURE.md) - Folder structure guide
- [Implementation Summary](./IMPLEMENTATION_SUMMARY.md) - Quick reference

## ✅ Production Checklist

Before deploying to production:

- [ ] All migrations tested locally
- [ ] All tests passing (`./scripts/test.sh`)
- [ ] Verification script passes (`./scripts/verify.sh`)
- [ ] RLS policies reviewed
- [ ] Storage policies reviewed
- [ ] Scheduled jobs configured
- [ ] Seed data reviewed
- [ ] Backup strategy in place
- [ ] Monitoring configured

## 🐛 Troubleshooting

See [README_LOCAL_DEV.md](./README_LOCAL_DEV.md) for detailed troubleshooting.

Common issues:
- **Supabase won't start**: Run `supabase stop && supabase start`
- **Migrations fail**: Run `./scripts/reset.sh`
- **Connection issues**: Check `supabase status`

## 📝 Notes

- All migrations are idempotent (safe to run multiple times)
- Migrations use `IF NOT EXISTS` and `ON CONFLICT` for safety
- Scripts include error handling and verification
- Database state is verified after each migration

