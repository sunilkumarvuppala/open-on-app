-- Migration: Rename audit_logs.details to metadata
-- This aligns the database schema with the trigger function and SQLAlchemy model

-- Check if details column exists and rename it to metadata
DO $$
BEGIN
  -- Check if 'details' column exists
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'audit_logs' 
      AND column_name = 'details'
  ) THEN
    -- Rename the column
    ALTER TABLE public.audit_logs 
    RENAME COLUMN details TO metadata;
    
    RAISE NOTICE 'Renamed audit_logs.details to audit_logs.metadata';
  ELSE
    -- If details doesn't exist, check if metadata already exists
    IF NOT EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = 'audit_logs' 
        AND column_name = 'metadata'
    ) THEN
      -- Create metadata column if neither exists
      ALTER TABLE public.audit_logs 
      ADD COLUMN metadata JSONB;
      
      RAISE NOTICE 'Created audit_logs.metadata column';
    ELSE
      RAISE NOTICE 'audit_logs.metadata column already exists';
    END IF;
  END IF;
END $$;

