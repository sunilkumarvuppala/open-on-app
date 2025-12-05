#!/bin/bash

# ============================================================================
# Supabase Verification Script
# Comprehensive verification that all database changes are applied
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

echo -e "${BLUE}🔍 Supabase Database Verification${NC}"
echo "======================================"
echo ""

cd "$SUPABASE_DIR"

# Check if Supabase is running
if ! supabase status &> /dev/null; then
    echo -e "${RED}❌ Supabase is not running${NC}"
    echo "Start it with: supabase start"
    exit 1
fi

DB_URL=$(supabase status --output json 2>/dev/null | grep -o '"DB_URL":"[^"]*' | cut -d'"' -f4 || echo "postgresql://postgres:postgres@127.0.0.1:54322/postgres")

echo -e "${GREEN}📡 Database: $DB_URL${NC}"
echo ""

# Verification counter
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Check function
verify_check() {
    local check_name="$1"
    local query="$2"
    local expected="$3"
    local is_warning="${4:-false}"
    
    echo -n "  ✓ $check_name... "
    
    result=$(psql "$DB_URL" -t -c "$query" 2>/dev/null | tr -d ' ' || echo "0")
    
    if [ "$result" = "$expected" ] || [ "$result" -ge "$expected" ] 2>/dev/null; then
        echo -e "${GREEN}✅${NC}"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        if [ "$is_warning" = "true" ]; then
            echo -e "${YELLOW}⚠️  (expected: $expected, got: $result)${NC}"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${RED}❌ (expected: $expected, got: $result)${NC}"
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
        fi
        return 1
    fi
}

# ============================================================================
# VERIFICATION CHECKS
# ============================================================================

echo -e "${BLUE}📊 Verifying Database Schema${NC}"
echo ""

# 1. Tables
echo -e "${BLUE}1. Tables${NC}"
verify_check "user_profiles table" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles';" \
    "1"
verify_check "recipients table" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipients';" \
    "1"
verify_check "capsules table" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'capsules';" \
    "1"
verify_check "themes table" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'themes';" \
    "1"
verify_check "animations table" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'animations';" \
    "1"
verify_check "notifications table" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications';" \
    "1"
verify_check "user_subscriptions table" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_subscriptions';" \
    "1"
verify_check "audit_logs table" \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'audit_logs';" \
    "1"

# 2. Enums
echo ""
echo -e "${BLUE}2. Enums${NC}"
verify_check "capsule_status enum" \
    "SELECT COUNT(*) FROM pg_type WHERE typname = 'capsule_status';" \
    "1"
verify_check "notification_type enum" \
    "SELECT COUNT(*) FROM pg_type WHERE typname = 'notification_type';" \
    "1"
verify_check "subscription_status enum" \
    "SELECT COUNT(*) FROM pg_type WHERE typname = 'subscription_status';" \
    "1"

# 3. Functions
echo ""
echo -e "${BLUE}3. Functions${NC}"
verify_check "update_capsule_status function" \
    "SELECT COUNT(*) FROM pg_proc WHERE proname = 'update_capsule_status';" \
    "1"
verify_check "handle_capsule_opened function" \
    "SELECT COUNT(*) FROM pg_proc WHERE proname = 'handle_capsule_opened';" \
    "1"
verify_check "notify_capsule_unlocked function" \
    "SELECT COUNT(*) FROM pg_proc WHERE proname = 'notify_capsule_unlocked';" \
    "1"
verify_check "create_audit_log function" \
    "SELECT COUNT(*) FROM pg_proc WHERE proname = 'create_audit_log';" \
    "1"
verify_check "update_updated_at function" \
    "SELECT COUNT(*) FROM pg_proc WHERE proname = 'update_updated_at';" \
    "1"
verify_check "delete_expired_disappearing_messages function" \
    "SELECT COUNT(*) FROM pg_proc WHERE proname = 'delete_expired_disappearing_messages';" \
    "1"
verify_check "send_unlock_soon_notifications function" \
    "SELECT COUNT(*) FROM pg_proc WHERE proname = 'send_unlock_soon_notifications';" \
    "1"

