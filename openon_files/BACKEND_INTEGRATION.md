# 🔌 Backend Integration Guide

This guide shows how to replace mock repositories with real backend implementations.

## Quick Integration Checklist

- [ ] Choose backend (Supabase recommended for MVP)
- [ ] Set up authentication
- [ ] Create database schema
- [ ] Implement repositories
- [ ] Set up cloud storage for images
- [ ] Configure push notifications
- [ ] Update environment variables
- [ ] Test thoroughly

---

## Option 1: Supabase (Recommended)

### Why Supabase?
- ✅ Built-in auth
- ✅ Real-time database
- ✅ File storage
- ✅ Edge functions
- ✅ Generous free tier
- ✅ Great Flutter support

### 1. Setup

```bash
# Add dependencies to pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
```

```dart
// lib/main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  
  runApp(const ProviderScope(child: OpenOnApp()));
}

// Access anywhere
final supabase = Supabase.instance.client;
```

### 2. Database Schema

```sql
-- Users table (handled by Supabase Auth)
-- auth.users is created automatically

-- Profiles table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recipients table
CREATE TABLE recipients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name TEXT NOT NULL,
  relationship TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Capsules table
CREATE TABLE capsules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES auth.users NOT NULL,
  recipient_id UUID REFERENCES recipients NOT NULL,
  recipient_name TEXT NOT NULL,
  letter_text TEXT NOT NULL,
  photo_url TEXT,
  unlock_time TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  opened_at TIMESTAMP WITH TIME ZONE,
  label TEXT NOT NULL,
  reaction TEXT
);

-- Indexes for performance
CREATE INDEX idx_capsules_sender ON capsules(sender_id);
CREATE INDEX idx_capsules_unlock_time ON capsules(unlock_time);
CREATE INDEX idx_recipients_user ON recipients(user_id);

-- Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE capsules ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can view own recipients"
  ON recipients FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recipients"
  ON recipients FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view sent capsules"
  ON capsules FOR SELECT
  USING (auth.uid() = sender_id);

CREATE POLICY "Users can insert capsules"
  ON capsules FOR INSERT
  WITH CHECK (auth.uid() = sender_id);
```

### 3. Implement UserRepository

```dart
// lib/core/repositories/supabase_user_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'repositories.dart';

class SupabaseUserRepository implements UserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<AppUser?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', session.user.id)
        .single();

    return AppUser.fromJson(response);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create user');
    }

    // Create profile
    await _client.from('profiles').insert({
      'id': authResponse.user!.id,
      'email': email,
      'name': name,
    });

    return AppUser(
      id: authResponse.user!.id,
      email: email,
      name: name,
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid credentials');
    }

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    return AppUser.fromJson(profile);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<AppUser> updateProfile({
    String? name,
    String? avatarPath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    String? avatarUrl;
    if (avatarPath != null) {
      // Upload to Supabase Storage
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}';
      await _client.storage
          .from('avatars')
          .upload(fileName, File(avatarPath));
      
      avatarUrl = _client.storage
          .from('avatars')
          .getPublicUrl(fileName);
    }

    final updates = {
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId);

    return getCurrentUser() as Future<AppUser>;
  }

  @override
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<bool> isAuthenticated() async {
    return _client.auth.currentSession != null;
  }
}
```

### 4. Implement CapsuleRepository

```dart
// lib/core/repositories/supabase_capsule_repository.dart
class SupabaseCapsuleRepository implements CapsuleRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Capsule>> getSentCapsules() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('capsules')
        .select()
        .eq('sender_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Capsule.fromJson(json))
        .toList();
  }

  @override
  Future<Capsule> createCapsule({
    required String recipientId,
    required String recipientName,
    required String letterText,
    required DateTime unlockTime,
    required String label,
    String? photoPath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    String? photoUrl;
    if (photoPath != null) {
      final fileName = '${uuid.v4()}-${DateTime.now().millisecondsSinceEpoch}';
      await _client.storage
          .from('capsule-photos')
          .upload(fileName, File(photoPath));
      
      photoUrl = _client.storage
          .from('capsule-photos')
          .getPublicUrl(fileName);
    }

    final data = {
      'sender_id': userId,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'letter_text': letterText,
      'unlock_time': unlockTime.toIso8601String(),
      'label': label,
      if (photoUrl != null) 'photo_url': photoUrl,
    };

    final response = await _client
        .from('capsules')
        .insert(data)
        .select()
        .single();

    return Capsule.fromJson(response);
  }

  @override
  Future<Capsule> markAsOpened(String capsuleId) async {
    final response = await _client
        .from('capsules')
        .update({'opened_at': DateTime.now().toIso8601String()})
        .eq('id', capsuleId)
        .select()
        .single();

    // TODO: Trigger notification to sender
    await _notifySender(capsuleId);

    return Capsule.fromJson(response);
  }

  Future<void> _notifySender(String capsuleId) async {
    // TODO: Implement with Supabase Edge Function
    // or Firebase Cloud Messaging
  }

  // ... other methods
}
```

