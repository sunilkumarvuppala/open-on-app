# Supabase Scripts

Utility SQL scripts for database operations, debugging, and verification.

## Scripts

- `CHECK_DEPENDENCIES.sql` - Check database dependencies
- `CHECK_MIGRATION.sql` - Verify migration status
- `DEBUG_THOUGHT_ISSUE.sql` - Debug queries for Thoughts feature
- `VERIFY_MIGRATION.sql` - Verify migration application

## Usage

These scripts can be run in:
- Supabase SQL Editor
- psql command line
- Any PostgreSQL client

## Example

```bash
# Run via psql
psql -h localhost -U postgres -d postgres -f supabase/scripts/CHECK_MIGRATION.sql
```

---

**Note**: These are utility scripts. For test queries, see `supabase/tests/`.

