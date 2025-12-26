# Letter Invites Feature - Documentation Summary

> **Quick Reference Guide**  
> Last Updated: January 2025  
> Status: ✅ Production Ready & Acquisition Ready

---

## 📚 Complete Documentation

**Main Feature Documentation**: [LETTER_INVITES.md](./LETTER_INVITES.md) - Complete feature documentation with all details

**Related Documentation**:
- [Backend API Reference](../backend/API_REFERENCE.md#letter-invites-endpoints-new) - API endpoints
- [Database Schema](../supabase/DATABASE_SCHEMA.md#letter_invites--new) - Database table and RPC functions
- [Features List](../reference/FEATURES_LIST.md#7-letter-invites--new) - Feature checklist

---

## 🎯 Quick Overview

**What it does**: Allows registered users to send letters to unregistered users via private, secure invite links.

**Key Benefits**:
- User acquisition mechanism
- Privacy-preserving (no sender identity exposed)
- Seamless onboarding (signup → immediate letter access)
- Automatic connection creation

**Product Principle**: "The letter is the invitation" - Recipients feel curiosity, not marketing pressure.

---

## 🔑 Key Components

### Frontend
- `step_choose_recipient.dart` - Recipient selection with "Invite with a letter" option
- `create_capsule_screen.dart` - Post-creation invite share dialog
- `locked_capsule_screen.dart` - "Share Invite Link" button
- `signup_screen.dart` - Invite claiming on signup

### Backend
- `capsules.py` - Letter creation with invite generation
- `letter_invites.py` - Invite management endpoints
- `repositories.py` - LetterInviteRepository

### Database
- `letter_invites` table - Stores invite tokens and claim status
- `rpc_get_letter_invite_public()` - Public preview (no auth)
- `rpc_claim_letter_invite()` - Claim invite on signup

---

## 🔄 User Flows

### Sender Flow
1. Create letter → Select "Invite with a letter"
2. Complete letter creation
3. Share invite link (shown after creation)
4. Recipient receives link

### Receiver Flow
1. Open invite link → See preview (no auth required)
2. See countdown (if before open time)
3. At open time → "Create account to unlock"
4. Sign up → Invite automatically claimed
5. Navigate to letter → Letter unlocks immediately

---

## 🔒 Security

- **Token Generation**: `secrets.token_urlsafe(32)` (cryptographically secure)
- **Token Validation**: 32+ characters, base64url safe
- **Single Claim**: First user to claim wins (atomic operation)
- **Privacy**: No sender identity or letter content in preview
- **RLS**: Database-level security policies

---

## ⚙️ Configuration

**Backend Environment Variable**:
```bash
export INVITE_BASE_URL="https://openon.app/invite"
```

**Default**: `https://openon.app/invite` (can be overridden)

---

## 📊 Database Schema

**Table**: `letter_invites`
- `id` (UUID, PK)
- `letter_id` (UUID, FK → capsules)
- `invite_token` (TEXT, UNIQUE, 32+ chars)
- `created_at` (TIMESTAMPTZ)
- `claimed_at` (TIMESTAMPTZ, nullable)
- `claimed_user_id` (UUID, nullable)

**Indexes**:
- `invite_token` (partial: unclaimed only)
- `letter_id`
- `claimed_user_id` (partial: claimed only)

---

## 🚀 API Endpoints

### Create Invite
```
POST /letter-invites/letters/{letter_id}
```

### Get Preview (Public)
```
GET /letter-invites/preview/{invite_token}
```

### Claim Invite
```
POST /letter-invites/claim/{invite_token}
```

---

## ✅ Production Checklist

- [x] Database migration applied
- [x] Environment variable configured
- [x] Backend endpoints implemented
- [x] Frontend UI implemented
- [x] Security measures in place
- [x] Error handling comprehensive
- [x] Performance optimized
- [x] Documentation complete

---

## 🔗 Related Features

- **Countdown Shares**: Similar sharing mechanism (different use case)
- **Connections**: Automatic connection creation on claim
- **Anonymous Letters**: Works with anonymous letters
- **Letters to Self**: Not applicable (self-recipients only)

---

**For complete details, see [LETTER_INVITES.md](./LETTER_INVITES.md)**