### 5. Update Providers

```dart
// lib/core/providers/providers.dart
final capsuleRepositoryProvider = Provider<CapsuleRepository>((ref) {
  return SupabaseCapsuleRepository(); // Changed from Mock
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return SupabaseUserRepository(); // Changed from Mock
});

// Stream auth state changes
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  
  return Supabase.instance.client.auth.onAuthStateChange.asyncMap(
    (event) async {
      if (event.session == null) return null;
      return await repo.getCurrentUser();
    },
  );
});
```

---

## Option 2: Firebase

### Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  firebase_storage: ^11.5.0
  firebase_messaging: ^14.7.0
```

### Firestore Data Model

```dart
// Collections structure
users/
  {userId}/
    - email: string
    - name: string
    - avatarUrl: string

recipients/
  {recipientId}/
    - userId: string
    - name: string
    - relationship: string
    - avatarUrl: string

capsules/
  {capsuleId}/
    - senderId: string
    - recipientId: string
    - recipientName: string
    - letterText: string
    - photoUrl: string
    - unlockTime: timestamp
    - createdAt: timestamp
    - openedAt: timestamp (nullable)
    - label: string
    - reaction: string (nullable)
```

### Firebase UserRepository

```dart
class FirebaseUserRepository implements UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return AppUser(
      id: user.uid,
      email: user.email!,
      name: doc.data()!['name'],
      avatarUrl: doc.data()!['avatarUrl'],
    );
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return AppUser(
      id: credential.user!.uid,
      email: email,
      name: name,
    );
  }

  // ... other methods
}
```

---

## Option 3: Custom REST API

### Setup

```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
  dio: ^5.4.0  # Alternative with better features
```

### API Client

```dart
// lib/core/api/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;
  String? _token;

  ApiClient({String baseUrl = 'https://api.yourapp.com'})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
  }

  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, dynamic data) => _dio.post(path, data: data);
  Future<Response> put(String path, dynamic data) => _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
}
```

### REST UserRepository

```dart
class RestUserRepository implements UserRepository {
  final ApiClient _client;

  RestUserRepository(this._client);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final token = response.data['token'];
    _client.setToken(token);

    return AppUser.fromJson(response.data['user']);
  }

  @override
  Future<List<Capsule>> getSentCapsules() async {
    final response = await _client.get('/capsules/sent');
    return (response.data as List)
        .map((json) => Capsule.fromJson(json))
        .toList();
  }

  // ... other methods
}
```

---

## Push Notifications Setup

### Firebase Cloud Messaging

```dart
// lib/core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission();

    // Get FCM token
    final token = await _fcm.getToken();
    print('FCM Token: $token');
    
    // Send token to backend
    // await api.saveDeviceToken(token);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      print('Got a message: ${message.notification?.title}');
      // Show local notification
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    print('Background message: ${message.notification?.title}');
  }
}
```

---

## Environment Variables

### Create config file

```dart
// lib/core/config/env.dart
class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yourapp.com',
  );
}
```

### Run with env vars

```bash
flutter run \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key
```

---

## Testing After Integration

### 1. Unit Tests

```dart
// test/repositories/capsule_repository_test.dart
void main() {
  group('CapsuleRepository', () {
    late CapsuleRepository repository;

    setUp(() {
      repository = SupabaseCapsuleRepository();
    });

    test('creates capsule successfully', () async {
      final capsule = await repository.createCapsule(
        recipientId: 'test-id',
        recipientName: 'Test User',
        letterText: 'Test letter',
        unlockTime: DateTime.now().add(Duration(days: 1)),
        label: 'Test',
      );

      expect(capsule.id, isNotEmpty);
      expect(capsule.letterText, 'Test letter');
    });
  });
}
```

### 2. Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  testWidgets('complete flow test', (tester) async {
    // 1. Launch app
    await tester.pumpWidget(ProviderScope(child: OpenOnApp()));
    
    // 2. Sign up
    await tester.tap(find.text('Get Started'));
    // ... complete flow
  });
}
```

---

## Checklist Before Going Live

- [ ] All mock repositories replaced
- [ ] Environment variables configured
- [ ] Database schema deployed
- [ ] Storage buckets created
- [ ] Push notifications tested
- [ ] Error handling robust
- [ ] Loading states work
- [ ] Offline support (if needed)
- [ ] Security rules configured
- [ ] API rate limiting in place
- [ ] Analytics integrated
- [ ] Crash reporting setup (Sentry/Crashlytics)

---

**Choose your backend and start integrating!** 🚀

Recommended order:
1. Start with Supabase (easiest)
2. Get auth working first
3. Then database operations
4. Then file storage
5. Finally push notifications
