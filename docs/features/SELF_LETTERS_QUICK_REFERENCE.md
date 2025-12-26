# Self Letters Feature - Quick Reference

**Last Updated**: January 2025  
**Status**: ✅ Production Ready  
**Related**: [Complete Documentation](./SELF_LETTERS.md)

---

## 🎯 Quick Facts

- **Feature**: Self Letters (Letters to Future Self)
- **Status**: ✅ Production Ready
- **Isolation**: Completely separate from regular capsules
- **Table**: `self_letters` (separate from `capsules`)
- **API Base**: `/self-letters`
- **Content Length**: 20-500 characters (configurable)

---

## 📁 Key Files

### Backend
- `backend/app/api/self_letters.py` - API endpoints
- `backend/app/services/self_letter_service.py` - Business logic
- `backend/app/db/repositories.py` - `SelfLetterRepository` class
- `backend/app/db/models.py` - `SelfLetter` model
- `backend/app/models/schemas.py` - Request/response schemas
- `backend/app/core/config.py` - Configuration (content length limits)

### Frontend
- `frontend/lib/features/self_letters/create_self_letter_screen.dart` - Creation screen
- `frontend/lib/features/self_letters/open_self_letter_screen.dart` - Open/view screen
- `frontend/lib/core/models/models.dart` - `SelfLetter` model
- `frontend/lib/core/data/api_repositories.dart` - API repository
- `frontend/lib/core/providers/providers.dart` - `selfLettersProvider`
- `frontend/lib/features/home/home_screen.dart` - Integration (Sealed/Opened tabs)
- `frontend/lib/features/create_capsule/create_capsule_screen.dart` - Regular flow integration

### Database
- `supabase/migrations/14_letters_to_self.sql` - Initial table creation
- `supabase/migrations/22_fix_open_self_letter_ambiguous_column.sql` - Function fixes
- `supabase/migrations/23_add_title_to_self_letters.sql` - Title field addition
- `supabase/migrations/24_update_open_self_letter_for_title.sql` - Function update

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/self-letters` | Create self letter |
| `GET` | `/self-letters?skip=0&limit=20` | List self letters |
| `POST` | `/self-letters/{id}/open` | Open self letter |
| `POST` | `/self-letters/{id}/reflection` | Submit reflection |

**See**: [Backend API Reference](../backend/API_REFERENCE.md#self-letters-endpoints)

---

## 🗄️ Database Schema

**Table**: `public.self_letters`

**Key Columns**:
- `id` (UUID, PK)
- `user_id` (UUID, FK → auth.users)
- `content` (TEXT, NOT NULL)
- `title` (TEXT, NULLABLE) ⭐ NEW
- `char_count` (INTEGER)
- `scheduled_open_at` (TIMESTAMPTZ)
- `opened_at` (TIMESTAMPTZ, NULLABLE)
- `mood` (TEXT, NULLABLE) - Emoji
- `life_area` (TEXT, NULLABLE) - Enum
- `city` (TEXT, NULLABLE)
- `reflection_answer` (TEXT, NULLABLE) - "yes" | "no" | "skipped"
- `reflected_at` (TIMESTAMPTZ, NULLABLE)
- `sealed` (BOOLEAN, DEFAULT TRUE)
- `created_at` (TIMESTAMPTZ)

**Indexes**:
- `idx_self_letters_user_id`
- `idx_self_letters_user_scheduled_open`
- `idx_self_letters_user_opened_at`
- `idx_self_letters_scheduled_open_at`

**RLS Policies**:
- INSERT: Users can only create their own letters
- SELECT: Users can only read their own letters (content visibility based on time)
- UPDATE: NONE (immutable)
- DELETE: NONE (irreversible)

---

## 🔐 Security Checklist

- ✅ RLS policies enforce ownership
- ✅ Ownership verified at API, service, and database levels
- ✅ Content hidden until scheduled time
- ✅ SQL injection prevention (parameterized queries)
- ✅ Input validation (length, time, enums)
- ✅ Immutability enforced (no UPDATE/DELETE policies)

---

## ⚡ Performance

**Estimated Performance** (500k+ users):
- List query: ~10ms
- Open query: ~15ms
- Create query: ~20ms

**Optimizations**:
- Proper database indexes
- Optimized COUNT queries
- Pagination support
- Efficient state management

---

## 🧪 Testing Checklist

**Creation**:
- [ ] Create via dedicated screen
- [ ] Create via regular flow (select "myself")
- [ ] Validate content length (20-500)
- [ ] Test optional fields (mood, life area, city)
- [ ] Verify title field works

**Viewing**:
- [ ] View sealed letter (lock screen)
- [ ] Verify countdown and context text
- [ ] Verify animations and badges

**Opening**:
- [ ] Open letter (after scheduled time)
- [ ] Submit reflection (all options)
- [ ] Verify reflection is immutable

**Security**:
- [ ] Verify users cannot access others' letters
- [ ] Verify content hidden before scheduled time
- [ ] Verify cannot open before scheduled time

**Integration**:
- [ ] Verify self letters don't appear in regular capsule lists
- [ ] Verify regular capsules unaffected

---

## 🐛 Common Issues

**Issue**: "Letter not found or access denied"
- **Fix**: Verify ownership (user_id matches)

**Issue**: "Letter cannot be opened before scheduled time"
- **Fix**: Wait until scheduled time or verify timezone

**Issue**: "Content is null in list response"
- **Fix**: Expected behavior for sealed letters

**Issue**: Backend error "column reference 'id' is ambiguous"
- **Fix**: Apply migration 22

**Issue**: Backend error "column 'title' does not exist"
- **Fix**: Apply migration 23

---

## 📚 Related Documentation

- **[Complete Documentation](./SELF_LETTERS.md)** - Comprehensive feature documentation
- **[Visual Flow Diagrams](./SELF_LETTERS_VISUAL_FLOW.md)** - User flow diagrams
- **[Frontend Implementation](../frontend/features/LETTERS_TO_SELF.md)** - Frontend details
- **[Backend API Reference](../backend/API_REFERENCE.md#self-letters-endpoints)** - API documentation
- **[Security Review](../reviews/SELF_LETTERS_SECURITY_AND_PERFORMANCE_REVIEW.md)** - Security analysis
- **[Existing Features Verification](../reviews/EXISTING_FEATURES_VERIFICATION.md)** - Integration verification

---

**Document Status**: ✅ Production Ready  
**Last Reviewed**: January 2025

