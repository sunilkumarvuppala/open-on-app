# OpenOn Supabase API Specification

Complete REST and RPC API documentation for OpenOn backend.

## Base URL

```
https://[your-project-ref].supabase.co
```

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer [access_token]
```

---

## 🔐 Authentication Endpoints

### Sign Up
```http
POST /auth/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword",
  "data": {
    "full_name": "John Doe"
  }
}
```

### Sign In
```http
POST /auth/v1/token?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

### Sign Out
```http
POST /auth/v1/logout
Authorization: Bearer [access_token]
```

---

## 👤 User Profile Endpoints

### Get Current User Profile
```http
GET /rest/v1/user_profiles?user_id=eq.[user_id]
Authorization: Bearer [access_token]
```

### Update User Profile
```http
PATCH /rest/v1/user_profiles?user_id=eq.[user_id]
Authorization: Bearer [access_token]
Content-Type: application/json

{
  "full_name": "John Doe",
  "avatar_url": "https://...",
  "country": "US",
  "device_token": "fcm-token-here"
}
```

---

## 📇 Recipients Endpoints

### List Recipients
```http
GET /rest/v1/recipients?order=created_at.desc
Authorization: Bearer [access_token]
```

### Get Recipient
```http
GET /rest/v1/recipients?id=eq.[recipient_id]
Authorization: Bearer [access_token]
```

### Create Recipient
```http
POST /rest/v1/recipients
Authorization: Bearer [access_token]
Content-Type: application/json

{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "avatar_url": "https://..."
}
```

### Update Recipient
```http
PATCH /rest/v1/recipients?id=eq.[recipient_id]
Authorization: Bearer [access_token]
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane.doe@example.com"
}
```

### Delete Recipient
```http
DELETE /rest/v1/recipients?id=eq.[recipient_id]
Authorization: Bearer [access_token]
```

---

## 💌 Capsules Endpoints

### Get Inbox (Received Capsules)
```http
GET /rest/v1/inbox_view?order=created_at.desc
Authorization: Bearer [access_token]
```

### Get Outbox (Sent Capsules)
```http
GET /rest/v1/outbox_view?order=created_at.desc
Authorization: Bearer [access_token]
```

### Get Capsule by ID
```http
GET /rest/v1/recipient_safe_capsules_view?id=eq.[capsule_id]
Authorization: Bearer [access_token]
```

### Create Capsule
```http
POST /rest/v1/capsules
Authorization: Bearer [access_token]
Content-Type: application/json

{
  "recipient_id": "recipient-uuid",
  "is_anonymous": false,
  "is_disappearing": false,
  "disappearing_after_open_seconds": null,
  "unlocks_at": "2025-02-01T00:00:00Z",
  "expires_at": null,
  "title": "A Letter for You",
  "body_text": "This is the letter content...",
  "body_rich_text": null,
  "theme_id": "theme-uuid",
  "animation_id": "animation-uuid"
}
```

### Update Capsule (Before Opening)
```http
PATCH /rest/v1/capsules?id=eq.[capsule_id]
Authorization: Bearer [access_token]
Content-Type: application/json

{
  "title": "Updated Title",
  "body_text": "Updated content..."
}
```

### Open Capsule (Mark as Opened)
```http
PATCH /rest/v1/capsules?id=eq.[capsule_id]
Authorization: Bearer [access_token]
Content-Type: application/json

{
  "opened_at": "2025-01-15T12:00:00Z"
}
```

### Delete Capsule (Unopened Only)
```http
DELETE /rest/v1/capsules?id=eq.[capsule_id]
Authorization: Bearer [access_token]
```

### Filter Capsules by Status
```http
GET /rest/v1/inbox_view?status=eq.ready&order=unlocks_at.asc
Authorization: Bearer [access_token]
```

---

## 🎨 Themes Endpoints

### List All Themes
```http
GET /rest/v1/themes?order=name.asc
Authorization: Bearer [access_token]
```

### Get Theme
```http
GET /rest/v1/themes?id=eq.[theme_id]
Authorization: Bearer [access_token]
```

### Filter Premium Themes
```http
GET /rest/v1/themes?premium_only=eq.true
Authorization: Bearer [access_token]
```

---

