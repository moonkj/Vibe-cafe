-- Expand sticker CHECK constraints to include new types (VIBE, HEALING, WORK)
-- Dynamically drop existing CHECK constraints referencing sticker columns

DO $$
DECLARE
  r RECORD;
BEGIN
  -- Drop CHECK constraints on reports.selected_sticker
  FOR r IN
    SELECT conname FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE t.relname = 'reports' AND n.nspname = 'public'
      AND c.contype = 'c'
      AND pg_get_constraintdef(c.oid) LIKE '%selected_sticker%'
  LOOP
    EXECUTE 'ALTER TABLE reports DROP CONSTRAINT ' || quote_ident(r.conname);
  END LOOP;

  -- Drop CHECK constraints on spots.representative_sticker
  FOR r IN
    SELECT conname FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE t.relname = 'spots' AND n.nspname = 'public'
      AND c.contype = 'c'
      AND pg_get_constraintdef(c.oid) LIKE '%representative_sticker%'
  LOOP
    EXECUTE 'ALTER TABLE spots DROP CONSTRAINT ' || quote_ident(r.conname);
  END LOOP;
END $$;

-- Re-add with expanded set
ALTER TABLE reports
  ADD CONSTRAINT reports_selected_sticker_check
  CHECK (selected_sticker IN ('STUDY', 'MEETING', 'RELAX', 'VIBE', 'HEALING', 'WORK'));

ALTER TABLE spots
  ADD CONSTRAINT spots_representative_sticker_check
  CHECK (representative_sticker IN ('STUDY', 'MEETING', 'RELAX', 'VIBE', 'HEALING', 'WORK'));
