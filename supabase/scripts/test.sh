#!/bin/bash

# ============================================================================
# Supabase Test Script
# Runs tests to verify database setup and functionality
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

echo -e "${BLUE}🧪 Supabase Test Script${NC}"
echo "=========================="
echo ""

cd "$SUPABASE_DIR"

# Get database URL
if ! supabase status &> /dev/null; then
    echo -e "${RED}❌ Supabase is not running${NC}"
    echo "Start it with: supabase start"
    exit 1
fi

DB_URL=$(supabase status --output json 2>/dev/null | grep -o '"DB_URL":"[^"]*' | cut -d'"' -f4 || echo "postgresql://postgres:postgres@127.0.0.1:54322/postgres")

echo -e "${GREEN}📡 Testing database: $DB_URL${NC}"
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_check() {
    local test_name="$1"
    local query="$2"
    local expected="$3"
    
    echo -n "  Testing: $test_name... "
    
    result=$(psql "$DB_URL" -t -c "$query" 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$result" = "$expected" ] || [ "$result" -ge "$expected" ] 2>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL (expected: $expected, got: $result)${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# ============================================================================
# TESTS
# ============================================================================

echo -e "${BLUE}📊 Running Tests${NC}"
echo ""

# Test 1: Tables exist
echo -e "${BLUE}1. Testing Tables${NC}"
test_check "All tables exist" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('user_profiles', 'recipients', 'capsules', 'themes', 'animations', 'notifications', 'user_subscriptions', 'audit_logs');" \
    "8"

# Test 2: Enums exist
echo -e "${BLUE}2. Testing Enums${NC}"
test_check "Capsule status enum exists" \
    "SELECT COUNT(*) FROM pg_type WHERE typname = 'capsule_status';" \
    "1"
test_check "Notification type enum exists" \
    "SELECT COUNT(*) FROM pg_type WHERE typname = 'notification_type';" \
    "1"
test_check "Subscription status enum exists" \
    "SELECT COUNT(*) FROM pg_type WHERE typname = 'subscription_status';" \
    "1"

# Test 3: Functions exist
echo -e "${BLUE}3. Testing Functions${NC}"
test_check "All functions exist" \
    "SELECT COUNT(*) FROM pg_proc WHERE proname IN ('update_capsule_status', 'handle_capsule_opened', 'notify_capsule_unlocked', 'create_audit_log', 'update_updated_at', 'delete_expired_disappearing_messages', 'send_unlock_soon_notifications');" \
    "7"

# Test 4: Views exist
echo -e "${BLUE}4. Testing Views${NC}"
test_check "All views exist" \
    "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public' AND table_name IN ('recipient_safe_capsules_view', 'inbox_view', 'outbox_view');" \
    "3"

# Test 5: RLS enabled
echo -e "${BLUE}5. Testing RLS${NC}"
test_check "RLS enabled on user_profiles" \
    "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_profiles' AND rowsecurity = true;" \
    "1"
test_check "RLS enabled on capsules" \
    "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'capsules' AND rowsecurity = true;" \
    "1"

# Test 6: Indexes exist
echo -e "${BLUE}6. Testing Indexes${NC}"
test_check "Key indexes exist" \
    "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public' AND indexname LIKE 'idx_%';" \
    "20"

# Test 7: Storage buckets
echo -e "${BLUE}7. Testing Storage${NC}"
test_check "Storage buckets exist" \
    "SELECT COUNT(*) FROM storage.buckets WHERE id IN ('avatars', 'capsule_assets', 'animations', 'themes');" \
    "4"

# Test 8: Seed data
echo -e "${BLUE}8. Testing Seed Data${NC}"
test_check "Themes seeded" \
    "SELECT COUNT(*) FROM public.themes;" \
    "6"
test_check "Animations seeded" \
    "SELECT COUNT(*) FROM public.animations;" \
    "5"

# Test 9: Triggers
echo -e "${BLUE}9. Testing Triggers${NC}"
test_check "Key triggers exist" \
    "SELECT COUNT(*) FROM pg_trigger WHERE tgname LIKE 'trigger_%';" \
    "8"

# Test 10: Scheduled jobs
echo -e "${BLUE}10. Testing Scheduled Jobs${NC}"
test_check "Scheduled jobs exist" \
    "SELECT COUNT(*) FROM cron.job WHERE jobname IN ('delete-expired-disappearing-messages', 'send-unlock-soon-notifications', 'update-premium-status');" \
    "3"

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "=========================="
echo -e "${BLUE}📊 Test Summary${NC}"
echo "=========================="
echo -e "${GREEN}✅ Passed: $TESTS_PASSED${NC}"
if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}❌ Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
fi

