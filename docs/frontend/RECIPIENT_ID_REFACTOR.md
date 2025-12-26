# Recipient ID Refactor - Production Documentation

> **Status**: ✅ Production-Ready | **Version**: 1.0.0 | **Last Updated**: December 2025  
> **Related**: [Capsule Model](./features/CAPSULE.md) | [Recipients Feature](./features/RECIPIENTS.md) | [Architecture Guide](../architecture/ARCHITECTURE.md)

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Root Cause Analysis](#root-cause-analysis)
4. [Solution Architecture](#solution-architecture)
5. [Implementation Details](#implementation-details)
6. [Data Flow Diagrams](#data-flow-diagrams)
7. [Best Practices Guide](#best-practices-guide)
8. [Migration Guide](#migration-guide)
9. [API Contracts](#api-contracts)
10. [Troubleshooting](#troubleshooting)
11. [Future Considerations](#future-considerations)

---

## Executive Summary

### What Changed

The frontend `Capsule` model field `receiverId` was renamed to `recipientId` to match backend naming conventions and clarify that it represents a recipient record UUID, not a user UUID.

### Why It Matters

- **Consistency**: Frontend and backend now use consistent naming (`recipientId`/`recipient_id`)
- **Clarity**: Field name clearly indicates it's a recipient record ID, preventing confusion
- **Prevention**: Helper methods and deprecation warnings prevent common mistakes
- **Maintainability**: Future developers immediately understand the data model

### Impact

- ✅ **Zero Breaking Changes**: API contracts remain unchanged
- ✅ **Backward Compatible**: All existing code updated seamlessly
- ✅ **Production Ready**: Follows industry best practices
- ✅ **Acquisition Ready**: Clear documentation for due diligence

---

## Problem Statement

### The Issue

Every time a new feature was added, developers encountered errors when trying to determine if the current user is the receiver of a capsule. The root cause was a fundamental misunderstanding of the data model.

### Symptoms

1. **Naming Mismatch**: Frontend used `receiverId` but backend uses `recipient_id`
2. **Semantic Confusion**: `receiverId` implied it was a user ID, but it's actually a recipient record UUID
3. **Inconsistent Checks**: Developers tried `capsule.receiverId == currentUserId`, which fails for connection-based recipients
4. **Repeated Errors**: Same mistakes occurred with every new feature

### Example of the Problem

```dart
// ❌ WRONG - This doesn't work for connection-based recipients
if (capsule.receiverId == currentUserId) {
  // This will always fail because:
  // - receiverId is a recipient UUID (from recipients table)
  // - currentUserId is a user UUID (from auth.users)
  // - For connection-based recipients, the user ID is in recipient.linked_user_id
}
```

---

## Root Cause Analysis

### Data Model Structure

#### Backend Database Schema

```
┌─────────────────┐
│   auth.users    │  ← User accounts (Supabase Auth)
│                 │
│  id (UUID)      │
│  email          │
└─────────────────┘
         ↑
         │
┌─────────────────┐
│  user_profiles  │  ← Extended user data
│                 │
│  user_id (FK)   │──→ auth.users.id
└─────────────────┘
         ↑
         │
┌─────────────────┐
│   recipients    │  ← Contact list entries
│                 │
│  id (UUID)      │  ← This is recipient_id
│  owner_id (FK)  │──→ auth.users.id (who owns this contact)
│  linked_user_id │──→ auth.users.id (if recipient is a registered user)
│  email          │  ← For email-based recipients
└─────────────────┘
         ↑
         │
┌─────────────────┐
│    capsules     │  ← Time-locked letters
│                 │
│  sender_id (FK) │──→ auth.users.id
│  recipient_id   │──→ recipients.id (NOT user.id!)
└─────────────────┘
```

#### Key Distinctions

| Concept | Type | Source | Example |
|---------|------|--------|---------|
| **User ID** | UUID | `auth.users.id` | `550e8400-e29b-41d4-a716-446655440000` |
| **Recipient ID** | UUID | `recipients.id` | `6ba7b810-9dad-11d1-80b4-00c04fd430c8` |
| **Linked User ID** | UUID | `recipients.linked_user_id` | `550e8400-e29b-41d4-a716-446655440000` |

### Two Types of Recipients

#### 1. Email-Based Recipients

```
User A creates recipient:
  - name: "John Doe"
  - email: "john@example.com"
  - linked_user_id: NULL

Capsule created:
  - recipient_id → recipients.id (UUID)
  - Backend matches by: recipient.email == user.email
```

#### 2. Connection-Based Recipients

```
User A connects with User B:
  - User A's recipient list gets entry:
    - name: "Jane Smith"
    - email: NULL
    - linked_user_id: User B's user_id

Capsule created:
  - recipient_id → recipients.id (UUID)
  - Backend matches by: recipient.linked_user_id == user.id
```

### The Confusion

The frontend model used `receiverId` which:
- **Implied**: It was the user ID of the receiver
- **Reality**: It's the UUID of the recipient record
- **Problem**: Cannot directly compare with `currentUserId`

---

## Solution Architecture

### Design Principles

1. **Naming Consistency**: Frontend matches backend naming
2. **Type Safety**: Clear distinction between user IDs and recipient IDs
3. **Developer Experience**: Helper methods prevent common mistakes
4. **Backend Verification**: Receiver status always verified server-side

### Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Backend (PostgreSQL)                      │
│                                                              │
│  capsules.recipient_id → recipients.id                       │
│  recipients.linked_user_id → auth.users.id (if connection)  │
│  recipients.email (if email-based)                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    API Response
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Frontend (Flutter/Dart)                         │
│                                                              │
│  CapsuleMapper maps:                                         │
│    recipient_id → recipientId                                │
│                                                              │
│  Capsule Model:                                              │
│    - recipientId: String (recipient record UUID)             │
│    - isCurrentUserSender(userId): bool                       │
│    - isCurrentUserReceiver(userId): @Deprecated             │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    Usage in Features
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Feature Implementation                          │
│                                                              │
│  ✅ DO:                                                      │
│    if (capsule.isCurrentUserSender(userId)) { ... }         │
│    await apiClient.post('/track-view'); // Backend verifies │
│                                                              │
│  ❌ DON'T:                                                   │
│    if (capsule.recipientId == userId) { ... } // WRONG!    │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Details

### 1. Model Changes

#### Before

```dart
class Capsule {
  final String receiverId; // ❌ Confusing name
  // ...
}
```

#### After

```dart
/// Capsule model - represents a time-locked letter
/// 
/// IMPORTANT: recipientId is the UUID of the recipient record (from recipients table),
/// NOT the user ID of the receiver. For connection-based recipients, use the recipient's
/// linked_user_id to find the actual user. For email-based recipients, match by email.
class Capsule {
  final String recipientId; // ✅ Clear naming
  // ...
  
  /// Check if the current user is the sender of this capsule
  /// 
  /// This is a simple comparison since senderId is always a user UUID.
  bool isCurrentUserSender(String currentUserId) {
    return senderId == currentUserId;
  }
  
  /// Check if the current user is the receiver of this capsule
  /// 
  /// WARNING: This method cannot reliably determine receiver status on the frontend
  /// because recipientId is a recipient record UUID, not a user UUID.
  /// 
  /// For connection-based recipients: recipientId points to a recipient record
  /// that has a linked_user_id field containing the actual user ID.
  /// 
  /// For email-based recipients: recipientId points to a recipient record
  /// that has an email field that must be matched.
  /// 
  /// RECOMMENDATION: Always verify receiver status via backend API endpoints
  /// that have access to the full recipient data and can properly match users.
  /// 
  /// This method is provided for convenience but should be used with caution.
  /// Prefer backend verification for critical operations.
  @Deprecated('Use backend API verification instead. This cannot reliably determine receiver status.')
  bool isCurrentUserReceiver(String currentUserId) {
    // This is intentionally always false to prevent misuse
    // The frontend cannot reliably determine receiver status without recipient data
    return false;
  }
}
```

### 2. Mapper Changes

#### CapsuleMapper

```dart
// Before
receiverId: _safeString(recipientIdValue) ?? '',

// After
recipientId: _safeString(recipientIdValue) ?? '',
```

### 3. Updated Files

All references updated in:
- `frontend/lib/core/models/models.dart` - Core model
- `frontend/lib/core/data/capsule_mapper.dart` - Data mapping
- `frontend/lib/features/capsule/locked_capsule_screen.dart` - Uses helper methods
- `frontend/lib/features/capsule/opened_letter_screen.dart` - Updated references
- `frontend/lib/core/data/api_repositories.dart` - Repository methods
- `frontend/lib/core/data/repositories.dart` - Mock data
- `frontend/lib/core/providers/providers.dart` - Provider logic
- `frontend/lib/features/create_capsule/create_capsule_screen.dart` - Creation flow

---

## Data Flow Diagrams

### Creating a Capsule

```
┌──────────────┐
│   Frontend   │
│  Create Form │
└──────┬───────┘
       │
       │ 1. User selects recipient
       │    (recipient.id from recipients list)
       ↓
┌──────────────────┐
│  DraftCapsule    │
│  recipientId     │ ← recipient.id (UUID)
└──────┬───────────┘
       │
       │ 2. Convert to Capsule
       │    recipientId preserved
       ↓
┌──────────────────┐
│  API Request     │
│  POST /capsules  │
│  recipient_id    │ ← recipientId
└──────┬───────────┘
       │
       │ 3. Backend validates
       ↓
┌──────────────────┐
│   Backend        │
│  - Validates     │
│    recipient_id  │
│  - Creates       │
│    capsule       │
└──────┬───────────┘
       │
       │ 4. Response
       ↓
┌──────────────────┐
│  API Response    │
│  recipient_id     │ ← recipients.id (UUID)
└──────┬───────────┘
       │
       │ 5. Map to model
       ↓
┌──────────────────┐
│  Capsule Model   │
│  recipientId     │ ← recipient_id
└──────────────────┘
```

### Checking Receiver Status

```
┌──────────────────┐
│   Frontend       │
│  Need to check   │
│  if user is      │
│  receiver?       │
└──────┬───────────┘
       │
       │ ❌ CANNOT check on frontend
       │    recipientId != userId
       │
       │ ✅ MUST use backend API
       ↓
┌──────────────────┐
│  API Request     │
│  POST /track-view│
│  (or similar)    │
└──────┬───────────┘
       │
       │ Backend has full context:
       │ - recipient.email
       │ - recipient.linked_user_id
       │ - user.email
       │ - user.id
       ↓
┌──────────────────┐
│   Backend        │
│  Verification:   │
│                  │
│  Email-based:    │
│    recipient.email == user.email
│                  │
│  Connection:     │
│    recipient.linked_user_id == user.id
└──────┬───────────┘
       │
       │ Response: success/failure
       ↓
┌──────────────────┐
│  Frontend         │
│  Uses response    │
│  to determine     │
│  receiver status  │
└──────────────────┘
```

---

## Best Practices Guide

### ✅ DO: Use Helper Methods

```dart
// Check if current user is sender
final userAsync = ref.read(currentUserProvider);
final currentUserId = userAsync.asData?.value?.id ?? '';

if (capsule.isCurrentUserSender(currentUserId)) {
  // Sender-specific logic
  // This is safe and reliable
}
```

### ✅ DO: Use Backend Verification for Receiver Checks

```dart
// Always verify receiver status via backend API
// Backend has access to full recipient data and can properly match users

// Example: Tracking receiver view
if (!isSender && !_hasTrackedView && capsule.isLocked) {
  await apiClient.post(
    ApiConfig.trackCapsuleView(capsule.id),
    {},
  );
  // Backend will verify if current user is recipient
  // Returns success only if user is actually the recipient
}
```

### ❌ DON'T: Try to Check Receiver Status on Frontend

```dart
// ❌ WRONG - This doesn't work for connection-based recipients!
if (capsule.recipientId == currentUserId) {
  // This will always fail because:
  // - recipientId is a recipient UUID (from recipients table)
  // - currentUserId is a user UUID (from auth.users)
  // - They are different types of IDs
}

// ❌ WRONG - Cannot determine receiver status without recipient data
if (capsule.isCurrentUserReceiver(currentUserId)) {
  // This method is deprecated and always returns false
  // It exists only to prevent accidental misuse
}
```

### ✅ DO: Understand the Data Model

```dart
// recipientId is a recipient record UUID
final recipientId = capsule.recipientId;

// To find the actual user for connection-based recipients:
// 1. Fetch recipient data from backend
// 2. Check recipient.linked_user_id
// 3. Compare with currentUserId

// For email-based recipients:
// 1. Fetch recipient data from backend
// 2. Check recipient.email
// 3. Compare with current user's email
```

### ✅ DO: Use Backend Endpoints for Receiver Operations

```dart
// All receiver verification should go through backend:

// 1. Track receiver view
await apiClient.post('/capsules/${id}/track-view');

// 2. Open capsule (only recipients can open)
await apiClient.post('/capsules/${id}/open');

// 3. Get receiver-specific data
await apiClient.get('/capsules/${id}'); // Backend filters by receiver status
```

---

## Migration Guide

### For Existing Code

All existing code has been migrated. If you encounter old code:

#### Step 1: Rename Field

```dart
// Before
capsule.receiverId

// After
capsule.recipientId
```

#### Step 2: Update Sender Checks

```dart
// Before
if (capsule.senderId == currentUserId) { ... }

// After (preferred)
if (capsule.isCurrentUserSender(currentUserId)) { ... }
```

#### Step 3: Update Receiver Checks

```dart
// Before (WRONG - never worked correctly)
if (capsule.receiverId == currentUserId) { ... }

// After (CORRECT - use backend verification)
await apiClient.post('/capsules/${id}/track-view');
// Backend verifies receiver status
```

### For New Features

When adding new features that need to check receiver status:

1. **Never** compare `capsule.recipientId == currentUserId`
2. **Always** use backend API endpoints that verify receiver status
3. **Use** `capsule.isCurrentUserSender()` for sender checks
4. **Document** why backend verification is required

---

## API Contracts

### Backend API

#### Create Capsule

```http
POST /capsules
Content-Type: application/json

{
  "recipient_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",  // recipients.id UUID
  "title": "Happy Birthday",
  "body_text": "Wishing you a wonderful day!",
  "unlocks_at": "2025-12-31T00:00:00Z"
}
```

#### Get Capsule

```http
GET /capsules/{id}
```

**Response**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "sender_id": "user-uuid-here",
  "recipient_id": "recipient-uuid-here",  // recipients.id, NOT user.id
  "title": "Happy Birthday",
  "status": "sealed",
  "unlocks_at": "2025-12-31T00:00:00Z"
}
```

#### Track Receiver View

```http
POST /capsules/{id}/track-view
```

**Backend Verification**:
- Checks if current user is recipient
- For email-based: `recipient.email == user.email`
- For connection-based: `recipient.linked_user_id == user.id`
- Returns success only if user is actually the recipient

---

## Troubleshooting

### Common Issues

#### Issue: "Why can't I check if user is receiver?"

**Answer**: `recipientId` is a recipient record UUID, not a user UUID. For connection-based recipients, the user ID is in `recipient.linked_user_id`, which isn't available in the `Capsule` model.

**Solution**: Use backend API endpoints that verify receiver status.

#### Issue: "My receiver check always fails"

**Answer**: You're probably comparing `capsule.recipientId == currentUserId`, which doesn't work.

**Solution**: Use backend verification:
```dart
await apiClient.post('/capsules/${id}/track-view');
```

#### Issue: "How do I know if a recipient is connection-based?"

**Answer**: You can't determine this from the `Capsule` model alone. The backend handles both types transparently.

**Solution**: Backend API endpoints handle both types automatically.

### Debugging Tips

1. **Log recipientId**: Check what value `capsule.recipientId` has
2. **Log currentUserId**: Verify the current user's ID
3. **Check Backend Logs**: See how backend verifies receiver status
4. **Use Helper Methods**: `isCurrentUserSender()` is reliable

---

## Future Considerations

### Potential Enhancements

If receiver status checking becomes critical on frontend:

1. **Include Recipient Data in Response**
   ```json
   {
     "capsule": { ... },
     "recipient": {
       "id": "...",
       "linked_user_id": "...",
       "email": "..."
     }
   }
   ```

2. **Add Proper Helper Method**
   ```dart
   bool isCurrentUserReceiver(String currentUserId, Recipient recipient) {
     if (recipient.linkedUserId == currentUserId) return true;
     // Additional checks...
   }
   ```

3. **Cache Recipient Data**
   - Store recipient data in capsule model
   - Enable frontend receiver checks
   - Trade-off: Larger payload, more complexity

### Current Recommendation

**Keep backend verification** - It's:
- ✅ More secure
- ✅ Handles edge cases
- ✅ Single source of truth
- ✅ Simpler frontend code

---

## Related Documentation

- [Capsule Feature](./features/CAPSULE.md) - Capsule viewing and management
- [Recipients Feature](./features/RECIPIENTS.md) - Recipient management
- [Architecture Guide](../architecture/ARCHITECTURE.md) - Overall system architecture
- [Database Schema](../supabase/DATABASE_SCHEMA.md) - Database structure
- [API Reference](../reference/API_REFERENCE.md) - Complete API documentation

---

## Summary

### Key Takeaways

1. **`recipientId` is a recipient record UUID**, not a user UUID
2. **Use `isCurrentUserSender()`** for sender checks
3. **Always use backend verification** for receiver checks
4. **Naming is now consistent** between frontend and backend
5. **Helper methods prevent common mistakes**

### Production Status

✅ **Production-Ready**: All code updated, tested, and documented  
✅ **Backward Compatible**: No breaking changes to API contracts  
✅ **Acquisition-Ready**: Clear documentation for due diligence  
✅ **Maintainable**: Future developers will understand immediately  

---

**Last Updated**: December 2025  
**Maintained By**: Engineering Team  
**Status**: ✅ Production-Ready
