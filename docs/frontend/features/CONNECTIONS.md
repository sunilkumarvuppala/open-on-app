# Connections Feature Documentation

## Overview

The Connections feature enables users to establish mutual friendships before sending letters. This ensures that letters can only be sent to users who have accepted a connection request, providing a secure and controlled communication system.

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [User Flow](#user-flow)
3. [Architecture](#architecture)
4. [Database Schema](#database-schema)
5. [API Endpoints](#api-endpoints)
6. [Frontend Implementation](#frontend-implementation)
7. [Business Rules](#business-rules)
8. [Security](#security)
9. [State Management](#state-management)
10. [Error Handling](#error-handling)

---

## Feature Overview

### Purpose
The Connections feature allows users to:
- Send connection requests to other users
- Accept or decline incoming connection requests
- View all mutual connections
- Send letters only to connected users

### Key Concepts

**Connection Request**: A pending invitation from one user to another
- Status: `pending`, `accepted`, or `declined`
- Can include an optional message
- Must be accepted by the recipient to establish a connection

**Connection**: A mutual friendship between two users
- Created automatically when a request is accepted
- Bidirectional (both users can see each other)
- Required before sending letters

**Recipient Auto-Creation**: When a connection is accepted, recipient entries are automatically created for both users, allowing them to send letters to each other.

---

## User Flow

### 1. Sending a Connection Request

```
User A → Searches for User B
       → Clicks "Add Connection"
       → Optionally adds a message
       → Sends request
       → Request appears in "Outgoing Requests"
```

**Backend Flow**:
1. Validate user is not sending to themselves
2. Check if already connected
3. Check for existing pending request
4. Check cooldown period (7 days after decline)
5. Check rate limit (max 5 requests per day)
6. Create connection request with status `pending`

### 2. Receiving a Connection Request

```
User B → Receives notification
       → Views request in "Incoming Requests"
       → Accepts or Declines
       → If accepted: Connection created, Recipients auto-created
```

**Backend Flow**:
1. Verify request exists and user is the recipient
2. Verify request status is `pending`
3. If accepted:
   - Create connection record
   - Auto-create recipient entries for both users
   - Update request status to `accepted`
4. If declined:
   - Update request status to `declined`
   - Store optional decline reason

### 3. Viewing Connections

```
User → Opens "People" tab
     → Views "Connections" tab
     → Sees all mutual connections
     → Can send letter to any connection
```

---

## Architecture

### Component Structure

```
Frontend (Flutter)
├── People Screen (Main UI)
│   ├── Connections Tab
│   ├── Requests Tab (Incoming/Outgoing)
│   └── Add Connection FAB
├── Add Connection Screen
│   └── User Search
└── State Management (Riverpod)
    ├── connectionsProvider
    ├── incomingRequestsProvider
    └── outgoingRequestsProvider

Backend (FastAPI)
├── API Routes (connections.py)
│   ├── POST /connections/requests
│   ├── PATCH /connections/requests/{id}
│   ├── GET /connections/requests/incoming
│   ├── GET /connections/requests/outgoing
│   └── GET /connections
├── Service Layer (connection_service.py)
│   ├── check_existing_connection()
│   ├── check_pending_request()
│   ├── check_cooldown()
│   ├── check_rate_limit()
│   └── create_connection()
└── Helpers (connection_helpers.py)
    └── build_connection_request_response()

Database (PostgreSQL)
├── connection_requests (table)
├── connections (table)
└── blocked_users (table)
```

### Data Flow

```
┌─────────────┐
│   Flutter   │
│   Frontend  │
└──────┬──────┘
       │ HTTP/REST
       ▼
┌─────────────┐
│   FastAPI   │
│   Backend   │
└──────┬──────┘
       │ SQL
       ▼
┌─────────────┐
│  PostgreSQL │
│  (Supabase) │
└─────────────┘
```

---

## Database Schema

### Table: `connection_requests`

Stores all connection requests between users.

```sql
CREATE TABLE connection_requests (
  id UUID PRIMARY KEY,
  from_user_id UUID NOT NULL REFERENCES auth.users(id),
  to_user_id UUID NOT NULL REFERENCES auth.users(id),
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined')),
  message TEXT,
  declined_reason TEXT,
  acted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  
  -- Prevents duplicate pending requests
  CONSTRAINT unique_pending UNIQUE (from_user_id, to_user_id)
);
```

**Key Constraints**:
- Unique constraint prevents duplicate pending requests
- Status must be one of: `pending`, `accepted`, `declined`
- Foreign keys ensure referential integrity

### Table: `connections`

Stores mutual connections (friendships).

```sql
CREATE TABLE connections (
  user_id_1 UUID NOT NULL REFERENCES auth.users(id),
  user_id_2 UUID NOT NULL REFERENCES auth.users(id),
  connected_at TIMESTAMPTZ NOT NULL,
  
  PRIMARY KEY (user_id_1, user_id_2),
  CONSTRAINT user_order CHECK (user_id_1 < user_id_2)
);
```

**Key Design**:
- User IDs are stored in sorted order (`user_id_1 < user_id_2`)
- Primary key on both columns ensures uniqueness
- Bidirectional relationship (both users can query)

### Table: `blocked_users`

Tracks blocked users for abuse prevention.

```sql
CREATE TABLE blocked_users (
  blocker_id UUID NOT NULL REFERENCES auth.users(id),
  blocked_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL,
  
  PRIMARY KEY (blocker_id, blocked_id)
);
```

---

## API Endpoints

### POST `/connections/requests`

Send a connection request to another user.

**Request**:
```json
{
  "to_user_id": "uuid",
  "message": "optional message"
}
```

**Response**: `ConnectionRequestResponse`

**Validations**:
- Cannot send to yourself
- Cannot send if already connected
- Cannot send if pending request exists
- Must wait 7 days after decline (cooldown)
- Max 5 requests per day (rate limit)

### PATCH `/connections/requests/{request_id}`

Respond to a connection request (accept or decline).

**Request**:
```json
{
  "status": "accepted" | "declined",
  "declined_reason": "optional reason"
}
```

**Response**: `ConnectionRequestResponse`

**Validations**:
- Only recipient can respond
- Request must be `pending`
- If accepted: Creates connection and recipients

### GET `/connections/requests/incoming`

Get all pending incoming requests.

**Query Parameters**:
- `limit` (default: 50, max: 100)
- `offset` (default: 0)

**Response**: `ConnectionRequestListResponse`

### GET `/connections/requests/outgoing`

Get all pending outgoing requests.

**Query Parameters**:
- `limit` (default: 50, max: 100)
- `offset` (default: 0)

**Response**: `ConnectionRequestListResponse`

### GET `/connections`

Get all mutual connections.

**Query Parameters**:
- `limit` (default: 50, max: 100)
- `offset` (default: 0)

**Response**: `ConnectionListResponse`

---

## Frontend Implementation

### People Screen

**Location**: `frontend/lib/features/people/people_screen.dart`

Main screen for all connection-related features with tabs:
- **Connections**: List of all mutual connections
- **Requests**: Incoming and outgoing connection requests

**Key Features**:
- Search functionality for connections
- Real-time updates via polling
- Badge counters for pending requests
- Theme-aware UI

### Add Connection Screen

**Location**: `frontend/lib/features/connections/add_connection_screen.dart`

Screen for searching and sending connection requests.

**Features**:
- User search with debouncing
- Filters out already connected users
- Sends connection request with optional message

### State Management

**Providers** (Riverpod):

```dart
// Connections list
final connectionsProvider = StreamProvider<List<Connection>>((ref) {
  final repo = ref.watch(connectionRepositoryProvider);
  return repo.watchConnections();
});

// Incoming requests
final incomingRequestsProvider = StreamProvider<List<ConnectionRequest>>((ref) {
  final repo = ref.watch(connectionRepositoryProvider);
  return repo.watchIncomingRequests();
});

// Outgoing requests
final outgoingRequestsProvider = StreamProvider<List<ConnectionRequest>>((ref) {
  final repo = ref.watch(connectionRepositoryProvider);
  return repo.watchOutgoingRequests();
});

// Request counts
final incomingRequestsCountProvider = Provider<int>((ref) {
  final requests = ref.watch(incomingRequestsProvider);
  return requests.when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
```

**Polling Strategy**:
- Uses `StreamPollingMixin` for consistent polling
- Polls every 5 seconds for updates
- Automatically cancels timers on dispose

---

## Business Rules

### Connection Request Rules

1. **Self-Requests**: Users cannot send requests to themselves
2. **Duplicate Prevention**: Cannot send if pending request already exists
3. **Already Connected**: Cannot send if already connected
4. **Cooldown Period**: Must wait 7 days after a decline before retrying
5. **Rate Limiting**: Maximum 5 connection requests per day per user

### Connection Rules

1. **Mutual Requirement**: Both users must be in the connection (bidirectional)
2. **Auto-Recipient Creation**: Recipients are auto-created when connection is accepted
3. **Letter Sending**: Letters can only be sent to connected users
4. **Connection Deletion**: Users can remove connections (unfriend)

### Recipient Integration

When a connection is accepted:
1. Connection record is created in `connections` table
2. Two recipient entries are auto-created:
   - One for User A (so they can send to User B)
   - One for User B (so they can send to User A)
3. Recipients have `email = NULL` (indicating connection-based)
4. Recipients are linked via `linked_user_id` (future enhancement)

---

## Security

### Access Control

**RLS Policies** (Row Level Security):

```sql
-- Users can only see requests where they are sender or receiver
CREATE POLICY "Users can view own connection requests"
  ON connection_requests FOR SELECT
  USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);

-- Only sender can create requests
CREATE POLICY "Users can send connection requests"
  ON connection_requests FOR INSERT
  WITH CHECK (auth.uid() = from_user_id);

-- Only receiver can respond
CREATE POLICY "Receivers can respond to requests"
  ON connection_requests FOR UPDATE
  USING (auth.uid() = to_user_id AND status = 'pending');
```

### Input Validation

- All inputs sanitized via `sanitize_text()`
- Message length limited to 500 characters
- Decline reason limited to 500 characters
- User IDs validated as UUIDs

### Rate Limiting

- Maximum 5 connection requests per day
- Cooldown period of 7 days after decline
- Prevents abuse and spam

---

## State Management

### Repository Pattern

**Interface**: `ConnectionRepository`
- Abstract interface for connection operations
- Implementations: `ApiConnectionRepository` (FastAPI backend)

**Key Methods**:
```dart
Future<ConnectionRequest> sendConnectionRequest({
  required String toUserId,
  String? message,
});

Future<ConnectionRequest> respondToRequest({
  required String requestId,
  required String status,
  String? declinedReason,
});

Stream<List<ConnectionRequest>> watchIncomingRequests();
Stream<List<ConnectionRequest>> watchOutgoingRequests();
Stream<List<Connection>> watchConnections();
```

### Polling Implementation

Uses `StreamPollingMixin` for consistent polling:

```dart
class ApiConnectionRepository with StreamPollingMixin {
  static const Duration _pollInterval = Duration(seconds: 5);
  
  @override
  Stream<List<ConnectionRequest>> watchIncomingRequests() {
    return createPollingStream<List<ConnectionRequest>>(
      loadData: _loadIncomingRequestsData,
      pollInterval: _pollInterval,
    );
  }
}
```

**Benefits**:
- Consistent polling pattern
- Automatic timer cleanup
- Proper error handling
- Efficient resource management

---

## Error Handling

### Backend Error Responses

**400 Bad Request**:
- Cannot send to yourself
- Already connected
- Pending request exists
- Request already responded to

**403 Forbidden**:
- Not the recipient of request
- User is blocked

**404 Not Found**:
- Connection request not found

**429 Too Many Requests**:
- Rate limit exceeded
- Cooldown period active

**500 Internal Server Error**:
- Database errors
- Unexpected exceptions

### Frontend Error Handling

```dart
try {
  await connectionRepo.sendConnectionRequest(
    toUserId: userId,
    message: message,
  );
  // Show success
} on RepositoryException catch (e) {
  // Show user-friendly error
} catch (e) {
  // Show generic error
}
```

**Error Display**:
- Theme-aware SnackBars
- User-friendly error messages
- Detailed logging for debugging

---

## Integration with Letters

### Letter Sending Requirement

**Enforcement**: Letters can only be sent to connected users.

**Validation Flow**:
1. User selects recipient
2. Backend checks if recipient has `linked_user_id`
3. If connection-based: Verifies connection exists
4. If legacy (email-based): Verifies connection via email
5. Only proceeds if connection verified

**Code Location**: `backend/app/api/capsules.py` - `create_capsule()`

---

## Future Enhancements

### Planned Features

1. **Blocking**: Full blocking implementation (currently TODO)
2. **Connection Groups**: Organize connections into groups
3. **Connection Notes**: Add personal notes about connections
4. **Connection History**: View connection request history
5. **Bulk Actions**: Accept/decline multiple requests

### Technical Improvements

1. **Real-time Updates**: Replace polling with WebSocket/SSE
2. **Push Notifications**: Notify users of new requests
3. **Connection Suggestions**: Suggest users to connect with
4. **Analytics**: Track connection metrics

---

## Testing

### Backend Tests

**Test Cases**:
- Send connection request
- Accept connection request
- Decline connection request
- Rate limiting
- Cooldown period
- Duplicate prevention

### Frontend Tests

**Test Cases**:
- Display connections list
- Display incoming requests
- Display outgoing requests
- Send connection request
- Accept/decline request
- Search functionality

---

## Troubleshooting

### Common Issues

**Issue**: Connection request not appearing
- **Check**: Verify request was created in database
- **Check**: Verify RLS policies allow access
- **Check**: Verify polling is working

**Issue**: Cannot send letter to connection
- **Check**: Verify connection exists
- **Check**: Verify recipient was auto-created
- **Check**: Verify permission checks

**Issue**: Rate limit errors
- **Check**: Verify daily request count
- **Check**: Wait for cooldown period if declined

---

## Related Documentation

- [Backend API Reference](../backend/API_REFERENCE.md#connections)
- [Database Schema](../../supabase/DATABASE_SCHEMA.md#connections)
- [People Screen](./PEOPLE.md) (if exists)
- [Recipients Feature](./RECIPIENTS.md)

---

**Last Updated**: January 2025  
**Maintained By**: Development Team
