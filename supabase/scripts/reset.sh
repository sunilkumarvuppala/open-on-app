#!/bin/bash

# ============================================================================
# Supabase Reset Script
# Resets local database and reapplies all migrations
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

echo -e "${YELLOW}⚠️  Supabase Reset Script${NC}"
echo "=============================="
echo ""
echo -e "${RED}This will reset your local database and delete all data!${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Reset cancelled."
    exit 0
fi

cd "$SUPABASE_DIR"

# Check if Supabase is running
if ! supabase status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Supabase not running. Starting...${NC}"
    supabase start
fi

echo ""
echo -e "${GREEN}🔄 Resetting database...${NC}"

# Reset database
supabase db reset

echo ""
echo -e "${GREEN}✅ Database reset complete!${NC}"
echo ""
echo "All migrations have been reapplied."
echo "Access Supabase Studio: http://localhost:54323"

