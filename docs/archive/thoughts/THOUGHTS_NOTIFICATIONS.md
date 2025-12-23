# Thoughts Feature - Notification System

## Current State

### ❌ What's NOT Working Yet

1. **No Real-Time Notifications**: Receivers don't get notified immediately when a thought is sent
2. **No Push Notifications**: Edge Function has stub code but doesn't actually send push notifications
3. **No Real-Time UI Updates**: Flutter app uses `FutureProvider` (one-time fetch), not a real-time stream
4. **Manual Refresh Required**: Receiver must manually refresh to see new thoughts

### ✅ What IS Working

1. **Database Storage**: Thoughts are stored correctly in `thoughts` table
2. **Notification Records**: Edge Function creates notification records (if used)
3. **RPC Functions**: All database functions work correctly
4. **Manual Fetching**: `listIncoming()` can fetch thoughts on demand

---

## How Receivers Currently See Thoughts

### Current Flow (Manual Refresh)

```
1. User A sends thought to User B
   ↓
2. Thought is saved to database (thoughts table)
   ↓
3. User B opens app
   ↓
4. User B navigates to "Thoughts" screen (if exists)
   ↓
5. App calls listIncoming() → fetches thoughts from database
   ↓
6. User B sees the thought
```

**Problem**: User B only sees the thought when they manually open the app and navigate to the thoughts screen.

---

## How to Implement Real-Time Notifications

You have **3 options** for notifying receivers:

### Option 1: Supabase Realtime (Recommended) ⭐

**Best for**: Real-time UI updates, instant notifications when app is open

#### How It Works

1. **Database Trigger**: When a thought is inserted, Supabase Realtime broadcasts the change
2. **Flutter Subscription**: App subscribes to `thoughts` table changes
3. **UI Update**: When new thought arrives, UI updates automatically

#### Implementation Steps

**Step 1: Enable Realtime on `thoughts` table**

```sql
-- Run this in Supabase SQL Editor
ALTER PUBLICATION supabase_realtime ADD TABLE public.thoughts;
```

**Step 2: Update Flutter Provider to Use Realtime**

```dart
// In frontend/lib/core/providers/providers.dart

// Change from FutureProvider to StreamProvider
final incomingThoughtsProvider = StreamProvider<List<Thought>>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  
  final currentUser = await userAsync.future;
  if (currentUser == null) {
    throw AuthenticationException('Not authenticated');
  }
  
  final repo = ref.watch(thoughtRepositoryProvider);
  
  // Initial load
  final initialThoughts = await repo.listIncoming();
  yield initialThoughts;
  
  // Set up realtime subscription
  final supabase = SupabaseConfig.client;
  final subscription = supabase
      .from('thoughts')
      .stream(primaryKey: ['id'])
      .eq('receiver_id', currentUser.id)
      .order('created_at', ascending: false)
      .listen((data) {
        // Convert to Thought objects and yield
        // This will trigger UI updates automatically
      });
  
  // Clean up on dispose
  ref.onDispose(() {
    subscription.cancel();
  });
});
```

**Step 3: Update Repository to Support Realtime**

```dart
// In frontend/lib/core/data/thought_repository.dart

Stream<List<Thought>> watchIncomingThoughts() {
  return _supabase
      .from('thoughts')
      .stream(primaryKey: ['id'])
      .eq('receiver_id', _supabase.auth.currentUser?.id ?? '')
      .order('created_at', ascending: false)
      .map((data) {
        // Convert to Thought objects
        return data.map((json) => Thought.fromJson(json)).toList();
      });
}
```

**When Receiver Gets Notified**:
- ✅ **Immediately** when app is open (real-time update)
- ✅ **When app opens** (fetches latest thoughts)
- ❌ **When app is closed** (no push notification yet)

---

### Option 2: Push Notifications (FCM/APNS)

**Best for**: Notifying users when app is closed or in background

#### How It Works

1. **Edge Function**: When thought is sent, Edge Function sends push notification
2. **FCM/APNS**: Delivers notification to device
3. **App Receives**: Flutter app receives notification and shows badge/banner

#### Implementation Steps

**Step 1: Complete Edge Function Implementation**

The Edge Function (`supabase/functions/send-thought/index.ts`) has stub code. You need to:

1. **Set up FCM/APNS credentials** in Supabase
2. **Implement actual push notification sending**:

```typescript
// In send-thought/index.ts, replace the TODO section:

// Send push notification via Supabase's built-in push service
// Or use your own FCM/APNS service
const { data: pushResult, error: pushError } = await supabaseAdmin
  .functions.invoke('send-push-notification', {
    body: {
      user_id: receiver_id,
      title: 'Thought',
      body: `${senderName} thought of you today.`,
      data: {
        type: 'thought_received',
        thought_id: thoughtId,
        sender_id: user.id,
      },
    },
  });
```

