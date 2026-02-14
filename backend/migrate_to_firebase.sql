-- Migration script to update existing documents table to use Firebase Storage
-- Run this if you already have data in the documents table

-- Add new columns for Firebase Storage
ALTER TABLE documents ADD COLUMN IF NOT EXISTS firebase_url TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS firebase_path TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_type VARCHAR(100);

-- Rename old file_path column to file_path_old (backup)
ALTER TABLE documents RENAME COLUMN file_path TO file_path_old;

-- Make firebase_url and firebase_path NOT NULL after migration
-- (You'll need to migrate existing data first before running these)
-- ALTER TABLE documents ALTER COLUMN firebase_url SET NOT NULL;
-- ALTER TABLE documents ALTER COLUMN firebase_path SET NOT NULL;

-- Drop old column after confirming migration is successful
-- ALTER TABLE documents DROP COLUMN file_path_old;
