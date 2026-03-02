-- Allow admin to DELETE spots (for dummy data cleanup)
-- Also allows deleting spots identified by DUMMY: prefix in google_place_id
-- or legacy [테스트] prefix in name.

CREATE POLICY "spots_delete_admin"
  ON spots FOR DELETE TO authenticated
  USING (
    auth.uid() = 'da2a8b72-a3c2-415b-bae5-63f2fa0b92a0'::uuid
    OR google_place_id LIKE 'DUMMY:%'
    OR name LIKE '%[테스트]%'
  );
