# Migrations 25, 26, 27: Visual Flow Diagram

> **Visual representation** of the migration chain and function flow.  
> For detailed documentation, see [MIGRATIONS_25_26_27.md](./MIGRATIONS_25_26_27.md).

---

## Migration Chain Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Migration 13 (Original)                                    │
│ open_letter() - Recipients only                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Migration 25: Add Self-Send Support                        │
│                                                             │
│ ✅ Adds: Sender check for self-sends                       │
│ ❌ Bug: Ambiguous column reference                         │
│ ❌ Bug: Missing TEXT cast                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Migration 26: Tighten Security                              │
│                                                             │
│ ✅ Adds: Security clarification                            │
│ ❌ Bug: Same as migration 25 (not fixed)                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Migration 27: Fix All Bugs ✅ FINAL                         │
│                                                             │
│ ✅ Fixes: Ambiguous columns                                │
│ ✅ Fixes: Datatype mismatch                                │
│ ✅ Optimizes: Single UPDATE                                │
│                                                             │
│ Result: Production-ready function                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Function Flow (Migration 27)

```
┌─────────────────────────────────────────────────────────────┐
│ open_letter(letter_id UUID)                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │ Get Capsule Data      │
         │ (JOIN recipients)     │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │ Security Check #1      │
         │ Is caller the sender?  │
         └───────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
    ┌─────────┐           ┌──────────────┐
    │  YES    │           │     NO       │
    └────┬────┘           └──────┬───────┘
         │                       │
         ▼                       ▼
    ┌─────────────────┐   ┌──────────────────┐
    │ Self-send?      │   │ Recipient check   │
    │ linked_user_id  │   │ (normal case)     │
    │ = sender_id?    │   └──────┬───────────┘
    └────┬────────────┘          │
         │                       │
    ┌────┴────┐                  │
    │         │                  │
    ▼         ▼                  ▼
┌───────┐ ┌──────────┐    ┌──────────────┐
│ ALLOW │ │  REJECT  │    │    ALLOW     │
└───┬───┘ └──────────┘    └──────┬───────┘
    │                             │
    └─────────────┬───────────────┘
                  │
                  ▼
         ┌───────────────────────┐
         │ Security Check #2      │
         │ Status = 'sealed' or   │
         │ 'ready'?               │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │ Security Check #3      │
         │ unlocks_at <= now()?   │
         └───────────┬───────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │ Already opened?        │
         └───────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
    ┌─────────┐           ┌──────────────┐
    │  YES    │           │     NO       │
    └────┬────┘           └──────┬───────┘
         │                       │
         ▼                       ▼
    ┌─────────────────┐   ┌──────────────────┐
    │ Return existing │   │ UPDATE:          │
    │ data            │   │ - opened_at      │
    │ (idempotent)    │   │ - status         │
    └─────────────────┘   │ - reveal_at      │
                          │   (if anonymous) │
                          └──────┬───────────┘
                                 │
                                 ▼
                          ┌──────────────────┐
                          │ Return updated   │
                          │ capsule data     │
                          └──────────────────┘
```

---

## Security Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Authorization Checks (5 Layers)                            │
└─────────────────────────────────────────────────────────────┘

Layer 1: Sender Verification
├─ Is caller the sender?
│  ├─ YES → Is it a self-send? (linked_user_id = sender_id)
│  │        ├─ YES → ✅ ALLOW
│  │        └─ NO  → ❌ REJECT (security: sender cannot open others' letters)
│  └─ NO  → Continue to Layer 2

Layer 2: Recipient Verification (Connection-Based)
├─ Is recipient linked to a user?
│  ├─ YES → Is caller the linked user?
│  │        ├─ YES → ✅ ALLOW
│  │        └─ NO  → ❌ REJECT
│  └─ NO  → Continue to Layer 3

Layer 3: Recipient Verification (Email-Based)
├─ Is recipient email-based?
│  ├─ YES → Does caller's email match?
│  │        ├─ YES → ✅ ALLOW
│  │        └─ NO  → ❌ REJECT
│  └─ NO  → ❌ REJECT (invalid configuration)

Layer 4: Status Validation
├─ Is status 'sealed' or 'ready'?
│  ├─ YES → Continue to Layer 5
│  └─ NO  → ❌ REJECT

Layer 5: Time Validation
├─ Has unlocks_at passed?
│  ├─ YES → ✅ ALLOW (proceed to open)
│  └─ NO  → ❌ REJECT (not yet unlocked)
```

---

## Performance Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Query Execution Flow                                         │
└─────────────────────────────────────────────────────────────┘

Step 1: Initial SELECT (< 1ms)
├─ FROM capsules c
├─ JOIN recipients r ON c.recipient_id = r.id
├─ WHERE c.id = letter_id (PRIMARY KEY)
└─ Result: Single row with capsule + recipient data

Step 2: Security Checks (< 0.1ms)
├─ Authorization validation (in-memory)
└─ Status/time validation (in-memory)

Step 3a: Already Opened? (< 1ms)
├─ IF opened_at IS NOT NULL
├─ SELECT with LEFT JOIN user_profiles (PRIMARY KEY)
└─ RETURN (idempotent)

Step 3b: Open Letter (< 2ms)
├─ UPDATE capsules (PRIMARY KEY WHERE clause)
│  ├─ SET opened_at = now()
│  ├─ SET status = 'opened'
│  └─ SET reveal_at = CASE ... (if anonymous)
└─ Single atomic operation

Step 4: Return Data (< 1ms)
├─ SELECT with LEFT JOIN user_profiles (PRIMARY KEY)
└─ RETURN updated capsule data

Total: < 5ms
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Input: letter_id (UUID)                                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Processing:                                                  │
│                                                              │
│ 1. Fetch capsule + recipient data                           │
│ 2. Verify authorization (5 layers)                          │
│ 3. Check if already opened                                  │
│ 4. Update if needed (atomic)                                │
│ 5. Calculate reveal_at (if anonymous)                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Output: Table with capsule data                              │
│                                                              │
│ - id, sender_id, sender_name, sender_avatar_url            │
│ - recipient_id, is_anonymous, status                       │
│ - reveal_at, opened_at, created_at                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Error Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Error Handling                                               │
└─────────────────────────────────────────────────────────────┘

Error: Capsule not found
├─ Condition: NOT FOUND after SELECT
└─ Response: RAISE EXCEPTION 'Capsule not found or deleted'

Error: Unauthorized (Sender opening others' letter)
├─ Condition: auth.uid() = sender_id AND linked_user_id != sender_id
└─ Response: RAISE EXCEPTION 'Only recipient can open this letter'

Error: Unauthorized (Wrong recipient)
├─ Condition: auth.uid() != linked_user_id (connection-based)
└─ Response: RAISE EXCEPTION 'Only recipient can open this letter'

Error: Unauthorized (Wrong email)
├─ Condition: Email mismatch (email-based)
└─ Response: RAISE EXCEPTION 'Only recipient can open this letter'

Error: Invalid configuration
├─ Condition: No linked_user_id and no email
└─ Response: RAISE EXCEPTION 'Invalid recipient configuration'

Error: Invalid status
├─ Condition: Status not 'sealed' or 'ready'
└─ Response: RAISE EXCEPTION 'Letter is not eligible to open'

Error: Not yet unlocked
├─ Condition: unlocks_at > now()
└─ Response: RAISE EXCEPTION 'Letter is not yet unlocked'
```

---

**Last Updated**: December 2025  
**See Also**: [MIGRATIONS_25_26_27.md](./MIGRATIONS_25_26_27.md) for detailed documentation

