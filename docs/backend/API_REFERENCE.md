# Backend API Reference

Complete API endpoint documentation for the OpenOn backend.

## 📋 Base URL

```
Development: http://localhost:8000
Production: https://api.openon.com
```

## 🔐 Authentication

All endpoints (except signup and login) require authentication via JWT Bearer token.

### Headers

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

## 📚 Table of Contents

1. [Authentication](#authentication-endpoints)
2. [Capsules](#capsules-endpoints)
3. [Drafts](#drafts-endpoints)
4. [Recipients](#recipients-endpoints)
5. [User Search](#user-search)
6. [Error Handling](#error-handling)

---

## Authentication Endpoints

### POST /auth/signup

Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "SecurePass123",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response (201):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Validation:**
- Email: Valid email format, unique
- Username: 3-100 characters, alphanumeric + underscore/hyphen, unique
- Password: 8-128 characters
- First Name: 1-100 characters
- Last Name: 1-100 characters

**Example:**
```bash
curl -X POST "http://localhost:8000/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "username": "alice",
    "password": "SecurePass123",
    "first_name": "Alice",
    "last_name": "Johnson"
  }'
```

### POST /auth/login

Authenticate user and get tokens.

**Request Body:**
```json
{
  "username": "username",
  "password": "password"
}
```

**Note**: Can use either `username` or `email` for login.

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Example:**
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "password": "SecurePass123"
  }'
```

### GET /auth/me

Get current authenticated user information.

**Headers:**
```http
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "alice@example.com",
  "username": "alice",
  "first_name": "Alice",
  "last_name": "Johnson",
  "full_name": "Alice Johnson",
  "is_active": true,
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### GET /auth/username/check

Check if a username is available (for real-time validation).

**Query Parameters:**
- `username` (required): Username to check (3-100 characters)

**Response (200):**
```json
{
  "available": true,
  "message": "Username is available"
}
```

**When username is taken:**
```json
{
  "available": false,
  "message": "Username already taken"
}
```

**When username format is invalid:**
```json
{
  "available": false,
  "message": "Username validation error message"
}
```

**Example:**
```bash
curl -X GET "http://localhost:8000/auth/username/check?username=alice"
```

### GET /auth/users/search

Search for registered users (for adding recipients).

**Query Parameters:**
- `query` (required): Search query (min 2 characters)
- `limit` (optional): Maximum results (default: 10, max: 50)

**Headers:**
```http
Authorization: Bearer <access_token>
```

**Response (200):**
```json
[
  {
    "id": "user-id-1",
    "email": "user1@example.com",
    "username": "user1",
    "first_name": "User",
    "last_name": "One",
    "full_name": "User One",
    "is_active": true,
    "created_at": "2025-01-15T10:30:00Z"
  }
]
```

**Example:**
```bash
curl -X GET "http://localhost:8000/auth/users/search?query=alice&limit=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## Capsules Endpoints

### POST /capsules

Create a new capsule (initially in draft state).

**Request Body:**
```json
{
  "receiver_id": "user-id",
  "title": "Capsule Title",
  "body": "Capsule content...",
  "media_urls": ["https://example.com/image.jpg"],
  "theme": "birthday",
  "allow_early_view": false,
  "allow_receiver_reply": true
}
```

**Response (201):**
```json
{
  "id": "capsule-id",
  "sender_id": "your-user-id",
  "receiver_id": "receiver-user-id",
  "title": "Capsule Title",
  "body": "Capsule content...",
  "media_urls": ["https://example.com/image.jpg"],
  "theme": "birthday",
  "state": "draft",
  "created_at": "2025-01-15T10:30:00Z",
  "sealed_at": null,
  "scheduled_unlock_at": null,
  "opened_at": null,
  "allow_early_view": false,
  "allow_receiver_reply": true
}
```

**Example:**
```bash
curl -X POST "http://localhost:8000/capsules" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "receiver_id": "receiver-id",
    "title": "My First Capsule",
    "body": "This is a time capsule!",
    "theme": "birthday"
  }'
```

### GET /capsules

List capsules for the current user.

**Query Parameters:**
- `box` (optional): "inbox" or "outbox" (default: "inbox")
- `state` (optional): Filter by state (draft, sealed, unfolding, ready, opened)
- `page` (optional): Page number (default: 1, min: 1)
- `page_size` (optional): Items per page (default: 20, min: 1, max: 100)

**Response (200):**
```json
{
  "capsules": [
    {
      "id": "capsule-id",
      "sender_id": "sender-id",
      "receiver_id": "receiver-id",
      "title": "Capsule Title",
      "body": "Capsule content...",
      "state": "ready",
      "scheduled_unlock_at": "2026-01-01T00:00:00Z",
      ...
    }
  ],
  "total": 10,
  "page": 1,
  "page_size": 20
}
```

**Example:**
```bash
# Get inbox capsules
curl -X GET "http://localhost:8000/capsules?box=inbox" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Get ready capsules only
curl -X GET "http://localhost:8000/capsules?box=inbox&state=ready" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### GET /capsules/{capsule_id}

Get details of a specific capsule.

**Response (200):**
```json
{
  "id": "capsule-id",
  "sender_id": "sender-id",
  "receiver_id": "receiver-id",
  "title": "Capsule Title",
  "body": "Capsule content...",
  "state": "ready",
  "scheduled_unlock_at": "2026-01-01T00:00:00Z",
  ...
}
```

**Permissions:**
- Sender: Can always view
- Receiver: Can view if `opened` or if `allow_early_view` is true and state is `unfolding`/`ready`

**Example:**
```bash
curl -X GET "http://localhost:8000/capsules/capsule-id" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### PUT /capsules/{capsule_id}

Update a capsule (only works for drafts).

**Request Body:**
```json
{
  "title": "Updated Title",
  "body": "Updated content...",
  "media_urls": ["https://example.com/new-image.jpg"],
  "theme": "anniversary",
  "receiver_id": "new-receiver-id",
  "allow_early_view": true,
  "allow_receiver_reply": false
}
```

**Response (200):**
```json
{
  "id": "capsule-id",
  "title": "Updated Title",
  "body": "Updated content...",
  ...
}
```

**Note**: Only sender can edit, and only if capsule is in `draft` state.

**Example:**
```bash
curl -X PUT "http://localhost:8000/capsules/capsule-id" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "title": "Updated Title",
    "body": "Updated content..."
  }'
```

### POST /capsules/{capsule_id}/seal

Seal a capsule and set unlock time.

**Request Body:**
```json
{
  "scheduled_unlock_at": "2026-01-01T00:00:00Z"
}
```

**Response (200):**
```json
{
  "id": "capsule-id",
  "state": "sealed",
  "sealed_at": "2025-01-15T10:35:00Z",
  "scheduled_unlock_at": "2026-01-01T00:00:00Z",
  ...
}
```

**Validation:**
- Unlock time must be at least 1 minute in the future
- Unlock time cannot be more than 5 years in the future
- Capsule must be in `draft` state

**⚠️ Important**: After sealing, capsule cannot be edited or cancelled.

**Example:**
```bash
curl -X POST "http://localhost:8000/capsules/capsule-id/seal" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "scheduled_unlock_at": "2026-01-01T00:00:00Z"
  }'
```

### POST /capsules/{capsule_id}/open

Open a ready capsule (receiver only).

**Response (200):**
```json
{
  "id": "capsule-id",
  "state": "opened",
  "opened_at": "2025-01-15T10:40:00Z",
  ...
}
```

**Requirements:**
- Must be the receiver
- Capsule must be in `ready` state
- Action is irreversible

**Example:**
```bash
curl -X POST "http://localhost:8000/capsules/capsule-id/open" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### DELETE /capsules/{capsule_id}

Delete a capsule (only drafts).

**Response (200):**
```json
{
  "message": "Capsule deleted successfully"
}
```

**Note**: Only sender can delete, and only if capsule is in `draft` state.

**Example:**
```bash
curl -X DELETE "http://localhost:8000/capsules/capsule-id" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## Drafts Endpoints

### POST /drafts

Create a new draft.

**Request Body:**
```json
{
  "title": "Draft Title",
  "body": "Draft content...",
  "recipient_id": "recipient-id"
}
```

**Response (201):**
```json
{
  "id": "draft-id",
  "owner_id": "your-user-id",
  "title": "Draft Title",
  "body": "Draft content...",
  "recipient_id": "recipient-id",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

### GET /drafts

List all drafts for the current user.

**Query Parameters:**
- `page` (optional): Page number (default: 1, min: 1)
- `page_size` (optional): Items per page (default: 50, min: 1, max: 100)

**Response (200):**
```json
[
  {
    "id": "draft-id",
    "title": "Draft Title",
    "body": "Draft content...",
    ...
  }
]
```

### GET /drafts/{draft_id}

Get a specific draft.

**Response (200):**
```json
{
  "id": "draft-id",
  "title": "Draft Title",
  "body": "Draft content...",
  ...
}
```

### PUT /drafts/{draft_id}

Update a draft.

**Request Body:**
```json
{
  "title": "Updated Title",
  "body": "Updated content...",
  "recipient_id": "new-recipient-id"
}
```

### DELETE /drafts/{draft_id}

Delete a draft.

**Response (200):**
```json
{
  "message": "Draft deleted successfully"
}
```

---

## Recipients Endpoints

### POST /recipients

Add a recipient.

**Request Body:**
```json
{
  "name": "Recipient Name",
  "email": "recipient@example.com",
  "user_id": "user-id"
}
```

**Response (201):**
```json
{
  "id": "recipient-id",
  "owner_id": "your-user-id",
  "name": "Recipient Name",
  "email": "recipient@example.com",
  "user_id": "user-id",
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Note**: `user_id` is optional - use when recipient is a registered user.

### GET /recipients

List all recipients for the current user.

**Response (200):**
```json
[
  {
    "id": "recipient-id",
    "name": "Recipient Name",
    "email": "recipient@example.com",
    "user_id": "user-id",
    ...
  }
]
```

### GET /recipients/{recipient_id}

Get a specific recipient.

**Response (200):**
```json
{
  "id": "recipient-id",
  "name": "Recipient Name",
  "email": "recipient@example.com",
  ...
}
```

### DELETE /recipients/{recipient_id}

Delete a recipient.

**Response (200):**
```json
{
  "message": "Recipient deleted successfully"
}
```

---

## Error Handling

### HTTP Status Codes

- **200 OK**: Request successful
- **201 Created**: Resource created successfully
- **400 Bad Request**: Invalid input data
- **401 Unauthorized**: Missing or invalid token
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource doesn't exist
- **422 Unprocessable Entity**: Validation error
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server error

### Error Response Format

```json
{
  "detail": "Error message here"
}
```

### Common Errors

#### Validation Error (400)

```json
{
  "detail": "Invalid email format"
}
```

#### Authentication Error (401)

```json
{
  "detail": "Invalid authentication credentials"
}
```

#### Permission Error (403)

```json
{
  "detail": "Cannot edit capsule in sealed state"
}
```

#### Not Found (404)

```json
{
  "detail": "Capsule not found"
}
```

---

## Rate Limiting

- **Default**: 60 requests per minute per IP
- **Configurable**: Via `RATE_LIMIT_PER_MINUTE` environment variable
- **Response**: 429 Too Many Requests when limit exceeded

---

## Interactive Documentation

Visit http://localhost:8000/docs for interactive API documentation with:
- Try-it-out functionality
- Request/response examples
- Schema definitions
- Authentication testing

---

**Last Updated**: 2025

