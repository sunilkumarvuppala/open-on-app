# Letter Count Calculation - Analysis & Issues

## Current Approach

### Problem Statement
The backend's `list_recipients` endpoint returns `id=other_user_id` (connection user ID) for connection-based recipients, but capsules store actual recipient UUIDs in the `recipient_id` field. This creates a mismatch when trying to count letters.

### Current Implementation
**File**: `frontend/lib/core/data/api_repositories.dart`

**For Letters Sent**:
- Matches by `receiverName` (from capsule response) against connection's display name
- Uses fuzzy matching (contains logic) to handle name variations

**For Letters Received**:
- Filters by `senderId == connectionId` (correct, as backend already filters inbox)

## Potential Issues

### 1. Name Matching False Positives ⚠️
**Risk**: Medium
- If two connections have similar names (e.g., "John" and "John Smith"), the contains logic might incorrectly match both
- Partial matches could count letters sent to wrong recipients

**Example**:
- Connection A: "John"
- Connection B: "John Smith"
- Letter sent to "John Smith" might be counted for both connections

### 2. Name Format Differences ⚠️
**Risk**: Medium
- Connection display name: Built from `first_name + last_name` or `username`
- Recipient name in capsules: Stored when capsule was created (might be different format)
- Names might have different spacing, capitalization, or formatting

**Example**:
- Connection: "John Smith"
- Capsule recipient: "John  Smith" (double space) or "john smith" (different case)

### 3. Name Changes Over Time ⚠️
**Risk**: Low
- If a user changes their name after connection is established, old capsules will have old name
- New capsules will have new name
- Matching might miss some letters

### 4. Missing recipient_name in Response ⚠️
**Risk**: Low
- Backend includes `recipient_name` in `CapsuleResponse`
- But if recipient is deleted or not found, `recipient_name` might be null
- Fallback to "Recipient" would cause false matches

### 5. Performance ⚠️
**Risk**: Low
- Loading all outbox capsules and filtering in memory
- For users with many letters, this could be slow
- But pagination limits this (default 50)

## Verification Checklist

- [x] Backend includes `recipient_name` in capsule response
- [x] Name matching uses sanitization (handles case, whitespace)
- [x] Received letters correctly filtered by `senderId`
- [ ] Test with similar names (false positive risk)
- [ ] Test with name format differences
- [ ] Test with name changes over time
- [ ] Verify recipient_name is never null in responses

## Better Solutions

### Option 1: Backend Endpoint (Recommended) ⭐
Create a backend endpoint that returns letter counts directly:
```
GET /connections/{connection_id}/stats
Returns: { letters_sent: int, letters_received: int }
```

**Pros**:
- Most accurate (database-level queries)
- No false positives
- Better performance
- Single source of truth

**Cons**:
- Requires backend changes
- Additional API endpoint

### Option 2: Query Actual Recipient UUIDs
Query the recipients table to find actual recipient UUIDs that represent the connection, then match by `recipient_id`.

**Pros**:
- More accurate than name matching
- Uses actual database relationships

**Cons**:
- API repository doesn't have direct database access
- Would need to query recipients API and find matching UUIDs
- Still might have issues if recipient records don't exist

### Option 3: Hybrid Approach (Current + Improvements)
1. Try to match by recipient_id first (if we can find actual UUIDs)
2. Fallback to name matching with stricter rules
3. Add exact match preference over contains

**Pros**:
- Works with current architecture
- Handles edge cases better

**Cons**:
- Still has name matching risks
- More complex logic

## Recommended Next Steps

1. **Immediate**: Improve name matching to prefer exact matches
2. **Short-term**: Add backend endpoint for letter counts
3. **Long-term**: Refactor to use recipient UUIDs consistently

## Testing Scenarios

1. **Same name, different users**: Two connections both named "John"
2. **Name variations**: "John Smith" vs "John  Smith" vs "john smith"
3. **Name changes**: User changes name after sending letters
4. **Missing recipient_name**: Capsule response has null recipient_name
5. **Many letters**: User with 100+ letters to test performance

---

**Last Updated**: December 2025

