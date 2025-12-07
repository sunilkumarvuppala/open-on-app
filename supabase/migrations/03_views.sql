-- ============================================================================
-- Views Migration
-- Safe views for data access (inherit RLS from underlying tables)
-- ============================================================================

-- ============================================================================
-- VIEW: recipient_safe_capsules_view
-- ============================================================================
-- WHAT: Capsules view that hides sender information for anonymous messages
-- WHY: Protects sender identity when is_anonymous = TRUE.
--      Recipients should query this view instead of capsules table directly
--      to ensure anonymous sender protection is enforced.
-- USAGE EXAMPLES:
--   - Get recipient's capsules: SELECT * FROM recipient_safe_capsules_view WHERE recipient_id = '...'
--   - Anonymous shows 'Anonymous': SELECT sender_name FROM recipient_safe_capsules_view WHERE is_anonymous = TRUE
--   - Non-anonymous shows real name: SELECT sender_name FROM recipient_safe_capsules_view WHERE is_anonymous = FALSE
-- BEHAVIOR:
--   - If is_anonymous = TRUE: sender_id = NULL, sender_name = 'Anonymous', sender_avatar_url = NULL
--   - If is_anonymous = FALSE: Shows actual sender_id, sender_name, sender_avatar_url
--   - Excludes soft-deleted capsules (deleted_at IS NULL)
-- ============================================================================
CREATE OR REPLACE VIEW public.recipient_safe_capsules_view AS
SELECT 
  c.id,
  CASE 
    WHEN c.is_anonymous = TRUE THEN NULL
    ELSE c.sender_id
  END AS sender_id,
  CASE 
    WHEN c.is_anonymous = TRUE THEN 'Anonymous'
    ELSE up.full_name
  END AS sender_name,
  CASE 
    WHEN c.is_anonymous = TRUE THEN NULL
    ELSE up.avatar_url
  END AS sender_avatar_url,
  c.recipient_id,
  r.name AS recipient_name,
  c.is_anonymous,
  c.is_disappearing,
  c.disappearing_after_open_seconds,
  c.unlocks_at,
  c.opened_at,
  c.expires_at,
  c.title,
  c.body_text,
  c.body_rich_text,
  c.theme_id,
  c.animation_id,
  c.status,
  c.deleted_at,
  c.created_at,
  c.updated_at
FROM public.capsules c
LEFT JOIN public.recipients r ON c.recipient_id = r.id
LEFT JOIN public.user_profiles up ON c.sender_id = up.user_id
WHERE c.deleted_at IS NULL;

-- ============================================================================
-- VIEW: inbox_view
-- ============================================================================
-- WHAT: Capsules received by current authenticated user (inbox)
-- WHY: Simplifies inbox queries by automatically filtering by auth.uid().
--      Uses recipient_safe_capsules_view to ensure anonymous protection.
--      Provides single query for inbox screen instead of complex JOINs.
-- USAGE EXAMPLES:
--   - Get inbox: SELECT * FROM inbox_view ORDER BY created_at DESC
--   - Get unopened: SELECT * FROM inbox_view WHERE opened_at IS NULL
--   - Get ready to open: SELECT * FROM inbox_view WHERE status = 'ready'
-- BEHAVIOR:
--   - Automatically filters by auth.uid() (current logged-in user)
--   - Uses recipient_safe_capsules_view (anonymous protection)
--   - Excludes soft-deleted capsules
--   - Includes current_user_id column for convenience
-- ============================================================================
CREATE OR REPLACE VIEW public.inbox_view AS
SELECT 
  c.*,
  r.owner_id AS current_user_id
FROM public.recipient_safe_capsules_view c
JOIN public.recipients r ON c.recipient_id = r.id
WHERE r.owner_id = auth.uid()
  AND c.deleted_at IS NULL;

-- ============================================================================
-- VIEW: outbox_view
-- ============================================================================
-- WHAT: Capsules sent by current authenticated user (outbox)
-- WHY: Simplifies outbox queries by automatically filtering by auth.uid().
--      Provides single query for outbox screen instead of complex WHERE clauses.
--      Senders see full information (no anonymous protection needed).
-- USAGE EXAMPLES:
--   - Get outbox: SELECT * FROM outbox_view ORDER BY created_at DESC
--   - Get unopened sent: SELECT * FROM outbox_view WHERE opened_at IS NULL
--   - Get opened sent: SELECT * FROM outbox_view WHERE opened_at IS NOT NULL
-- BEHAVIOR:
--   - Automatically filters by auth.uid() (current logged-in user)
--   - Queries capsules table directly (senders see full info)
--   - Excludes soft-deleted capsules
-- ============================================================================
CREATE OR REPLACE VIEW public.outbox_view AS
SELECT 
  c.*
FROM public.capsules c
WHERE c.sender_id = auth.uid()
  AND c.deleted_at IS NULL;