# 4. Views
echo ""
echo -e "${BLUE}4. Views${NC}"
verify_check "recipient_safe_capsules_view" \
    "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public' AND table_name = 'recipient_safe_capsules_view';" \
    "1"
verify_check "inbox_view" \
    "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public' AND table_name = 'inbox_view';" \
    "1"
verify_check "outbox_view" \
    "SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public' AND table_name = 'outbox_view';" \
    "1"

# 5. Triggers
echo ""
echo -e "${BLUE}5. Triggers${NC}"
verify_check "Capsule status trigger" \
    "SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'trigger_update_capsule_status';" \
    "1"
verify_check "Capsule opened trigger" \
    "SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'trigger_handle_capsule_opened';" \
    "1"
verify_check "Capsule unlocked notification trigger" \
    "SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'trigger_notify_capsule_unlocked';" \
    "1"
verify_check "Updated_at triggers" \
    "SELECT COUNT(*) FROM pg_trigger WHERE tgname LIKE 'trigger_update_%_updated_at';" \
    "4"
verify_check "Audit log triggers" \
    "SELECT COUNT(*) FROM pg_trigger WHERE tgname LIKE 'trigger_audit_%';" \
    "2"

# 6. RLS Policies
echo ""
echo -e "${BLUE}6. RLS Policies${NC}"
verify_check "User profiles RLS enabled" \
    "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_profiles' AND rowsecurity = true;" \
    "1"
verify_check "Recipients RLS enabled" \
    "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'recipients' AND rowsecurity = true;" \
    "1"
verify_check "Capsules RLS enabled" \
    "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'capsules' AND rowsecurity = true;" \
    "1"
verify_check "RLS policies exist" \
    "SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public';" \
    "25" "true"

# 7. Indexes
echo ""
echo -e "${BLUE}7. Indexes${NC}"
verify_check "Key indexes exist" \
    "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public' AND indexname LIKE 'idx_%';" \
    "20" "true"

# 8. Storage
echo ""
echo -e "${BLUE}8. Storage Buckets${NC}"
verify_check "avatars bucket" \
    "SELECT COUNT(*) FROM storage.buckets WHERE id = 'avatars';" \
    "1"
verify_check "capsule_assets bucket" \
    "SELECT COUNT(*) FROM storage.buckets WHERE id = 'capsule_assets';" \
    "1"
verify_check "animations bucket" \
    "SELECT COUNT(*) FROM storage.buckets WHERE id = 'animations';" \
    "1"
verify_check "themes bucket" \
    "SELECT COUNT(*) FROM storage.buckets WHERE id = 'themes';" \
    "1"

# 9. Seed Data
echo ""
echo -e "${BLUE}9. Seed Data${NC}"
verify_check "Themes seeded" \
    "SELECT COUNT(*) FROM public.themes;" \
    "6" "true"
verify_check "Animations seeded" \
    "SELECT COUNT(*) FROM public.animations;" \
    "5" "true"

# 10. Scheduled Jobs
echo ""
echo -e "${BLUE}10. Scheduled Jobs${NC}"
verify_check "Scheduled jobs exist" \
    "SELECT COUNT(*) FROM cron.job WHERE jobname IN ('delete-expired-disappearing-messages', 'send-unlock-soon-notifications', 'update-premium-status');" \
    "3" "true"

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "======================================"
echo -e "${BLUE}📊 Verification Summary${NC}"
echo "======================================"
echo -e "${GREEN}✅ Passed: $CHECKS_PASSED${NC}"
if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
fi
if [ "$CHECKS_FAILED" -gt 0 ]; then
    echo -e "${RED}❌ Failed: $CHECKS_FAILED${NC}"
    echo ""
    echo -e "${RED}❌ Verification failed!${NC}"
    echo "Run ./scripts/migrate.sh to apply missing changes."
    exit 1
else
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Some optional checks had warnings (seed data, scheduled jobs)${NC}"
    fi
    exit 0
fi

