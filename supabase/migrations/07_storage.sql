-- ============================================================================
-- Storage Buckets Migration
-- Storage bucket configuration with RLS policies
-- ============================================================================

-- Avatars bucket (public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- RLS Policies for avatars bucket
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'avatars');

-- Capsule assets bucket (private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'capsule_assets',
  'capsule_assets',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/webm', 'audio/mpeg', 'audio/wav']
) ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- RLS Policies for capsule_assets bucket
DROP POLICY IF EXISTS "Users can upload capsule assets" ON storage.objects;
CREATE POLICY "Users can upload capsule assets"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'capsule_assets'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Senders can view own capsule assets" ON storage.objects;
CREATE POLICY "Senders can view own capsule assets"
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'capsule_assets'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.capsules c
        WHERE c.sender_id = auth.uid()
          AND c.id::text = (storage.foldername(name))[2]
      )
    )
  );

DROP POLICY IF EXISTS "Recipients can view received capsule assets" ON storage.objects;
CREATE POLICY "Recipients can view received capsule assets"
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'capsule_assets'
    AND EXISTS (
      SELECT 1 FROM public.capsules c
      JOIN public.recipients r ON c.recipient_id = r.id
      WHERE r.owner_id = auth.uid()
        AND c.id::text = (storage.foldername(name))[2]
    )
  );

DROP POLICY IF EXISTS "Users can delete own capsule assets" ON storage.objects;
CREATE POLICY "Users can delete own capsule assets"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'capsule_assets'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Animations bucket (public, admins can upload)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'animations',
  'animations',
  true,
  52428800,
  ARRAY['video/mp4', 'video/webm', 'application/json', 'image/gif']
) ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- RLS Policies for animations bucket
DROP POLICY IF EXISTS "Anyone can view animations" ON storage.objects;
CREATE POLICY "Anyone can view animations"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'animations');

DROP POLICY IF EXISTS "Admins can upload animations" ON storage.objects;
CREATE POLICY "Admins can upload animations"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'animations'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Admins can update animations" ON storage.objects;
CREATE POLICY "Admins can update animations"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'animations'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Admins can delete animations" ON storage.objects;
CREATE POLICY "Admins can delete animations"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'animations'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

-- Themes bucket (public, admins can upload)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'themes',
  'themes',
  true,
  1048576,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/json']
) ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- RLS Policies for themes bucket
DROP POLICY IF EXISTS "Anyone can view themes" ON storage.objects;
CREATE POLICY "Anyone can view themes"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'themes');

DROP POLICY IF EXISTS "Admins can upload themes" ON storage.objects;
CREATE POLICY "Admins can upload themes"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'themes'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Admins can update themes" ON storage.objects;
CREATE POLICY "Admins can update themes"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'themes'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

DROP POLICY IF EXISTS "Admins can delete themes" ON storage.objects;
CREATE POLICY "Admins can delete themes"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'themes'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND is_admin = TRUE
    )
  );

