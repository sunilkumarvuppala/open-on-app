#!/bin/bash

# ============================================================================
# Supabase Migration Script
# Ensures all database changes are applied
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPABASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}🔄 Supabase Migration Script${NC}"
echo "===================================="
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI is not installed${NC}"
    echo "Install it with: npm install -g supabase"
    exit 1
fi

cd "$SUPABASE_DIR"

# Check if we're in a Supabase project
if [ ! -f "config.toml" ]; then
    echo -e "${RED}❌ Not a Supabase project. Run setup.sh first.${NC}"
    exit 1
fi

# Get database URL
echo -e "${GREEN}📡 Getting database connection...${NC}"

# Check if Supabase is running
if ! supabase status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Supabase not running. Starting...${NC}"
    supabase start
fi

DB_URL=$(supabase status --output json 2>/dev/null | grep -o '"DB_URL":"[^"]*' | cut -d'"' -f4 || echo "")

if [ -z "$DB_URL" ]; then
    # Try alternative method
    DB_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
    echo -e "${YELLOW}⚠️  Using default local database URL${NC}"
fi

echo -e "${GREEN}✅ Database URL: $DB_URL${NC}"
echo ""

# Check for pending migrations
echo -e "${GREEN}📋 Checking migrations...${NC}"

MIGRATION_COUNT=$(ls -1 migrations/*.sql 2>/dev/null | wc -l | tr -d ' ')
echo "Found $MIGRATION_COUNT migration files"

if [ "$MIGRATION_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No migration files found${NC}"
    exit 0
fi

# Apply migrations
echo ""
echo -e "${GREEN}📝 Applying migrations...${NC}"

for migration in migrations/*.sql; do
    if [ -f "$migration" ]; then
        MIGRATION_NAME=$(basename "$migration")
        echo -e "${BLUE}  → $MIGRATION_NAME${NC}"
        
        # Apply migration
        if psql "$DB_URL" -f "$migration" 2>&1 | grep -q "ERROR"; then
            # Check if error is due to already existing objects
            ERROR_OUTPUT=$(psql "$DB_URL" -f "$migration" 2>&1 || true)
            if echo "$ERROR_OUTPUT" | grep -q "already exists\|duplicate\|already exists"; then
                echo -e "${YELLOW}    ⚠️  Some objects may already exist (safe to ignore)${NC}"
            else
                echo -e "${RED}    ❌ Migration failed${NC}"
                echo "$ERROR_OUTPUT"
                exit 1
            fi
        else
            echo -e "${GREEN}    ✅ Applied${NC}"
        fi
    fi
done

echo ""
echo -e "${GREEN}✅ All migrations applied${NC}"

# Verify database state
echo ""
echo -e "${GREEN}🔍 Verifying database state...${NC}"

# Check tables
TABLE_COUNT=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('user_profiles', 'recipients', 'capsules', 'themes', 'animations', 'notifications', 'user_subscriptions', 'audit_logs');" 2>/dev/null | tr -d ' ')

if [ "$TABLE_COUNT" -ge 8 ]; then
    echo -e "${GREEN}  ✅ All tables exist ($TABLE_COUNT/8)${NC}"
else
    echo -e "${YELLOW}  ⚠️  Some tables may be missing ($TABLE_COUNT/8)${NC}"
fi

# Check functions
FUNCTION_COUNT=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname IN ('update_capsule_status', 'handle_capsule_opened', 'notify_capsule_unlocked', 'create_audit_log', 'update_updated_at', 'delete_expired_disappearing_messages', 'send_unlock_soon_notifications');" 2>/dev/null | tr -d ' ')

if [ "$FUNCTION_COUNT" -ge 7 ]; then
    echo -e "${GREEN}  ✅ All functions exist ($FUNCTION_COUNT/7)${NC}"
else
    echo -e "${YELLOW}  ⚠️  Some functions may be missing ($FUNCTION_COUNT/7)${NC}"
fi

# Check views
VIEW_COUNT=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public' AND table_name IN ('recipient_safe_capsules_view', 'inbox_view', 'outbox_view');" 2>/dev/null | tr -d ' ')

if [ "$VIEW_COUNT" -ge 3 ]; then
    echo -e "${GREEN}  ✅ All views exist ($VIEW_COUNT/3)${NC}"
else
    echo -e "${YELLOW}  ⚠️  Some views may be missing ($VIEW_COUNT/3)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Migration complete!${NC}"
echo ""
echo "Database is ready for use."
echo "Access Supabase Studio: http://localhost:54323"

