# Friend Request / Mutual Connection Feature

Complete implementation guide for the Friend Request / Mutual Connection feature.

## 📋 Overview

This feature enables users to:
- Send connection requests to other users
- Accept or decline incoming requests
- View mutual connections (friends)
- Enforce that letters can only be sent to mutual friends

## 🗄️ Database Schema

### Tables Created

1. **connection_requests** - Tracks friend requests
   - Status: pending, accepted, declined
   - Includes message and declined_reason fields
   - Unique constraint prevents duplicate pending requests

2. **connections** - Stores mutual connections
   - Users stored in sorted order (user_id_1 < user_id_2)
   - Primary key on both user IDs ensures uniqueness

3. **blocked_users** - Abuse prevention
   - Tracks blocked users
   - Prevents blocked users from sending requests

### Migration Files

- `supabase/migrations/08_connections.sql` - Table creation
- `supabase/migrations/09_connections_rls.sql` - RLS policies
- `supabase/migrations/10_connections_functions.sql` - RPC functions

## 🔒 Security (RLS Policies)

- Users can only see requests where they are sender or receiver
- Only receivers can respond to requests
- Connections can only be created via RPC (service role)
- Blocked users cannot send requests

## 🔧 RPC Functions

### send_connection_request(to_user_id, message?)
- Validates: no self-requests, not already connected, not blocked, no duplicate pending
- Enforces: 7-day cooldown after decline, max 5 requests per day
- Returns: Created request with profile info

### respond_to_request(request_id, action, declined_reason?)
- Validates: only receiver can respond, request must be pending
- Actions: 'accept' (creates connection) or 'decline'
- Returns: Updated request with connection info if accepted

### get_pending_requests()
- Returns: JSON with incoming and outgoing arrays
- Includes user profile info for each request

### get_connections()
- Returns: List of all mutual connections
- Includes other user's profile info

## 📱 Flutter Implementation

### Models

- `ConnectionRequest` - Request model with status and profiles
- `Connection` - Mutual connection model
- `ConnectionUserProfile` - User profile info
- `PendingRequests` - Container for incoming/outgoing requests

**Note**: Run `flutter pub run build_runner build` to generate freezed files.

### Repository

`SupabaseConnectionRepository` implements:
- CRUD operations for requests and connections
- Real-time streams for live updates
- User search functionality
- Block/unblock operations

### Providers

- `connectionRepositoryProvider` - Repository instance
- `incomingRequestsProvider` - Stream of incoming requests
- `outgoingRequestsProvider` - Stream of outgoing requests
- `connectionsProvider` - Stream of connections
- `incomingRequestsCountProvider` - Badge count for incoming requests

### Screens

1. **AddConnectionScreen** (`/connections/add`)
   - Search users by username, name, or email
   - Send request with optional message

2. **RequestsScreen** (`/connections/requests`)
   - Two tabs: Incoming and Outgoing
   - Accept/decline incoming requests
   - View status of outgoing requests

3. **ConnectionsScreen** (`/connections`)
   - List all mutual connections
   - Quick action to send letters (future)

## 🔄 Real-Time Updates

All lists update in real-time using Supabase streams:
- Incoming requests: Streams `connection_requests` where `to_user_id = current_user`
- Outgoing requests: Streams `connection_requests` where `from_user_id = current_user`
- Connections: Streams `connections` where user is either user_id_1 or user_id_2

## 🚀 Setup Instructions

### 1. Database Migration

Run the migrations in order:
```bash
cd supabase
supabase db reset  # Or apply migrations manually
```

### 2. Flutter Dependencies

Add Supabase SDK (already added to pubspec.yaml):
```bash
cd frontend
flutter pub get
```

### 3. Generate Freezed Files

```bash
cd frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Initialize Supabase Client

In your `main.dart`, initialize Supabase before running the app:

```dart
import 'package:openon_app/core/data/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize(
    url: 'http://localhost:54321', // Or your production URL
    anonKey: 'your-anon-key', // Get from supabase status
  );
  
  runApp(const MyApp());
}
```

### 5. Environment Variables (Optional)

You can also set environment variables:
```bash
flutter run --dart-define=SUPABASE_URL=http://localhost:54321 \
           --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## 🎨 UI Features

### Badge Counter

The incoming requests count is available via `incomingRequestsCountProvider`:

```dart
final count = ref.watch(incomingRequestsCountProvider);
Badge(
  label: Text('$count'),
  child: IconButton(
    icon: Icon(Icons.person_add),
    onPressed: () => context.push('/connections/requests'),
  ),
)
```

### Real-Time Updates

All screens automatically update when:
- New requests arrive
- Requests are accepted/declined
- New connections are created

## 🛡️ Abuse Prevention

1. **Rate Limiting**: Max 5 requests per day per user
2. **Cooldown**: 7 days after decline before resending
3. **Blocking**: Blocked users cannot send requests
4. **Duplicate Prevention**: Unique constraint on pending requests

## 📝 Usage Examples

### Send Connection Request

```dart
final repo = ref.read(connectionRepositoryProvider);
await repo.sendConnectionRequest(
  toUserId: 'user-uuid',
  message: 'Hey, let\'s connect!',
);
```

### Accept Request

```dart
await repo.respondToRequest(
  requestId: 'request-uuid',
  accept: true,
);
```

### Watch Incoming Requests

```dart
final incomingAsync = ref.watch(incomingRequestsProvider);
incomingAsync.when(
  data: (requests) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => ErrorWidget(e),
);
```

## 🔮 Future Enhancements

- [ ] Notification system integration (push notifications)
- [ ] "Send Letter" button integration with capsule creation
- [ ] Unfriend functionality
- [ ] Connection suggestions
- [ ] Mutual friends display

## 🐛 Troubleshooting

### Freezed files not generated
Run: `flutter pub run build_runner build --delete-conflicting-outputs`

### Supabase not initialized
Ensure `SupabaseConfig.initialize()` is called in `main()` before `runApp()`

### Real-time not working
Check that:
- Supabase client is initialized
- User is authenticated
- RLS policies allow access
- Network connection is active

### RPC function errors
Check Supabase logs and ensure:
- Functions are created in database
- User has EXECUTE permission
- Function parameters match expected types
