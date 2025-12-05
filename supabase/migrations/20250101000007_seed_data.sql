-- ============================================================================
-- Seed Data Migration
-- Sample data for development and testing
-- ============================================================================

-- THEMES SEED DATA
INSERT INTO public.themes (id, name, description, gradient_start, gradient_end, premium_only, preview_url)
VALUES
  (
    '00000000-0000-0000-0000-000000000001',
    'Deep Blue',
    'Deep blue-purple gradient, modern chat aesthetic',
    '#1D094B',
    '#3406CA',
    false,
    'https://example.com/themes/deep-blue-preview.jpg'
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'Galaxy Aurora',
    'Dark purple-blue with cyan/teal aurora colors',
    '#1C164E',
    '#2A1D6F',
    false,
    'https://example.com/themes/galaxy-aurora-preview.jpg'
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'Cosmic Void',
    'Deep black with vibrant purple/blue accents',
    '#1A0D2E',
    '#2D1B3D',
    false,
    'https://example.com/themes/cosmic-void-preview.jpg'
  ),
  (
    '00000000-0000-0000-0000-000000000004',
    'Nebula Dreams',
    'Dark purple with pink/cyan nebula colors',
    '#2D1B4E',
    '#3D2B5E',
    false,
    'https://example.com/themes/nebula-dreams-preview.jpg'
  ),
  (
    '00000000-0000-0000-0000-000000000005',
    'Stellar Night',
    'Dark blue with gold/cyan star colors',
    '#0F1B3A',
    '#1A2B4A',
    false,
    'https://example.com/themes/stellar-night-preview.jpg'
  ),
  (
    '00000000-0000-0000-0000-000000000006',
    'Premium Royal',
    'Exclusive royal purple and gold gradient',
    '#4A148C',
    '#7B1FA2',
    true,
    'https://example.com/themes/premium-royal-preview.jpg'
  )
ON CONFLICT (id) DO NOTHING;

-- ANIMATIONS SEED DATA
INSERT INTO public.animations (id, name, description, premium_only, preview_url)
VALUES
  (
    '00000000-0000-0000-0000-000000000101',
    'Sparkle Unfold',
    'Gentle sparkles as the letter unfolds',
    false,
    'https://example.com/animations/sparkle-unfold-preview.mp4'
  ),
  (
    '00000000-0000-0000-0000-000000000102',
    'Aurora Reveal',
    'Aurora-like light reveal animation',
    false,
    'https://example.com/animations/aurora-reveal-preview.mp4'
  ),
  (
    '00000000-0000-0000-0000-000000000103',
    'Magic Dust',
    'Magical dust particles floating around',
    false,
    'https://example.com/animations/magic-dust-preview.mp4'
  ),
  (
    '00000000-0000-0000-0000-000000000104',
    'Premium Galaxy',
    'Exclusive galaxy-themed reveal animation',
    true,
    'https://example.com/animations/premium-galaxy-preview.mp4'
  ),
  (
    '00000000-0000-0000-0000-000000000105',
    'Premium Cosmic',
    'Exclusive cosmic explosion reveal',
    true,
    'https://example.com/animations/premium-cosmic-preview.mp4'
  )
ON CONFLICT (id) DO NOTHING;

