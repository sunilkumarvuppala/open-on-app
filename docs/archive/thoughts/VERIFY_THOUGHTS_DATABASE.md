# Verify Thoughts Feature in Database

## Quick Verification Queries

Run these queries in **Supabase SQL Editor** to verify everything is working.

---

## 1. Check Tables Exist

```sql
-- Verify thoughts and rate_limits tables exist
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('thoughts', 'thought_rate_limits')
ORDER BY table_name;
```

**Expected Output:**
```
table_name          | table_type
--------------------|------------
thought_rate_limits | BASE TABLE
thoughts            | BASE TABLE
```

---

## 2. Check Functions Exist

```sql
-- Verify RPC functions exist
SELECT 
  routine_name,
  routine_type,
  data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%thought%'
ORDER BY routine_name;
```

**Expected Output:**
```
routine_name              | routine_type | return_type
--------------------------|--------------|------------
rpc_list_incoming_thoughts | FUNCTION     | jsonb
rpc_list_sent_thoughts     | FUNCTION     | jsonb
rpc_send_thought          | FUNCTION     | jsonb
set_thought_day_bucket     | FUNCTION     | trigger
```

---

## 3. Check Indexes Exist

```sql
-- Verify indexes are created
SELECT 
  indexname,
  tablename,
  indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND (indexname LIKE '%thought%' OR tablename IN ('thoughts', 'thought_rate_limits'))
ORDER BY tablename, indexname;
```

**Expected Output:**
```
indexname                      | tablename          | indexdef
-------------------------------|--------------------|----------------------------------------
idx_thought_rate_limits_day    | thought_rate_limits | CREATE INDEX ...
idx_thoughts_receiver_created  | thoughts           | CREATE INDEX ...
idx_thoughts_sender_created    | thoughts           | CREATE INDEX ...
idx_thoughts_sender_day        | thoughts           | CREATE INDEX ...
thought_rate_limits_pkey       | thought_rate_limits | CREATE UNIQUE INDEX ...
thoughts_pkey                  | thoughts           | CREATE UNIQUE INDEX ...
```

---

## 4. Check RLS Policies

```sql
-- Verify RLS is enabled and policies exist
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('thoughts', 'thought_rate_limits')
ORDER BY tablename, policyname;
```

**Expected Output:**
```
schemaname | tablename          | policyname                    | cmd    | roles
-----------|--------------------|-------------------------------|--------|-------
public     | thought_rate_limits| System can manage rate limits | ALL    | {authenticated}
public     | thought_rate_limits| Users can view own rate limits| SELECT | {authenticated}
public     | thoughts           | Receivers can view incoming   | SELECT | {authenticated}
public     | thoughts           | Senders can view sent thoughts| SELECT | {authenticated}
public     | thoughts           | System can delete thoughts    | DELETE | {authenticated}
public     | thoughts           | Users can send thoughts via RPC| INSERT | {authenticated}
```

---

## 5. Check Constraints

```sql
-- Verify constraints exist
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  conrelid::regclass as table_name
FROM pg_constraint
WHERE conrelid::regclass::text IN ('thoughts', 'thought_rate_limits')
ORDER BY table_name, constraint_name;
```

**Expected Output:**
```
constraint_name                    | constraint_type | table_name
-----------------------------------|-----------------|------------
thought_rate_limits_pkey           | p               | thought_rate_limits
thoughts_no_self_send              | c               | thoughts
thoughts_pkey                      | p               | thoughts
thoughts_unique_per_pair_per_day   | u               | thoughts
```

---

## 6. View All Thoughts (Service Role Only)

```sql
-- View all thoughts (requires service role or admin)
-- This bypasses RLS to see all data
SELECT 
  t.id,
  t.sender_id,
  t.receiver_id,
  t.created_at,
  t.day_bucket,
  t.client_source,
  sender.first_name || ' ' || COALESCE(sender.last_name, '') as sender_name,
  receiver.first_name || ' ' || COALESCE(receiver.last_name, '') as receiver_name
FROM public.thoughts t
LEFT JOIN public.user_profiles sender ON t.sender_id = sender.user_id
LEFT JOIN public.user_profiles receiver ON t.receiver_id = receiver.user_id
ORDER BY t.created_at DESC
LIMIT 20;
```

