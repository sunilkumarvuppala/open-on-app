# Data Model Guide - Recipients and Users

> **Status**: ✅ Production-Ready | **Version**: 1.0.0 | **Last Updated**: December 2025  
> **Related**: [Frontend Recipient ID Refactor](../frontend/RECIPIENT_ID_REFACTOR.md) | [Database Schema](../supabase/DATABASE_SCHEMA.md)

## Table of Contents

1. [Overview](#overview)
2. [Core Concepts](#core-concepts)
3. [Data Model Relationships](#data-model-relationships)
4. [Recipient Types](#recipient-types)
5. [Capsule Model](#capsule-model)
6. [Common Patterns](#common-patterns)
7. [Best Practices](#best-practices)

---

## Overview

This guide explains the relationship between users, recipients, and capsules in the OpenOn system. Understanding these relationships is critical for working with the codebase.

### Key Distinctions

| Concept | Type | Table | Purpose |
|---------|------|-------|---------|
| **User** | UUID | `auth.users` | Registered user account |
| **User Profile** | UUID | `user_profiles` | Extended user data |
| **Recipient** | UUID | `recipients` | Contact list entry |
| **Capsule** | UUID | `capsules` | Time-locked letter |

---

## Core Concepts

### Users vs Recipients

**Users** (`auth.users`):
- Registered accounts in the system
- Have authentication credentials
- Can send and receive letters
- Identified by `user_id` (UUID)

**Recipients** (`recipients`):
- Contact list entries
- Created by users to organize their contacts
- Can represent:
  - Email-based contacts (may or may not be registered users)
  - Connection-based contacts (registered users you're connected with)
- Identified by `recipient.id` (UUID)

### The Relationship

```
User A creates Recipient B:
  - Recipient B is owned by User A (recipient.owner_id = User A's ID)
  - Recipient B can represent:
    a) An email contact (recipient.email = "john@example.com")
    b) A connected user (recipient.linked_user_id = User C's ID)

User A creates Capsule for Recipient B:
  - capsule.recipient_id = Recipient B's ID (NOT User C's ID!)
  - Backend determines actual receiver by:
    - Email match: recipient.email == user.email
    - Connection match: recipient.linked_user_id == user.id
```

---

## Data Model Relationships

### Entity Relationship Diagram

```
┌─────────────────┐
│   auth.users    │  ← Supabase Auth (managed by Supabase)
│                 │
│  id (UUID)      │
│  email          │
└────────┬────────┘
         │
         │ 1:1
         ↓
┌─────────────────┐
│ user_profiles   │  ← Extended user data
│                 │
│  user_id (FK)   │──→ auth.users.id
│  first_name     │
│  last_name      │
│  username       │
│  avatar_url     │
└─────────────────┘
         │
         │ 1:N (owner)
         ↓
┌─────────────────┐
│   recipients    │  ← Contact list entries
│                 │
│  id (UUID)      │  ← This is recipient_id
│  owner_id (FK)  │──→ auth.users.id (who owns this contact)
│  name           │
│  email          │  ← For email-based recipients
│  linked_user_id │──→ auth.users.id (if connection-based)
│  username       │  ← @username for display
└────────┬────────┘
         │
         │ N:1
         ↓
┌─────────────────┐
│    capsules     │  ← Time-locked letters
│                 │
│  id (UUID)      │
│  sender_id (FK) │──→ auth.users.id
│  recipient_id   │──→ recipients.id (NOT user.id!)
│  title           │
│  body_text       │
│  unlocks_at     │
└─────────────────┘
```

### Key Relationships

1. **User → Recipients**: One user can have many recipients (1:N)
2. **Recipient → User**: Recipient can link to a user via `linked_user_id` (N:1, optional)
3. **Capsule → Recipient**: Capsule references recipient, not user directly (N:1)
4. **Capsule → Sender**: Capsule references sender user directly (N:1)

---

## Recipient Types

### 1. Email-Based Recipients

**Structure**:
```sql
recipients:
  id: UUID
  owner_id: UUID (user who created this contact)
  name: "John Doe"
  email: "john@example.com"  ← Has email
  linked_user_id: NULL       ← No linked user
  username: NULL
```

**Use Case**: User wants to send letter to someone by email, regardless of whether they're registered.

**Capsule Matching**: Backend matches by `recipient.email == user.email`

### 2. Connection-Based Recipients

**Structure**:
```sql
recipients:
  id: UUID
  owner_id: UUID (user who created this contact)
  name: "Jane Smith"
  email: NULL                 ← No email
  linked_user_id: UUID        ← Links to registered user
  username: "@janesmith"      ← From linked user's profile
```

**Use Case**: User is connected with another registered user. Recipient entry created automatically when connection is established.

**Capsule Matching**: Backend matches by `recipient.linked_user_id == user.id`

### 3. Unregistered Recipients

**Structure**:
```sql
recipients:
  id: UUID
  owner_id: UUID
  name: "Someone Special"
  email: NULL
  linked_user_id: NULL
  username: NULL
```

**Use Case**: Letter sent to someone who will receive an invite link. Recipient created when letter is created.

**Capsule Matching**: Via invite link token, not direct matching.

---

## Capsule Model

### Frontend Model

```dart
class Capsule {
  final String id;              // Capsule UUID
  final String senderId;        // User UUID (from auth.users)
  final String recipientId;      // Recipient UUID (from recipients table)
  final String senderName;      // Display name
  final String receiverName;     // Display name
  // ...
}
```

### Important Notes

1. **`senderId`**: Always a user UUID (from `auth.users`)
2. **`recipientId`**: Always a recipient UUID (from `recipients` table), NOT a user UUID
3. **Cannot compare**: `capsule.recipientId == currentUserId` (different types of IDs)

### Helper Methods

```dart
// ✅ Safe and reliable
bool isCurrentUserSender(String currentUserId) {
  return senderId == currentUserId;
}

// ❌ Deprecated - cannot reliably determine on frontend
@Deprecated('Use backend API verification instead.')
bool isCurrentUserReceiver(String currentUserId) {
  return false; // Always false to prevent misuse
}
```

---

## Common Patterns

### Pattern 1: Checking if User is Sender

```dart
// ✅ CORRECT
final isSender = capsule.isCurrentUserSender(currentUserId);
if (isSender) {
  // Sender-specific logic
}
```

### Pattern 2: Checking if User is Receiver

```dart
// ❌ WRONG - Don't do this
if (capsule.recipientId == currentUserId) {
  // This will always fail!
}

// ✅ CORRECT - Use backend verification
await apiClient.post('/capsules/${id}/track-view');
// Backend verifies receiver status and returns success only if user is recipient
```

### Pattern 3: Creating a Capsule

```dart
// User selects recipient from their recipient list
final selectedRecipient = recipients.firstWhere((r) => r.name == "John");

// Create capsule with recipient ID (not user ID)
final capsule = await capsuleRepo.createCapsule(
  recipientId: selectedRecipient.id,  // ✅ Recipient UUID
  title: "Happy Birthday",
  content: "Wishing you a wonderful day!",
  unlockAt: DateTime(2025, 12, 31),
);
```

### Pattern 4: Finding Capsules for a User

```dart
// Inbox: Find capsules where user is receiver
// Backend query:
//   - Email-based: WHERE recipient.email = user.email
//   - Connection-based: WHERE recipient.linked_user_id = user.id

// Outbox: Find capsules where user is sender
// Backend query:
//   WHERE capsule.sender_id = user.id
```

---

## Best Practices

### ✅ DO

1. **Use `isCurrentUserSender()`** for sender checks
2. **Use backend API** for receiver verification
3. **Understand recipient types** when working with capsules
4. **Use recipient IDs** when creating capsules
5. **Document assumptions** about recipient types

### ❌ DON'T

1. **Don't compare** `recipientId == userId` directly
2. **Don't assume** `recipientId` is a user ID
3. **Don't try** to determine receiver status on frontend
4. **Don't mix** recipient IDs and user IDs

### Code Examples

#### ✅ Good: Sender Check

```dart
if (capsule.isCurrentUserSender(currentUserId)) {
  // Safe and reliable
  showWithdrawButton();
}
```

#### ✅ Good: Receiver Verification

```dart
// Track receiver view - backend verifies receiver status
if (!isSender && !hasTrackedView) {
  await apiClient.post('/capsules/${id}/track-view');
  // Backend returns success only if user is recipient
}
```

#### ❌ Bad: Direct Comparison

```dart
// This doesn't work!
if (capsule.recipientId == currentUserId) {
  // Will always fail for connection-based recipients
}
```

---

## Related Documentation

- [Frontend Recipient ID Refactor](../frontend/RECIPIENT_ID_REFACTOR.md) - Complete refactor documentation
- [Database Schema](../supabase/DATABASE_SCHEMA.md) - Database structure
- [Capsule Feature](../frontend/features/CAPSULE.md) - Capsule viewing
- [Recipients Feature](../frontend/features/RECIPIENTS.md) - Recipient management
- [API Reference](../reference/API_REFERENCE.md) - API contracts

---

**Last Updated**: December 2025  
**Maintained By**: Engineering Team  
**Status**: ✅ Production-Ready

