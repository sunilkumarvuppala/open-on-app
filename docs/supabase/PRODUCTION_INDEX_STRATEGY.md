# Production Index Strategy - 200K+ Users

## Overview

This document outlines the comprehensive indexing strategy for OpenOn database, optimized for **200,000+ users** and scalable to **1,000,000+ users**. All indexes follow PostgreSQL best practices with no shortcuts or hacks.

## Index Design Principles

### 1. **Composite Indexes for Multi-Column Queries**
- Index columns in order of selectivity (most selective first)
- Include `deleted_at` in composite indexes for soft-delete filtering
- Use DESC ordering for columns that are frequently sorted DESC

### 2. **Partial Indexes for Efficiency**
- Use `WHERE` clauses to index only relevant rows
- Reduces index size by 50-90% in many cases
- Improves query performance and reduces maintenance overhead

### 3. **Foreign Key Indexes**
- PostgreSQL doesn't auto-index foreign keys
- All foreign keys have explicit indexes for JOIN performance
- Critical for referential integrity checks at scale

### 4. **Functional Indexes for Case-Insensitive Matching**
- Use `LOWER()` for email/name matching
- Use `TRIM()` for name matching to handle whitespace
- Partial indexes with `WHERE` clauses for specific use cases

## Index Catalog

### Capsules Table

#### Primary Query Patterns
1. **Outbox Queries** (sender_id + deleted_at + created_at)
   - Index: `idx_capsules_sender_deleted_created`
   - Query: `WHERE sender_id = ? AND deleted_at IS NULL ORDER BY created_at DESC`
   - Usage: Loading user's sent letters

2. **Inbox Queries** (recipient_id + deleted_at + created_at)
   - Index: `idx_capsules_recipient_deleted_created`
   - Query: `WHERE recipient_id = ? AND deleted_at IS NULL ORDER BY created_at DESC`
   - Usage: Loading user's received letters

3. **Letter Count Queries** (sender_id + recipient_id)
   - Indexes: 
     - `idx_capsules_sender_recipient_deleted` (for sent letters)
     - `idx_capsules_recipient_sender_deleted` (for received letters)
   - Query: `WHERE sender_id = ? AND recipient_id = ? AND deleted_at IS NULL`
   - Usage: Connection detail page letter counts
   - **CRITICAL**: Used heavily, must be optimized

4. **Status Filtering** (sender_id/recipient_id + status + deleted_at + created_at)
   - Indexes:
     - `idx_capsules_sender_status_deleted_created`
     - `idx_capsules_recipient_status_deleted_created`
   - Query: `WHERE sender_id = ? AND status = ? AND deleted_at IS NULL ORDER BY created_at DESC`
   - Usage: Filtering by status (sealed, ready, opened, expired)

5. **Cron Job Queries**
   - `idx_capsules_unlocks_at`: Finding capsules ready to unlock
   - `idx_capsules_opened_at`: Finding expired disappearing messages
   - Both use partial indexes with specific WHERE clauses

#### Index List
```sql
-- Base indexes
idx_capsules_sender_deleted_created (sender_id, deleted_at, created_at DESC) WHERE deleted_at IS NULL
idx_capsules_recipient_deleted_created (recipient_id, deleted_at, created_at DESC) WHERE deleted_at IS NULL
idx_capsules_status (status)

-- Letter count indexes (CRITICAL)
idx_capsules_sender_recipient_deleted (sender_id, recipient_id, deleted_at) WHERE deleted_at IS NULL
idx_capsules_recipient_sender_deleted (recipient_id, sender_id, deleted_at) WHERE deleted_at IS NULL

-- Status filtering indexes
idx_capsules_sender_status_deleted_created (sender_id, status, deleted_at, created_at DESC) WHERE deleted_at IS NULL
idx_capsules_recipient_status_deleted_created (recipient_id, status, deleted_at, created_at DESC) WHERE deleted_at IS NULL

-- Cron job indexes (partial)
idx_capsules_unlocks_at (unlocks_at) WHERE status = 'sealed' AND deleted_at IS NULL
idx_capsules_opened_at (opened_at) WHERE is_disappearing = TRUE AND deleted_at IS NULL

-- Foreign key indexes
idx_capsules_theme_id (theme_id) WHERE theme_id IS NOT NULL
idx_capsules_animation_id (animation_id) WHERE animation_id IS NOT NULL
```

### Recipients Table

#### Primary Query Patterns
1. **Owner Lookups** (owner_id + created_at)
   - Index: `idx_recipients_owner_created`
   - Query: `WHERE owner_id = ? ORDER BY created_at DESC`
   - Usage: Loading user's recipient list

