-- ============================================================================
-- Views Migration
-- Safe views for data access
-- ============================================================================

-- Recipient-safe capsules view (hides sender for anonymous messages)
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

-- Inbox view (capsules received by current user)
CREATE OR REPLACE VIEW public.inbox_view AS
SELECT 
  c.*,
  r.owner_id AS current_user_id
FROM public.recipient_safe_capsules_view c
JOIN public.recipients r ON c.recipient_id = r.id
WHERE r.owner_id = auth.uid()
  AND c.deleted_at IS NULL;

-- Outbox view (capsules sent by current user)
CREATE OR REPLACE VIEW public.outbox_view AS
SELECT 
  c.*
FROM public.capsules c
WHERE c.sender_id = auth.uid()
  AND c.deleted_at IS NULL;

