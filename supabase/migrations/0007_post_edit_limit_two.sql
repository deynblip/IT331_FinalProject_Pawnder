-- 0007: approved adoption posts can be edited up to 2 times (was 3 in 0006)
--
-- Same rules as 0006: an approved post stays approved when edited, a
-- pending post stays pending, and a rejected post goes back to pending.
-- Only edits of approved posts are counted. Posts that already have 2 or
-- more edits cannot be edited again.
--
-- Run once in the SQL Editor (after 0006).

begin;

-- Same parameters as before, so the existing grants stay.
create or replace function public.update_adoption_post(
  p_id uuid, p_name text, p_animal_type text, p_age_text text, p_sex text,
  p_source public.pet_source, p_description text, p_health_info text, p_reason text,
  p_barangay text, p_city text, p_street text, p_photo_paths text[],
  p_contact_person text, p_contact_phone text, p_contact_email text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_post public.adoption_posts;
  v_approved boolean;
begin
  select * into v_post from public.adoption_posts where id = p_id for update;
  if v_post.id is null or v_post.removed_at is not null then raise exception 'Pet not found.'; end if;
  if v_post.poster_id <> v_uid then raise exception 'You can only edit your own posts.'; end if;

  v_approved := v_post.status = 'approved';
  if v_approved and v_post.edit_count >= 2 then
    raise exception 'You have used both edits for this post.';
  end if;

  update public.adoption_posts
  set name = trim(p_name), animal_type = p_animal_type, age_text = trim(p_age_text),
      sex = p_sex, source = p_source, description = trim(p_description),
      health_info = coalesce(trim(p_health_info), ''), reason = trim(p_reason),
      barangay = trim(p_barangay), city = trim(p_city), photo_paths = p_photo_paths,
      -- Approved stays approved (counted). Pending stays pending.
      -- Rejected goes back to pending for another review.
      status = case when v_approved then 'approved' else 'pending' end::public.post_status,
      rejection_reason = null,
      edit_count = v_post.edit_count + case when v_approved then 1 else 0 end,
      resubmitted = case when v_approved then v_post.resubmitted
                         else v_post.resubmitted or v_post.status <> 'pending' end
  where id = p_id;

  update public.adoption_post_contacts
  set street = coalesce(trim(p_street), ''), contact_person = trim(p_contact_person),
      contact_phone = trim(p_contact_phone), contact_email = trim(p_contact_email)
  where post_id = p_id;
end $$;

commit;