2. **Connection-Based Lookups** (owner_id + linked_user_id)
   - Index: `idx_recipients_owner_linked_user`
   - Query: `WHERE owner_id = ? AND linked_user_id = ?`
   - Usage: Finding recipient for a specific connection
   - **CRITICAL**: Used for letter counting and capsule creation

3. **Reverse Connection Lookups** (linked_user_id + owner_id)
   - Index: `idx_recipients_linked_user_owner`
   - Query: `WHERE linked_user_id = ? AND owner_id = ?`
   - Usage: Finding recipient from connection user ID

4. **Email-Based Lookups** (owner_id + LOWER(email))
   - Index: `idx_recipients_email_lower`
   - Query: `WHERE owner_id = ? AND LOWER(email) = LOWER(?)`
   - Usage: Email-based recipient matching

5. **Name-Based Lookups** (owner_id + LOWER(TRIM(name)))
   - Index: `idx_recipients_name_lower`
   - Query: `WHERE owner_id = ? AND LOWER(TRIM(name)) = LOWER(TRIM(?))`
   - Usage: Connection-based recipient matching

#### Index List
```sql
-- Base indexes
idx_recipients_owner (owner_id)
idx_recipients_owner_created (owner_id, created_at DESC)
idx_recipients_relationship (owner_id, relationship)
idx_recipients_email (owner_id, email) WHERE email IS NOT NULL

-- Connection-based indexes (CRITICAL)
idx_recipients_owner_linked_user (owner_id, linked_user_id) WHERE linked_user_id IS NOT NULL
idx_recipients_linked_user_owner (linked_user_id, owner_id) WHERE linked_user_id IS NOT NULL

-- Functional indexes for matching
idx_recipients_email_lower (owner_id, LOWER(email)) WHERE email IS NOT NULL
idx_recipients_name_lower (owner_id, LOWER(TRIM(name))) WHERE email IS NULL
```

### Connections Table

#### Primary Query Patterns
1. **User1 Lookups** (user_id_1 + connected_at)
   - Index: `idx_connections_user1_connected_at`
   - Query: `WHERE user_id_1 = ? ORDER BY connected_at DESC`
   - Usage: UNION ALL optimized query (part 1)

2. **User2 Lookups** (user_id_2 + connected_at)
   - Index: `idx_connections_user2_connected_at`
   - Query: `WHERE user_id_2 = ? ORDER BY connected_at DESC`
   - Usage: UNION ALL optimized query (part 2)

#### Index List
```sql
-- Base indexes
idx_connections_user1 (user_id_1)
idx_connections_user2 (user_id_2)

-- Composite indexes for sorted queries
idx_connections_user1_connected_at (user_id_1, connected_at DESC)
idx_connections_user2_connected_at (user_id_2, connected_at DESC)
```

### Connection Requests Table

#### Primary Query Patterns
1. **Incoming Requests** (to_user_id + created_at)
   - Index: `idx_connection_requests_to_user_created`
   - Query: `WHERE to_user_id = ? ORDER BY created_at DESC`

2. **Outgoing Requests** (from_user_id + created_at)
   - Index: `idx_connection_requests_from_user_created`
   - Query: `WHERE from_user_id = ? ORDER BY created_at DESC`

3. **Pending Requests** (to_user_id/from_user_id + created_at, status = 'pending')
   - Indexes:
     - `idx_connection_requests_to_user_pending`
     - `idx_connection_requests_from_user_pending`
   - Query: `WHERE to_user_id = ? AND status = 'pending' ORDER BY created_at DESC`

#### Index List
```sql
-- Composite indexes for sorted queries
idx_connection_requests_to_user_created (to_user_id, created_at DESC)
idx_connection_requests_from_user_created (from_user_id, created_at DESC)

-- Partial indexes for pending requests
idx_connection_requests_to_user_pending (to_user_id, created_at DESC) WHERE status = 'pending'
idx_connection_requests_from_user_pending (from_user_id, created_at DESC) WHERE status = 'pending'

-- Duplicate prevention
idx_connection_requests_unique_pending (from_user_id, to_user_id) WHERE status = 'pending'
idx_connection_requests_from_to_status (from_user_id, to_user_id, status)
```

## Performance Metrics

### Expected Query Performance (200K Users)

| Query Type | Without Indexes | With Indexes | Improvement |
|-----------|----------------|--------------|-------------|
| Outbox (100 capsules) | 200-500ms | 5-15ms | **95% faster** |
| Inbox (100 capsules) | 300-600ms | 8-20ms | **95% faster** |
| Letter Count | 100-300ms | 2-8ms | **95% faster** |
| Connection List | 150-400ms | 10-25ms | **90% faster** |
| Recipient Lookup | 50-150ms | 1-5ms | **95% faster** |

