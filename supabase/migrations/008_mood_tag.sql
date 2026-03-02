-- Add mood_tag column to reports (optional free-form atmosphere tag)
ALTER TABLE reports ADD COLUMN IF NOT EXISTS mood_tag TEXT;
