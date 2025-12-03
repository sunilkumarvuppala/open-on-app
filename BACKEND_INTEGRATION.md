# Backend Integration Guide

This document describes how the frontend is integrated with the backend API.

## Overview

The frontend communicates with the FastAPI backend through HTTP REST API calls. The integration is implemented using:

- **HTTP Client**: `http` package for making API requests
- **API Client**: Custom `ApiClient` class that handles authentication, error handling, and request/response mapping
- **Repositories**: API-based repository implementations that replace mock repositories
- **Token Storage**: Secure storage of JWT tokens using SharedPreferences

## Configuration

### API Base URL

The API base URL is configured in `lib/core/data/api_config.dart`:

```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
```

**For Development:**
- Local backend: `http://localhost:8000`
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://localhost:8000`

**For Production:**
Set the `API_BASE_URL` environment variable when building:
```bash
flutter build apk --dart-define=API_BASE_URL=https://your-api-domain.com
```

### Enabling API Integration

The integration can be toggled in `lib/core/providers/providers.dart`:

```dart
const bool useApiRepositories = true; // Set to false to use mocks
```

## Architecture

### API Client (`api_client.dart`)

The `ApiClient` class provides:
- Automatic JWT token injection in request headers
- Error handling and exception mapping
- GET, POST, PUT, DELETE methods
- Query parameter support
- Response parsing

### Token Storage (`token_storage.dart`)

The `TokenStorage` service manages:
- Access token storage/retrieval
- Refresh token storage/retrieval
- Token clearing on logout
- Authentication state checking

### API Repositories (`api_repositories.dart`)

Three main repository implementations:

1. **ApiAuthRepository**: Handles authentication
   - Sign up
   - Sign in
   - Sign out
   - Get current user
   - Update profile

2. **ApiCapsuleRepository**: Manages capsules
   - Get capsules (inbox/outbox)
   - Create capsule
   - Update capsule
   - Delete capsule
   - Seal capsule (set unlock time)
   - Open capsule
   - Mark as opened

3. **ApiRecipientRepository**: Manages recipients
   - Get recipients
   - Create recipient
   - Delete recipient

## API Endpoints

### Authentication

- `POST /auth/signup` - Register new user
- `POST /auth/login` - Login user
- `GET /auth/me` - Get current user

### Capsules

- `GET /capsules?box={inbox|outbox}&state={state}&page={page}&page_size={size}` - List capsules
- `POST /capsules` - Create capsule (draft state)
- `GET /capsules/{id}` - Get capsule details
- `PUT /capsules/{id}` - Update capsule (draft only)
- `DELETE /capsules/{id}` - Delete capsule (draft only)
- `POST /capsules/{id}/seal` - Seal capsule with unlock time
- `POST /capsules/{id}/open` - Open capsule

### Recipients

- `GET /recipients?page={page}&page_size={size}` - List recipients
- `POST /recipients` - Create recipient
- `GET /recipients/{id}` - Get recipient
- `DELETE /recipients/{id}` - Delete recipient

## Data Mapping

### User Model

**Backend Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "username",
  "full_name": "John Doe",
  "is_active": true,
  "created_at": "2025-01-01T00:00:00Z"
}
```

**Frontend Model:**
```dart
User(
  id: json['id'],
  name: json['full_name'] ?? json['username'],
  email: json['email'],
)
```

### Capsule Model

**Backend Response:**
```json
{
  "id": "uuid",
  "sender_id": "uuid",
  "receiver_id": "uuid",
  "title": "Letter title",
  "body": "Letter content",
  "media_urls": "[\"url1\", \"url2\"]",
  "state": "draft|sealed|unfolding|ready|opened",
  "scheduled_unlock_at": "2025-12-25T00:00:00Z",
  "opened_at": "2025-12-25T01:00:00Z",
  "created_at": "2025-01-01T00:00:00Z"
}
```

**Frontend Model:**
```dart
Capsule(
  id: json['id'],
  senderId: json['sender_id'],
  receiverId: json['receiver_id'],
  label: json['title'],
  content: json['body'],
  photoUrl: mediaUrls?.first,
  unlockAt: DateTime.parse(json['scheduled_unlock_at']),
  openedAt: json['opened_at'] != null ? DateTime.parse(json['opened_at']) : null,
)
```

## Capsule Creation Flow

The backend requires a two-step process:

1. **Create Capsule** (draft state)
   ```dart
   final capsule = await repo.createCapsule(capsule);
   ```

2. **Seal Capsule** (set unlock time)
   ```dart
   if (repo is ApiCapsuleRepository) {
     await repo.sealCapsule(capsule.id, unlockAt);
   }
   ```

This is automatically handled in `create_capsule_screen.dart`.

## Error Handling

The API client maps HTTP status codes to exceptions:

- `400` → `ValidationException`
- `401` → `AuthenticationException`
- `403` → `AuthenticationException`
- `404` → `NotFoundException`
- `422` → `ValidationException`
- `500+` → `NetworkException`

All exceptions extend `AppException` and are handled consistently throughout the app.

## Authentication Flow

1. User signs up/logs in
2. Backend returns access and refresh tokens
3. Tokens are stored securely using `TokenStorage`
4. All subsequent API calls include `Authorization: Bearer {token}` header
5. On 401 errors, tokens are cleared and user is logged out

## State Management

The integration uses Riverpod providers:

- `authRepositoryProvider` - Returns `ApiAuthRepository` or `MockAuthRepository`
- `capsuleRepositoryProvider` - Returns `ApiCapsuleRepository` or `MockCapsuleRepository`
- `recipientRepositoryProvider` - Returns `ApiRecipientRepository` or `MockRecipientRepository`

Providers automatically refresh when data changes, and caches are invalidated after mutations.

## Testing

### Local Backend

1. Start the backend:
   ```bash
   cd backend
   python -m uvicorn app.main:app --reload
   ```

2. Update API base URL in `api_config.dart` or use environment variable

3. Run the Flutter app:
   ```bash
   cd frontend
   flutter run
   ```

### Mock Mode

To test without backend, set `useApiRepositories = false` in `providers.dart`.

## Troubleshooting

### Connection Refused

- Ensure backend is running
- Check API base URL matches backend address
- For Android emulator, use `10.0.2.2:8000` instead of `localhost:8000`

### Authentication Errors

- Check tokens are being saved correctly
- Verify backend secret key is set
- Check token expiration times

### CORS Errors

- Ensure backend CORS settings include your frontend origin
- Check `CORS_ORIGINS` in backend `.env` file

### Data Mapping Issues

- Verify backend response format matches expected schema
- Check date/time parsing (backend uses UTC)
- Ensure media_urls JSON parsing works correctly

## Future Enhancements

- [ ] Refresh token rotation
- [ ] Offline support with local caching
- [ ] Request retry logic
- [ ] Request/response logging
- [ ] Draft repository implementation
- [ ] File upload for media
- [ ] Real-time updates via WebSocket

