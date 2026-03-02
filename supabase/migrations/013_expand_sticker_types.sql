-- Migration 013: Expand sticker CHECK constraints to support 18 sticker types

-- Drop old constraints on reports
ALTER TABLE reports
  DROP CONSTRAINT IF EXISTS reports_selected_sticker_check;

-- Drop old constraints on spots
ALTER TABLE spots
  DROP CONSTRAINT IF EXISTS spots_representative_sticker_check;

-- Add new constraints with all 18 sticker values
ALTER TABLE reports
  ADD CONSTRAINT reports_selected_sticker_check
  CHECK (selected_sticker IN (
    'STUDY', 'WORK', 'STUDY_ZONE', 'NOMAD',
    'MEETING', 'VIBE', 'DATE', 'GATHERING',
    'FAMILY', 'RELAX', 'HEALING', 'COZY',
    'INSTA', 'RETRO', 'MINIMAL', 'GREEN',
    'PEAK', 'MUSIC'
  ));

ALTER TABLE spots
  ADD CONSTRAINT spots_representative_sticker_check
  CHECK (representative_sticker IN (
    'STUDY', 'WORK', 'STUDY_ZONE', 'NOMAD',
    'MEETING', 'VIBE', 'DATE', 'GATHERING',
    'FAMILY', 'RELAX', 'HEALING', 'COZY',
    'INSTA', 'RETRO', 'MINIMAL', 'GREEN',
    'PEAK', 'MUSIC'
  ));
