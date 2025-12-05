# OpenOn Supabase Backend Structure

Recommended folder structure for Supabase backend integration.

## 📁 Recommended Structure

```
supabase/
├── schema.sql                  # Complete database schema
├── rls_policies.sql            # Row-level security policies
├── storage.sql                 # Storage buckets configuration
├── seed_data.sql               # Seed data for development
├── functions/                  # Edge Functions (optional)
│   ├── send-notification/
│   │   ├── index.ts
│   │   └── package.json
│   └── webhook-stripe/
│       ├── index.ts
│       └── package.json
└── migrations/                 # Migration files (if using migrations)
    ├── 001_initial_schema.sql
    ├── 002_add_indexes.sql
    └── 003_add_functions.sql

frontend/lib/                   # Flutter backend integration
│   ├── core/
│   │   ├── supabase_client.dart
│   │   ├── auth_service.dart
│   │   └── storage_service.dart
│   ├── models/                 # Type definitions
│   │   └── supabase_types.dart
│   ├── repositories/
│   │   ├── capsule_repository.dart
│   │   ├── recipient_repository.dart
│   │   ├── theme_repository.dart
│   │   ├── notification_repository.dart
│   │   └── subscription_repository.dart
│   └── services/
│       ├── capsule_service.dart
│       ├── notification_service.dart
│       └── subscription_service.dart
│
├── docs/
│   ├── API_SPECIFICATION.md
│   ├── DEPLOYMENT.md
│   └── TROUBLESHOOTING.md
│
└── scripts/
    ├── deploy.sh
    ├── seed.sh
    └── migrate.sh
```

## 🔧 Implementation Files

### Flutter Supabase Client

**lib/core/supabase_client.dart**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static SupabaseClient? _instance;
  late final SupabaseClient client;

  SupabaseClient._internal() {
    client = Supabase.instance.client;
  }

  static SupabaseClient get instance {
    _instance ??= SupabaseClient._internal();
    return _instance!;
  }
}
```

### Repository Pattern Example

**lib/repositories/capsule_repository.dart**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/supabase_types.dart';

class CapsuleRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Capsule>> getInbox() async {
    final response = await _client
        .from('inbox_view')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => Capsule.fromJson(json))
        .toList();
  }

  Future<Capsule> createCapsule(CreateCapsuleRequest request) async {
    final response = await _client
        .from('capsules')
        .insert(request.toJson())
        .select()
        .single();
    
    return Capsule.fromJson(response);
  }

  Future<void> openCapsule(String capsuleId) async {
    await _client
        .from('capsules')
        .update({'opened_at': DateTime.now().toIso8601String()})
        .eq('id', capsuleId);
  }
}
```

## 🚀 Deployment Steps

1. **Create Supabase Project**
   - Go to supabase.com
   - Create new project
   - Note project URL and anon key

2. **Run Schema**
   ```bash
   psql -h [your-db-host] -U postgres -d postgres -f schema.sql
   ```

3. **Run RLS Policies**
   ```bash
   psql -h [your-db-host] -U postgres -d postgres -f rls_policies.sql
   ```

4. **Run Storage Setup**
   ```bash
   psql -h [your-db-host] -U postgres -d postgres -f storage.sql
   ```

5. **Seed Data (Optional)**
   ```bash
   psql -h [your-db-host] -U postgres -d postgres -f seed_data.sql
   ```

6. **Configure Flutter**
   ```dart
   await Supabase.initialize(
     url: 'https://[your-project].supabase.co',
     anonKey: '[your-anon-key]',
   );
   ```

## 📝 Environment Variables

Create `.env` file:
```
SUPABASE_URL=https://[your-project].supabase.co
SUPABASE_ANON_KEY=[your-anon-key]
SUPABASE_SERVICE_ROLE_KEY=[your-service-role-key]
```

## 🔐 Security Notes

1. **Never commit service role key** to version control
2. **Use RLS policies** for all data access
3. **Validate all inputs** on client and server
4. **Use HTTPS** for all API calls
5. **Implement rate limiting** for public endpoints

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgREST API](https://postgrest.org/)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

