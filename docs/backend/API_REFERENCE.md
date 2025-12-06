# Backend API Reference

Complete API endpoint documentation for the OpenOn backend, matching Supabase schema.

## 📋 Base URL

```
Development: http://localhost:8000
Production: https://api.openon.com
```

## 🔐 Authentication

**Important**: User signup and login are handled by Supabase Auth. This backend only provides profile management endpoints.

All endpoints require authentication via Supabase JWT Bearer token.

### Headers

```http
Authorization: Bearer <supabase_jwt_token>
Content-Type: application/json
```

### Getting a Token

1. User signs up/logs in via Supabase Auth (frontend)
2. Supabase returns JWT token
3. Include token in `Authorization` header for all API requests

## 📚 Table of Contents

1. [Authentication & Profile](#authentication--profile-endpoints)
2. [Capsules](#capsules-endpoints)
3. [Recipients](#recipients-endpoints)
4. [Error Handling](#error-handling)

---

## Authentication & Profile Endpoints

### GET /auth/me

Get current authenticated user profile information.

**Headers:**
```http
Authorization: Bearer <supabase_jwt_token>
```

**Response (200):**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "full_name": "Alice Johnson",
  "avatar_url": "https://example.com/avatar.jpg",
  "premium_status": false,
  "premium_until": null,
  "is_admin": false,
  "country": "US",
  "device_token": null,
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### PUT /auth/me

Update current user profile.

**Request Body:**
```json
{
  "full_name": "Alice Smith",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "country": "CA",
  "device_token": "fcm-token-here"
}
```

**Response (200):**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "full_name": "Alice Smith",
  "avatar_url": "https://example.com/new-avatar.jpg",
  ...
}
```

**Note**: All fields are optional. Only provided fields will be updated.

**Example:**
```bash
curl -X PUT "http://localhost:8000/auth/me" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "full_name": "Alice Smith",
    "country": "CA"
  }'
```

---

## Capsules Endpoints

### POST /capsules

Create a new capsule (in sealed status with unlock time).

**Request Body:**
```json
{
  "recipient_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Capsule Title",
  "body_text": "Capsule content...",
  "body_rich_text": null,
  "is_anonymous": false,
  "is_disappearing": false,
  "disappearing_after_open_seconds": null,
  "unlocks_at": "2026-01-01T00:00:00Z",
  "expires_at": null,
  "theme_id": "550e8400-e29b-41d4-a716-446655440001",
  "animation_id": "550e8400-e29b-41d4-a716-446655440002"
}
```

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "sender_id": "your-user-id",
  "recipient_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Capsule Title",
  "body_text": "Capsule content...",
  "body_rich_text": null,
  "is_anonymous": false,
  "is_disappearing": false,
  "disappearing_after_open_seconds": null,
  "status": "sealed",
  "unlocks_at": "2026-01-01T00:00:00Z",
  "opened_at": null,
  "deleted_at": null,
  "expires_at": null,
  "theme_id": "550e8400-e29b-41d4-a716-446655440001",
  "animation_id": "550e8400-e29b-41d4-a716-446655440002",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Validation:**
- `recipient_id`: Required, must be a valid UUID of a recipient owned by current user
- `unlocks_at`: Required, must be in the future
- Either `body_text` OR `body_rich_text` is required (not both empty)
- If `is_disappearing` is true, `disappearing_after_open_seconds` is required

**Example:**
```bash
curl -X POST "http://localhost:8000/capsules" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "recipient_id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "My First Capsule",
    "body_text": "This is a time capsule!",
    "unlocks_at": "2026-01-01T00:00:00Z"
  }'
```

### GET /capsules

List capsules for the current user.

**Query Parameters:**
- `box` (optional): "inbox" or "outbox" (default: "inbox")
- `status` (optional): Filter by status (sealed, ready, opened, expired)
- `page` (optional): Page number (default: 1, min: 1)
- `page_size` (optional): Items per page (default: 20, min: 1, max: 100)

**Response (200):**
```json
{
  "capsules": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "sender_id": "sender-id",
      "recipient_id": "recipient-id",
      "title": "Capsule Title",
      "body_text": "Capsule content...",
      "status": "ready",
      "unlocks_at": "2026-01-01T00:00:00Z",
      "opened_at": null,
      ...
    }
  ],
  "total": 10,
  "page": 1,
  "page_size": 20
}
```

**Note**: 
- `inbox`: Shows capsules where current user owns the recipient
- `outbox`: Shows capsules sent by current user

**Example:**
```bash
# Get inbox capsules
curl -X GET "http://localhost:8000/capsules?box=inbox" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"

# Get ready capsules only
curl -X GET "http://localhost:8000/capsules?box=inbox&status=ready" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### GET /capsules/{capsule_id}

Get details of a specific capsule.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "sender_id": "sender-id",
  "recipient_id": "recipient-id",
  "title": "Capsule Title",
  "body_text": "Capsule content...",
  "status": "ready",
  "unlocks_at": "2026-01-01T00:00:00Z",
  "opened_at": null,
  ...
}
```

**Permissions:**
- Sender: Can always view
- Recipient owner: Can view if status is `ready` or `opened`
- Anonymous capsules: Sender info hidden from recipient

**Example:**
```bash
curl -X GET "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### PUT /capsules/{capsule_id}

Update a capsule (only before opening).

**Request Body:**
```json
{
  "title": "Updated Title",
  "body_text": "Updated content...",
  "body_rich_text": null,
  "is_anonymous": true,
  "is_disappearing": true,
  "disappearing_after_open_seconds": 3600,
  "theme_id": "new-theme-id",
  "animation_id": "new-animation-id",
  "expires_at": "2027-01-01T00:00:00Z"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "title": "Updated Title",
  ...
}
```