## ✨ Animations Endpoints

### List All Animations
```http
GET /rest/v1/animations?order=name.asc
Authorization: Bearer [access_token]
```

### Get Animation
```http
GET /rest/v1/animations?id=eq.[animation_id]
Authorization: Bearer [access_token]
```

### Filter Premium Animations
```http
GET /rest/v1/animations?premium_only=eq.true
Authorization: Bearer [access_token]
```

---

## 🔔 Notifications Endpoints

### List Notifications
```http
GET /rest/v1/notifications?order=created_at.desc&delivered=eq.false
Authorization: Bearer [access_token]
```

### Mark Notification as Delivered
```http
PATCH /rest/v1/notifications?id=eq.[notification_id]
Authorization: Bearer [access_token]
Content-Type: application/json

{
  "delivered": true
}
```

### Delete Notification
```http
DELETE /rest/v1/notifications?id=eq.[notification_id]
Authorization: Bearer [access_token]
```

---

## 💳 Subscriptions Endpoints

### Get User Subscriptions
```http
GET /rest/v1/user_subscriptions?user_id=eq.[user_id]&order=created_at.desc
Authorization: Bearer [access_token]
```

### Get Active Subscription
```http
GET /rest/v1/user_subscriptions?user_id=eq.[user_id]&status=eq.active
Authorization: Bearer [access_token]
```

---

## 📦 Storage Endpoints

### Upload Avatar
```http
POST /storage/v1/object/avatars/{user_id}/avatar.jpg
Authorization: Bearer [access_token]
Content-Type: image/jpeg

[binary data]
```

### Upload Capsule Asset
```http
POST /storage/v1/object/capsule_assets/{user_id}/{capsule_id}/image.jpg
Authorization: Bearer [access_token]
Content-Type: image/jpeg

[binary data]
```

### Get Public URL
```http
GET /storage/v1/object/public/avatars/{user_id}/avatar.jpg
```

### Get Signed URL (Private)
```http
POST /storage/v1/object/sign/capsule_assets/{user_id}/{capsule_id}/image.jpg
Authorization: Bearer [access_token]
Content-Type: application/json

{
  "expiresIn": 3600
}
```

---

## 🔍 RPC Functions

### Get Inbox Count
```http
POST /rest/v1/rpc/get_inbox_count
Authorization: Bearer [access_token]
Content-Type: application/json

{}
```

### Get Outbox Count
```http
POST /rest/v1/rpc/get_outbox_count
Authorization: Bearer [access_token]
Content-Type: application/json

{}
```

### Get Unread Notifications Count
```http
POST /rest/v1/rpc/get_unread_notifications_count
Authorization: Bearer [access_token]
Content-Type: application/json

{}
```

---

## 📊 PostgREST Query Operators

### Filtering
- `eq` - equals
- `neq` - not equals
- `gt` - greater than
- `gte` - greater than or equal
- `lt` - less than
- `lte` - less than or equal
- `like` - pattern match
- `ilike` - case-insensitive pattern match
- `is` - null check
- `in` - in array

### Examples
```http
# Get capsules that unlock in the next 24 hours
GET /rest/v1/capsules?unlocks_at=gte.[now]&unlocks_at=lte.[now+24h]

# Get capsules with specific statuses
GET /rest/v1/capsules?status=in.(ready,opened)

# Search recipients by name
GET /rest/v1/recipients?name=ilike.*jane*
```

---

## 🚨 Error Responses

### 400 Bad Request
```json
{
  "message": "Validation error",
  "details": "..."
}
```

### 401 Unauthorized
```json
{
  "message": "JWT expired"
}
```

### 403 Forbidden
```json
{
  "message": "new row violates row-level security policy"
}
```

### 404 Not Found
```json
{
  "message": "Could not find resource"
}
```

### 500 Internal Server Error
```json
{
  "message": "Internal server error"
}
```

---

## 📝 Notes

1. All timestamps are in UTC (ISO 8601 format)
2. All UUIDs are in standard format
3. Use PostgREST query syntax for filtering, sorting, and pagination
4. RLS policies automatically filter results based on authenticated user
5. Anonymous capsules hide sender information in recipient views
6. Disappearing messages are automatically deleted after the specified time

