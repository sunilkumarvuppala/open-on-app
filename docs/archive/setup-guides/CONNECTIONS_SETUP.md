# Friend Request / Mutual Connection Feature - Setup Guide

## ✅ Implementation Status: **COMPLETE**

All components have been implemented and are ready to use!

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Run Database Migrations

```bash
cd supabase
supabase db reset
# Or apply migrations manually:
# supabase migration up
```

This will create:
- `connection_requests` table
- `connections` table  
- `blocked_users` table
- All RLS policies
- All RPC functions
- Notification triggers

### Step 2: Generate Flutter Code

```bash
cd frontend
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates the Freezed files for connection models.

### Step 3: Configure Supabase

**Get your Supabase credentials:**
```bash
cd supabase
supabase status
```

**Set environment variables or update main.dart:**

**Option A: Environment Variables** (Recommended)
```bash
flutter run --dart-define=SUPABASE_URL=http://localhost:54321 \
           --dart-define=SUPABASE_ANON_KEY=your-anon-key-here
```

**Option B: Direct in Code**
Edit `frontend/lib/main.dart` - Supabase initialization is already added!

---

## 📱 Accessing the Feature

### From Profile Screen

The profile screen now has a **"Connections"** section with:
- **My Connections** - View all mutual connections
- **Connection Requests** - Incoming/outgoing requests (with badge count)
- **Add Connection** - Send new connection requests

### Direct Navigation

```dart
// Navigate to connections list
context.push('/connections');

// Navigate to requests
context.push('/connections/requests');

// Navigate to add connection
context.push('/connections/add');
```

---

## 🎯 Feature Highlights

### ✅ Mutual Connection Enforcement
- Letters can **ONLY** be sent to users who have accepted connection requests
- Backend validates connection before allowing capsule creation
- Clear error message if not connected

### ✅ Real-Time Updates
- **Incoming requests** appear instantly (no refresh needed)
- **Outgoing requests** update status automatically (Pending → Accepted/Declined)
- **Connections list** updates when new connections are created
- **Badge counter** updates in real-time

### ✅ Complete UI Flow
- Search users by username, name, or email
- Send requests with optional message
- Accept/decline with confetti animation
- View all connections with quick actions

### ✅ Abuse Prevention
- Rate limiting: Max 5 requests/day
- Cooldown: 7 days after decline
- Blocking: Blocked users cannot send requests
- Duplicate prevention: No duplicate pending requests

---

## 📊 Database Tables

### connection_requests
Tracks all friend requests with status (pending/accepted/declined)

### connections  
Stores mutual friendships (sorted user IDs)

### blocked_users
Prevents blocked users from sending requests

---

## 🔧 RPC Functions

All functions are SECURITY DEFINER and handle validation:

1. **send_connection_request(to_user_id, message?)**
   - Validates: no self-requests, not connected, not blocked, no duplicates
   - Enforces: cooldown (7 days), rate limit (5/day)

2. **respond_to_request(request_id, action, declined_reason?)**
   - Only receiver can respond
   - Creates connection on accept
   - Updates status on decline

3. **get_pending_requests()**
   - Returns incoming and outgoing arrays
   - Includes user profile info

4. **get_connections()**
   - Returns all mutual connections
   - Includes other user's profile

---

## 🎨 UI Components

### Add Connection Screen
- Search bar with real-time results
- User cards with avatar and name
- Optional message field (120 chars)
- Send request button

### Requests Screen (Two Tabs)
- **Incoming Tab:**
  - Avatar + name + message
  - Time ago
  - Accept/Decline buttons
  - Badge count in tab
  
- **Outgoing Tab:**
  - Status chips (Pending/Accepted/Declined)
  - Grouped by status
  - Real-time status updates

### Connections Screen
- List of all mutual connections
- Avatar + name
- Time connected
- Quick action buttons

---

## 🔔 Notifications

Database triggers automatically create notifications:
- New request → "X wants to connect with you"
- Request accepted → "Your request to X was accepted!"

Notifications are stored in `notifications` table.

---

## 🧪 Testing

### Test Connection Flow

1. **User A sends request to User B:**
   - User A: Navigate to "Add Connection"
   - Search for User B
   - Send request
   - Request appears in "Outgoing" tab with "Pending" status

2. **User B receives request:**
   - Badge appears on "Connection Requests" (count: 1)
   - Open "Incoming" tab
   - See User A's request
   - Accept → Confetti animation → Success modal
   - User A appears in "Connections" list

3. **User A sees update:**
   - "Outgoing" tab shows status changed to "Accepted"
   - User B appears in "Connections" list
   - Can now send letters to User B

### Test Mutual Connection Enforcement

1. Try to create capsule for non-connected user
2. Should get error: "You can only send letters to users you are connected with"
3. Send connection request and accept
4. Now capsule creation should work

---

## 🐛 Common Issues

### "Supabase not initialized"
- Check `main.dart` has `SupabaseConfig.initialize()`
- Verify SUPABASE_URL and SUPABASE_ANON_KEY are set
- Check logs for initialization errors

### "Freezed files not found"
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Foreign key violation"
- User doesn't exist in `auth.users`
- Backend now handles this gracefully (returns 401)
- User should sign in again

### "Real-time not working"
- Ensure user is authenticated
- Check RLS policies allow access
- Verify network connection
- Check Supabase client is initialized

---

## 📚 Documentation

- **Complete Implementation**: `docs/CONNECTIONS_COMPLETE.md`
- **Feature Guide**: `docs/CONNECTIONS_FEATURE.md`
- **This Setup Guide**: `CONNECTIONS_SETUP.md`

---

## ✨ You're All Set!

The Friend Request / Mutual Connection feature is **fully implemented** and **production-ready**. 

All requirements from the specification have been met:
- ✅ Database schema
- ✅ RLS policies
- ✅ RPC functions
- ✅ Flutter UI
- ✅ Real-time updates
- ✅ Mutual connection enforcement
- ✅ Abuse prevention
- ✅ Notifications
- ✅ UX enhancements

**Happy connecting!** 🎉