**Expected Output:**
```
id                                   | sender_id | receiver_id | created_at          | day_bucket | sender_name | receiver_name
-------------------------------------|-----------|-------------|---------------------|------------|-------------|---------------
550e8400-e29b-41d4-a716-446655440000 | ...       | ...         | 2025-01-15 10:30:00 | 2025-01-15 | John Doe    | Jane Smith
```

---

## 7. View Rate Limits

```sql
-- View rate limit records
SELECT 
  sender_id,
  day_bucket,
  sent_count,
  updated_at
FROM public.thought_rate_limits
ORDER BY day_bucket DESC, sent_count DESC
LIMIT 20;
```

**Expected Output:**
```
sender_id                            | day_bucket | sent_count | updated_at
-------------------------------------|------------|------------|-------------------
550e8400-e29b-41d4-a716-446655440000 | 2025-01-15 | 5          | 2025-01-15 14:30:00
```

---

## 8. Test RPC Function (As Authenticated User)

**Important**: You need to be authenticated as a user to test RPC functions.

```sql
-- First, check your current user
SELECT auth.uid() as current_user_id;

-- If NULL, you're not authenticated. You need to:
-- 1. Use Supabase SQL Editor with your user's JWT token, OR
-- 2. Test from Flutter app, OR
-- 3. Use service role (bypasses RLS)

-- Test listing incoming thoughts (as authenticated user)
SELECT * FROM public.rpc_list_incoming_thoughts(
  p_cursor_created_at := NULL,
  p_limit := 10
);

-- Test listing sent thoughts (as authenticated user)
SELECT * FROM public.rpc_list_sent_thoughts(
  p_cursor_created_at := NULL,
  p_limit := 10
);
```

---

## 9. Check Recent Thoughts by User

```sql
-- View thoughts sent by a specific user (replace USER_ID)
SELECT 
  t.id,
  t.receiver_id,
  t.created_at,
  t.day_bucket,
  receiver.first_name || ' ' || COALESCE(receiver.last_name, '') as receiver_name
FROM public.thoughts t
LEFT JOIN public.user_profiles receiver ON t.receiver_id = receiver.user_id
WHERE t.sender_id = 'YOUR_USER_ID_HERE'::uuid
ORDER BY t.created_at DESC;

-- View thoughts received by a specific user (replace USER_ID)
SELECT 
  t.id,
  t.sender_id,
  t.created_at,
  t.day_bucket,
  sender.first_name || ' ' || COALESCE(sender.last_name, '') as sender_name
FROM public.thoughts t
LEFT JOIN public.user_profiles sender ON t.sender_id = sender.user_id
WHERE t.receiver_id = 'YOUR_USER_ID_HERE'::uuid
ORDER BY t.created_at DESC;
```

---

## 10. Verify Cooldown Logic

```sql
-- Check if cooldown is working (should only see 1 per sender-receiver per day)
SELECT 
  sender_id,
  receiver_id,
  day_bucket,
  COUNT(*) as thought_count,
  array_agg(id ORDER BY created_at) as thought_ids
FROM public.thoughts
GROUP BY sender_id, receiver_id, day_bucket
HAVING COUNT(*) > 1  -- This should return 0 rows if cooldown works
ORDER BY day_bucket DESC;
```

**Expected Output:**
```
(0 rows)  -- Good! No duplicates per day
```

If you see rows, there's a problem with the unique constraint.

---

## 11. Verify Rate Limiting

```sql
-- Check if any user exceeded daily limit (should be max 20)
SELECT 
  sender_id,
  day_bucket,
  sent_count
FROM public.thought_rate_limits
WHERE sent_count > 20
ORDER BY sent_count DESC;
```

**Expected Output:**
```
(0 rows)  -- Good! No one exceeded limit
```

---

## 12. Check Connections (Required for Thoughts)

```sql
-- Verify connections exist (thoughts can only be sent between connected users)
SELECT 
  user_id_1,
  user_id_2,
  connected_at
FROM public.connections
ORDER BY connected_at DESC
LIMIT 10;
```

**Note**: Users must be in `connections` table to send thoughts to each other.

---

## 13. Test Sending a Thought (Service Role)

**⚠️ WARNING**: This bypasses RLS. Only use for testing!

```sql
-- Set a test user context (replace with actual user ID)
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = 'YOUR_USER_ID_HERE'::text;

-- Try to send a thought (replace receiver_id)
SELECT public.rpc_send_thought(
  p_receiver_id := 'RECEIVER_USER_ID_HERE'::uuid,
  p_client_source := 'test'::text
);
```

