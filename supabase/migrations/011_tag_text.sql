-- Add tag_text column for user-typed custom hashtag (stored without # prefix)
ALTER TABLE reports ADD COLUMN IF NOT EXISTS tag_text TEXT;