**Step 2: Set Up Device Tokens**

Users need to register their device tokens:

```dart
// In Flutter app, when user logs in:
final token = await FirebaseMessaging.instance.getToken();
await _supabase
    .from('user_profiles')
    .update({'device_token': token})
    .eq('user_id', currentUserId);
```

**Step 3: Handle Push Notifications in Flutter**

```dart
// Listen for push notifications
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['type'] == 'thought_received') {
    // Show notification
    // Navigate to thoughts screen
    // Refresh thoughts list
  }
});
```

**When Receiver Gets Notified**:
- ✅ **Immediately** when thought is sent (push notification)
- ✅ **When app is closed** (system notification)
- ✅ **When app is in background** (notification banner)

---

### Option 3: Polling (Simple but Less Efficient)

**Best for**: Quick implementation, works without Realtime setup

#### How It Works

1. **Periodic Checks**: App periodically checks for new thoughts
2. **UI Update**: When new thoughts found, update UI

#### Implementation Steps

**Update Provider to Poll**:

```dart
// In frontend/lib/core/providers/providers.dart

final incomingThoughtsProvider = StreamProvider<List<Thought>>((ref) async* {
  final repo = ref.watch(thoughtRepositoryProvider);
  
  // Initial load
  yield await repo.listIncoming();
  
  // Poll every 30 seconds
  yield* Stream.periodic(const Duration(seconds: 30), (_) async {
    return await repo.listIncoming();
  }).asyncMap((future) => future);
});
```

**When Receiver Gets Notified**:
- ✅ **Within 30 seconds** when app is open (polling interval)
- ✅ **When app opens** (immediate fetch)
- ❌ **When app is closed** (no notification)

---

## Recommended Implementation

### For Best User Experience:

**Combine Option 1 + Option 2**:

1. **Realtime for Active Users** (Option 1)
   - Users with app open get instant updates
   - No polling overhead
   - Better battery life

2. **Push Notifications for Inactive Users** (Option 2)
   - Users with app closed get notified
   - Brings them back to the app
   - Better engagement

### Implementation Priority:

1. **Phase 1**: Implement Realtime (Option 1) - Quick win, instant updates
2. **Phase 2**: Implement Push Notifications (Option 2) - Better UX
3. **Phase 3**: Optimize with both - Best of both worlds

---

## Current Code Status

### ✅ Already Implemented

- Database schema (`thoughts` table)
- RPC functions (`rpc_send_thought`, `rpc_list_incoming_thoughts`)
- Flutter repository (`ThoughtRepository`)
- Basic providers (`incomingThoughtsProvider`)

### ❌ Not Yet Implemented

- Realtime subscriptions
- Push notification sending
- Notification preferences
- Badge counts
- In-app notification UI

---

## Quick Start: Enable Realtime (5 minutes)

### Step 1: Enable Realtime on Database

```sql
-- Run in Supabase SQL Editor
ALTER PUBLICATION supabase_realtime ADD TABLE public.thoughts;
```

### Step 2: Update Flutter Provider

Change `incomingThoughtsProvider` from `FutureProvider` to `StreamProvider` with Realtime subscription (see Option 1 above).

### Step 3: Test

1. User A sends thought to User B
2. User B's app should update automatically (if app is open)
3. Check logs to verify Realtime subscription is working

---

## Testing Notifications

### Test Realtime (Option 1)

```dart
// In your Flutter app, add this test:
final supabase = SupabaseConfig.client;
supabase
    .from('thoughts')
    .stream(primaryKey: ['id'])
    .eq('receiver_id', currentUserId)
    .listen((data) {
      print('🟢 New thought received: ${data.length}');
    });
```

### Test Push Notifications (Option 2)

1. Send a thought from User A to User B
2. Check Edge Function logs for notification attempt
3. Verify device token is set in `user_profiles`
4. Check if notification appears on device

---

## Summary

**Current State**: Receivers must manually refresh to see thoughts

**Recommended Solution**: 
1. Enable Realtime for instant updates (when app is open)
2. Add Push Notifications for background notifications (when app is closed)

**Time to Implement**:
- Realtime: ~30 minutes
- Push Notifications: ~2-3 hours (requires FCM/APNS setup)

**User Experience After Implementation**:
- ✅ Instant notification when app is open
- ✅ Push notification when app is closed
- ✅ Badge count on app icon
- ✅ In-app notification banner

