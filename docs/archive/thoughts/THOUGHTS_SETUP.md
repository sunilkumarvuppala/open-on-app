# Thoughts Feature - Quick Setup Guide

## Prerequisites

- Supabase project configured
- Flutter project with dependencies installed
- Supabase CLI (for local testing)

## Setup Steps

### 1. Run Database Migration

```bash
# Apply the migration
supabase migration up

# Or manually via psql:
psql -h <your-db-host> -U postgres -d postgres -f supabase/migrations/15_thoughts_feature.sql
```

### 2. Generate Flutter Models

The `thought_models.dart` file uses Freezed for code generation. Run:

```bash
cd frontend
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `thought_models.freezed.dart`
- `thought_models.g.dart`

### 3. Deploy Edge Function (Optional)

If you want to use the Edge Function for notifications:

```bash
supabase functions deploy send-thought
```

### 4. Verify Installation

Run the test queries from `supabase/migrations/15_thoughts_feature_tests.sql` to ensure:
- Tables are created
- RLS policies work
- RPC functions validate correctly

### 5. Test in Flutter

```dart
// Example usage in a widget
final thoughtRepo = ref.watch(thoughtRepositoryProvider);
final result = await thoughtRepo.sendThought(receiverId);

if (result.success) {
  // Show success
} else {
  // Handle error: result.errorCode, result.errorMessage
}
```

## Files Created

### Database
- `supabase/migrations/15_thoughts_feature.sql` - Main migration
- `supabase/tests/thoughts_feature_tests.sql` - Test queries (NOT a migration)

### Edge Function
- `supabase/functions/send-thought/index.ts` - Notification handler

### Flutter
- `frontend/lib/core/models/thought_models.dart` - Models (needs codegen)
- `frontend/lib/core/data/thought_repository.dart` - Repository
- Updated `frontend/lib/core/providers/providers.dart` - Providers

### Documentation
- `docs/THOUGHTS_FEATURE.md` - Complete documentation

## Next Steps

1. Create UI screens for sending/receiving thoughts
2. Add navigation to thoughts feature
3. Test with real users
4. Monitor rate limits and adjust if needed

## Troubleshooting

### Freezed Generation Errors
Run: `flutter pub run build_runner build --delete-conflicting-outputs`

### RPC Function Not Found
Ensure migration was applied: `supabase migration list`

### RLS Policy Errors
Check that RLS is enabled: `SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';`

### Edge Function Errors
Check Supabase logs: `supabase functions logs send-thought`