**Expected Results:**
- ✅ Success: Returns JSON with `thought_id`
- ❌ Error: Returns error message (e.g., "NOT_CONNECTED", "THOUGHT_ALREADY_SENT_TODAY")

---

## 14. Verify Day Bucket Trigger

```sql
-- Check if day_bucket is set correctly
SELECT 
  id,
  created_at,
  day_bucket,
  DATE(created_at) as expected_day_bucket,
  CASE 
    WHEN day_bucket = DATE(created_at) THEN '✅ Correct'
    ELSE '❌ Mismatch'
  END as status
FROM public.thoughts
ORDER BY created_at DESC
LIMIT 10;
```

**Expected Output:**
```
id   | created_at          | day_bucket | expected_day_bucket | status
-----|---------------------|------------|---------------------|--------
...  | 2025-01-15 10:30:00 | 2025-01-15 | 2025-01-15          | ✅ Correct
```

---

## 15. Count Statistics

```sql
-- Get overall statistics
SELECT 
  'Total Thoughts' as metric,
  COUNT(*)::text as value
FROM public.thoughts
UNION ALL
SELECT 
  'Unique Senders' as metric,
  COUNT(DISTINCT sender_id)::text as value
FROM public.thoughts
UNION ALL
SELECT 
  'Unique Receivers' as metric,
  COUNT(DISTINCT receiver_id)::text as value
FROM public.thoughts
UNION ALL
SELECT 
  'Thoughts Today' as metric,
  COUNT(*)::text as value
FROM public.thoughts
WHERE day_bucket = CURRENT_DATE
UNION ALL
SELECT 
  'Active Rate Limits' as metric,
  COUNT(*)::text as value
FROM public.thought_rate_limits
WHERE day_bucket = CURRENT_DATE;
```

**Expected Output:**
```
metric              | value
--------------------|-------
Total Thoughts      | 42
Unique Senders      | 10
Unique Receivers    | 15
Thoughts Today      | 5
Active Rate Limits  | 3
```

---

## 16. Check for Orphaned Records

```sql
-- Check for thoughts with invalid sender/receiver
SELECT 
  'Invalid Sender' as issue,
  COUNT(*) as count
FROM public.thoughts t
LEFT JOIN auth.users u ON t.sender_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 
  'Invalid Receiver' as issue,
  COUNT(*) as count
FROM public.thoughts t
LEFT JOIN auth.users u ON t.receiver_id = u.id
WHERE u.id IS NULL;
```

**Expected Output:**
```
issue            | count
-----------------|------
Invalid Sender  | 0
Invalid Receiver| 0
```

If count > 0, there are orphaned records (foreign key constraint should prevent this).

---

## Quick Verification Checklist

Run these in order:

- [ ] **Tables exist**: Query #1
- [ ] **Functions exist**: Query #2
- [ ] **Indexes exist**: Query #3
- [ ] **RLS enabled**: Query #4
- [ ] **Constraints exist**: Query #5
- [ ] **Can see thoughts**: Query #6 (service role)
- [ ] **Rate limits working**: Query #11
- [ ] **Cooldown working**: Query #10

---

## Common Issues

### Issue: "relation does not exist"
**Solution**: Migration not applied. Run `supabase migration up --linked` or apply via SQL Editor.

### Issue: "permission denied"
**Solution**: You're not using service role. Use Supabase SQL Editor with service role key, or test as authenticated user.

### Issue: "function does not exist"
**Solution**: Migration not applied correctly. Re-run migration.

### Issue: RLS blocking queries
**Solution**: Use service role for admin queries, or authenticate as the user for user-specific queries.

---

## Testing End-to-End

1. **Send a thought** from Flutter app (User A → User B)
2. **Run Query #6** to verify thought is in database
3. **Run Query #7** to verify rate limit incremented
4. **Run Query #10** to verify cooldown works (try sending again)
5. **Run Query #9** to see thoughts from User A's perspective

---

## Need Help?

If queries don't return expected results:
1. Check migration was applied: `SELECT * FROM supabase_migrations.schema_migrations ORDER BY version DESC LIMIT 5;`
2. Check for errors in Supabase logs
3. Verify RLS policies are correct
4. Test with service role to bypass RLS

