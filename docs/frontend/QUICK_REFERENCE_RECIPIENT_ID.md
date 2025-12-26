# Recipient ID Quick Reference

> **Quick reference for working with recipient IDs and user IDs**  
> For complete documentation, see [RECIPIENT_ID_REFACTOR.md](./RECIPIENT_ID_REFACTOR.md)

## Key Concepts

| Field | Type | Source | What It Is |
|-------|------|--------|-----------|
| `senderId` | UUID | `auth.users.id` | User ID of sender ✅ |
| `recipientId` | UUID | `recipients.id` | Recipient record ID ⚠️ |
| `currentUserId` | UUID | `auth.users.id` | Current user's ID ✅ |

**⚠️ Important**: `recipientId` is NOT a user ID. It's a recipient record UUID.

## Quick Patterns

### ✅ Check if User is Sender

```dart
if (capsule.isCurrentUserSender(currentUserId)) {
  // Safe and reliable
}
```

### ✅ Check if User is Receiver

```dart
// Always use backend verification
await apiClient.post('/capsules/${id}/track-view');
// Backend verifies receiver status
```

### ❌ Don't Do This

```dart
// ❌ WRONG - This doesn't work!
if (capsule.recipientId == currentUserId) {
  // Will always fail for connection-based recipients
}
```

## Common Scenarios

### Creating a Capsule

```dart
// User selects recipient from list
final recipient = recipients.firstWhere((r) => r.name == "John");

// Create capsule with recipient ID
await capsuleRepo.createCapsule(
  recipientId: recipient.id,  // ✅ Recipient UUID
  // ...
);
```

### Finding User's Capsules

```dart
// Inbox: Backend handles receiver matching
final inbox = await capsuleRepo.getCapsules(
  userId: currentUserId,
  asSender: false,  // Backend verifies receiver status
);

// Outbox: Simple sender check
final outbox = await capsuleRepo.getCapsules(
  userId: currentUserId,
  asSender: true,  // capsule.sender_id == currentUserId
);
```

## Why Backend Verification?

**Frontend cannot reliably determine receiver status** because:
- `recipientId` is a recipient record UUID, not user UUID
- For connection-based recipients: user ID is in `recipient.linked_user_id` (not in capsule)
- For email-based recipients: need to match `recipient.email == user.email` (not in capsule)

**Backend has full context**:
- Access to recipient record with `linked_user_id` and `email`
- Can properly match users for both recipient types

## Related Documentation

- [Complete Refactor Documentation](./RECIPIENT_ID_REFACTOR.md) - Full details
- [Data Model Guide](../architecture/DATA_MODEL_GUIDE.md) - Complete data relationships
- [Capsule Feature](./features/CAPSULE.md) - Capsule viewing
- [Recipients Feature](./features/RECIPIENTS.md) - Recipient management

---

**Last Updated**: December 2025