**Note**: 
- Only sender can edit
- Cannot edit if status is `opened` or `expired`
- `unlocks_at` cannot be changed after creation
- All fields are optional (partial update)

**Example:**
```bash
curl -X PUT "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "title": "Updated Title",
    "body_text": "Updated content..."
  }'
```

### POST /capsules/{capsule_id}/open

Open a ready capsule (recipient owner only).

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "status": "opened",
  "opened_at": "2025-01-15T10:40:00Z",
  ...
}
```

**Requirements:**
- Must be the recipient owner (user who owns the recipient)
- Capsule must be in `ready` status
- Action is irreversible
- For disappearing messages, `deleted_at` is automatically set

**Example:**
```bash
curl -X POST "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003/open" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### DELETE /capsules/{capsule_id}

Soft delete a capsule (for disappearing messages or sender deletion).

**Response (200):**
```json
{
  "message": "Capsule deleted successfully"
}
```

**Note**: 
- Only sender can delete
- Sets `deleted_at` timestamp (soft delete)
- Capsule is filtered out from queries

**Example:**
```bash
curl -X DELETE "http://localhost:8000/capsules/550e8400-e29b-41d4-a716-446655440003" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

---

## Recipients Endpoints

### POST /recipients

Add a new recipient to saved contacts.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://example.com/avatar.jpg",
  "relationship": "friend"
}
```

**Response (201):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "owner_id": "your-user-id",
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://example.com/avatar.jpg",
  "relationship": "friend",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Validation:**
- `name`: Required, 1-255 characters
- `email`: Optional, validated if provided
- `avatar_url`: Optional
- `relationship`: Optional, defaults to "friend" (friend, family, partner, colleague, acquaintance, other)

**Example:**
```bash
curl -X POST "http://localhost:8000/recipients" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "relationship": "friend"
  }'
```

### GET /recipients

List all recipients for the current user.

**Query Parameters:**
- `page` (optional): Page number (default: 1, min: 1)
- `page_size` (optional): Items per page (default: 20, min: 1, max: 100)

**Response (200):**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440004",
    "owner_id": "your-user-id",
    "name": "John Doe",
    "email": "john@example.com",
    "avatar_url": "https://example.com/avatar.jpg",
    "relationship": "friend",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z"
  }
]
```

**Example:**
```bash
curl -X GET "http://localhost:8000/recipients" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### GET /recipients/{recipient_id}

Get details of a specific recipient.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "owner_id": "your-user-id",
  "name": "John Doe",
  "email": "john@example.com",
  "avatar_url": "https://example.com/avatar.jpg",
  "relationship": "friend",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/recipients/550e8400-e29b-41d4-a716-446655440004" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

### PUT /recipients/{recipient_id}

Update a recipient.

**Request Body:**
```json
{
  "name": "John Smith",
  "email": "john.smith@example.com",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "relationship": "family"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "name": "John Smith",
  ...
}
```

**Note**: All fields are optional. Only provided fields will be updated.

**Example:**
```bash
curl -X PUT "http://localhost:8000/recipients/550e8400-e29b-41d4-a716-446655440004" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN" \
  -d '{
    "name": "John Smith",
    "relationship": "family"
  }'
```

### DELETE /recipients/{recipient_id}

Delete a recipient.

**Response (200):**
```json
{
  "message": "Recipient deleted successfully"
}
```

**Example:**
```bash
curl -X DELETE "http://localhost:8000/recipients/550e8400-e29b-41d4-a716-446655440004" \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT_TOKEN"
```

---

## Error Handling

### Error Response Format

All errors follow this format:

```json
{
  "detail": "Error message describing what went wrong"
}
```

### HTTP Status Codes

- `200 OK`: Successful request
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication token
- `403 Forbidden`: Authenticated but not authorized
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

### Common Error Scenarios

#### 401 Unauthorized

```json
{
  "detail": "Invalid authentication credentials"
}
```

**Cause**: Missing or invalid Supabase JWT token.

**Solution**: Ensure token is included in `Authorization` header and is valid.

#### 403 Forbidden

```json
{
  "detail": "You don't have permission to view this capsule"
}
```

**Cause**: User doesn't have permission to access the resource.

**Solution**: Ensure user owns the resource or has appropriate permissions.

#### 404 Not Found

```json
{
  "detail": "Capsule not found"
}
```

**Cause**: Resource doesn't exist or user doesn't have access.

**Solution**: Verify resource ID and user permissions.

#### 400 Bad Request

```json
{
  "detail": "Either body_text or body_rich_text is required"
}
```

**Cause**: Invalid request data or validation failure.

**Solution**: Check request body against API documentation.

---

## Status Values

### Capsule Status

- `sealed`: Capsule created with unlock time set (can be edited)
- `ready`: Unlock time has passed, recipient can open
- `opened`: Recipient has opened the capsule (terminal state)
- `expired`: Soft-deleted or expired (disappearing messages)

### Relationship Types

- `friend`: Friend relationship (default)
- `family`: Family member
- `partner`: Romantic partner
- `colleague`: Work colleague
- `acquaintance`: Acquaintance
- `other`: Other relationship

---

## Notes

1. **Authentication**: Signup and login are handled by Supabase Auth. This backend only provides profile management.

2. **Drafts**: Drafts feature has been removed. Capsules are created directly in 'sealed' status with `unlocks_at` set.

3. **UUIDs**: All IDs are UUIDs (not strings).

4. **Timezones**: All timestamps are in UTC and timezone-aware.

5. **Anonymous Capsules**: When `is_anonymous` is true, sender info is hidden from recipient via Supabase views.

6. **Disappearing Messages**: When `is_disappearing` is true, capsule is soft-deleted after opening (via Supabase triggers).

---

**Last Updated**: 2025-01-XX (Post Supabase Migration)
