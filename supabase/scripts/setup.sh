#!/bin/bash

# ============================================================================
# Supabase Setup Script
# Ensures all database changes are applied for local development
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPABASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SUPABASE_DIR/.." && pwd)"

echo -e "${GREEN}🚀 OpenOn Supabase Setup${NC}"
echo "================================"
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI is not installed${NC}"
    echo "Install it with: npm install -g supabase"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI found${NC}"

# Navigate to supabase directory
cd "$SUPABASE_DIR"

# Check if Supabase is initialized
if [ ! -f "config.toml" ]; then
    echo -e "${YELLOW}⚠️  Supabase not initialized. Initializing...${NC}"
    supabase init
fi

# Start Supabase locally
echo -e "${GREEN}📦 Starting Supabase locally...${NC}"
supabase start

# Get connection string
DB_URL=$(supabase status --output json | grep -o '"DB_URL":"[^"]*' | cut -d'"' -f4)

if [ -z "$DB_URL" ]; then
    echo -e "${RED}❌ Could not get database URL${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Supabase started${NC}"
echo "Database URL: $DB_URL"
echo ""

# Apply migrations
echo -e "${GREEN}📝 Applying migrations...${NC}"
supabase db reset --db-url "$DB_URL" || {
    echo -e "${YELLOW}⚠️  Migration reset failed, trying to apply migrations directly...${NC}"
    
    # Apply migrations manually if reset fails
    for migration in migrations/*.sql; do
        if [ -f "$migration" ]; then
            echo "Applying: $(basename $migration)"
            psql "$DB_URL" -f "$migration" || {
                echo -e "${YELLOW}⚠️  Migration $(basename $migration) may have already been applied${NC}"
            }
        fi
    done
}

echo -e "${GREEN}✅ Migrations applied${NC}"
echo ""

# Verify setup
echo -e "${GREEN}🔍 Verifying setup...${NC}"

# Check if tables exist
TABLES=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('user_profiles', 'recipients', 'capsules', 'themes', 'animations', 'notifications', 'user_subscriptions', 'audit_logs');")

if [ "$TABLES" -eq 8 ]; then
    echo -e "${GREEN}✅ All tables created${NC}"
else
    echo -e "${RED}❌ Some tables are missing (found $TABLES/8)${NC}"
    exit 1
fi

# Check if functions exist
FUNCTIONS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname IN ('update_capsule_status', 'handle_capsule_opened', 'notify_capsule_unlocked', 'create_audit_log', 'update_updated_at', 'delete_expired_disappearing_messages', 'send_unlock_soon_notifications');")

if [ "$FUNCTIONS" -eq 7 ]; then
    echo -e "${GREEN}✅ All functions created${NC}"
else
    echo -e "${YELLOW}⚠️  Some functions may be missing (found $FUNCTIONS/7)${NC}"
fi

# Check if RLS is enabled
RLS_ENABLED=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('user_profiles', 'recipients', 'capsules') AND rowsecurity = true;")

if [ "$RLS_ENABLED" -ge 3 ]; then
    echo -e "${GREEN}✅ RLS enabled on tables${NC}"
else
    echo -e "${YELLOW}⚠️  RLS may not be fully enabled${NC}"
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Get your local credentials: supabase status"
echo "2. Access Supabase Studio: http://localhost:54323"
echo "3. Access Inbucket (email testing): http://localhost:54324"
echo ""

