-- ============================================================================
-- Supabase Storage Buckets Configuration
-- Production-ready storage structure for OpenOn
-- ============================================================================

-- ============================================================================
-- AVATARS BUCKET
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true, -- Public bucket for avatars
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- RLS Policies for avatars bucket
CREATE POLICY "Users can upload own avatar"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

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

CREATE POLICY "Users can delete own avatar"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Anyone can view avatars"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'avatars');

-- ============================================================================
-- CAPSULE ASSETS BUCKET
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'capsule_assets',
  'capsule_assets',
  false, -- Private bucket
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/webm', 'audio/mpeg', 'audio/wav']
) ON CONFLICT (id) DO NOTHING;

-- RLS Policies for capsule_assets bucket
CREATE POLICY "Users can upload capsule assets"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'capsule_assets'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

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

CREATE POLICY "Users can delete own capsule assets"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'capsule_assets'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================================
-- ANIMATIONS BUCKET
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'animations',
  'animations',
  true, -- Public bucket for animations
  52428800, -- 50MB limit
  ARRAY['video/mp4', 'video/webm', 'application/json', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- RLS Policies for animations bucket
CREATE POLICY "Anyone can view animations"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'animations');

CREATE POLICY "Admins can upload animations"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'animations'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

CREATE POLICY "Admins can update animations"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'animations'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

CREATE POLICY "Admins can delete animations"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'animations'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

-- ============================================================================
-- THEMES BUCKET
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'themes',
  'themes',
  true, -- Public bucket for themes
  1048576, -- 1MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/json']
) ON CONFLICT (id) DO NOTHING;

-- RLS Policies for themes bucket
CREATE POLICY "Anyone can view themes"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'themes');

CREATE POLICY "Admins can upload themes"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'themes'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

CREATE POLICY "Admins can update themes"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'themes'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

CREATE POLICY "Admins can delete themes"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'themes'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_id = auth.uid()
        AND premium_status = TRUE
    )
  );

-- ============================================================================
-- STORAGE PATH STRUCTURE
-- ============================================================================

/*
Storage Path Structure:

avatars/
  {user_id}/
    avatar.jpg

capsule_assets/
  {user_id}/
    {capsule_id}/
      image1.jpg
      video1.mp4
      audio1.mp3

animations/
  {animation_id}/
    preview.mp4
    config.json

themes/
  {theme_id}/
    preview.jpg
    config.json
*/