### Index Size Estimates (200K Users)

| Table | Estimated Rows | Index Size | Notes |
|-------|---------------|------------|-------|
| capsules | 2M-5M | ~500MB-1GB | Multiple composite indexes |
| recipients | 400K-1M | ~100MB-250MB | Partial indexes reduce size |
| connections | 400K-1M | ~50MB-150MB | Composite indexes |
| connection_requests | 100K-500K | ~20MB-100MB | Partial indexes |

## Best Practices Applied

### ✅ Composite Index Column Ordering
- Most selective column first (e.g., `sender_id` before `status`)
- Filter columns before sort columns (e.g., `deleted_at` before `created_at`)
- DESC ordering for DESC sorts

### ✅ Partial Indexes
- All soft-delete indexes use `WHERE deleted_at IS NULL`
- Status-specific indexes use `WHERE status = '...'`
- Connection-based indexes use `WHERE linked_user_id IS NOT NULL`

### ✅ Functional Indexes
- `LOWER(email)` for case-insensitive email matching
- `LOWER(TRIM(name))` for case-insensitive, trimmed name matching

### ✅ Foreign Key Indexes
- All foreign keys have explicit indexes
- Partial indexes for nullable foreign keys (`WHERE column IS NOT NULL`)

### ✅ Statistics Updates
- `ANALYZE` run after index creation
- Ensures query planner has accurate statistics

## Migration Order

1. **Migration 01**: Create tables with foreign keys
2. **Migration 02**: Base indexes for all tables
3. **Migration 08**: Connection tables and base indexes
4. **Migration 17**: Connection query optimization indexes
5. **Migration 18**: Add `linked_user_id` column and indexes
6. **Migration 19**: Backfill recipients (uses indexes from 18)
7. **Migration 20**: Additional production optimizations

## Monitoring

### Key Metrics to Monitor

1. **Index Usage**
   ```sql
   SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
   FROM pg_stat_user_indexes
   WHERE schemaname = 'public'
   ORDER BY idx_scan DESC;
   ```

2. **Index Bloat**
   ```sql
   SELECT schemaname, tablename, indexname, pg_size_pretty(pg_relation_size(indexrelid)) as size
   FROM pg_stat_user_indexes
   WHERE schemaname = 'public'
   ORDER BY pg_relation_size(indexrelid) DESC;
   ```

3. **Slow Queries**
   - Enable `log_min_duration_statement = 1000` (log queries > 1s)
   - Monitor connection detail page queries (letter counts)
   - Monitor inbox/outbox queries

### Query Performance Testing

```sql
-- Test letter count query performance
EXPLAIN ANALYZE
SELECT COUNT(*) FROM capsules
WHERE sender_id = '...' AND recipient_id = '...' AND deleted_at IS NULL;

-- Test inbox query performance
EXPLAIN ANALYZE
SELECT * FROM capsules
WHERE recipient_id = '...' AND deleted_at IS NULL
ORDER BY created_at DESC
LIMIT 50;
```

## Maintenance

### Regular Maintenance Tasks

1. **VACUUM ANALYZE** (weekly)
   ```sql
   VACUUM ANALYZE public.capsules;
   VACUUM ANALYZE public.recipients;
   VACUUM ANALYZE public.connections;
   ```

2. **REINDEX** (monthly, if needed)
   ```sql
   REINDEX TABLE public.capsules;
   REINDEX TABLE public.recipients;
   ```

3. **Monitor Index Bloat**
   - Check index sizes monthly
   - Rebuild indexes if bloat > 30%

## Scaling to 1M+ Users

### Additional Optimizations

1. **Partitioning** (if needed at 1M+)
   - Partition `capsules` by `created_at` (monthly partitions)
   - Partition `recipients` by `owner_id` (hash partitioning)

2. **Read Replicas**
   - Use read replicas for analytics queries
   - Separate write and read workloads

3. **Connection Pooling**
   - Use PgBouncer or similar
   - Reduce connection overhead

4. **Query Result Caching**
   - Cache connection lists (5-10 minutes)
   - Cache letter counts (1-2 minutes)

## Summary

✅ **All foreign keys indexed**  
✅ **All common query patterns optimized**  
✅ **Partial indexes for efficiency**  
✅ **Composite indexes properly ordered**  
✅ **Functional indexes for case-insensitive matching**  
✅ **Statistics updated for query planner**  
✅ **Production-ready for 200K+ users**  
✅ **Scalable to 1M+ users with additional optimizations**

---

**Last Updated**: December 2025  
**Status**: Production-Ready

