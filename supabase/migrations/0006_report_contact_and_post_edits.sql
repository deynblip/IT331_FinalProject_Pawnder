-- 0006: report contact details and adoption post edit limit (Batch 9)
--
--  * Stray reports: the reporter's name, contact number and email, so the
--    owner of a lost pet can contact them. Required for new reports and
--    edits. Older reports have none (null).
--  * Adoption posts: editing an APPROVED post keeps it approved (no admin
--    re-review), up to 3 times. A pending post stays pending; a rejected
--    post goes back to pending (resubmit). Only edits of approved posts
--    are counted.
--
-- Run once in the SQL Editor.

begin;

-- ---------------------------------------------------------------- Stray reports

alter table public.stray_reports
  add column contact_name text
    check (contact_name is null or char_length(trim(contact_name)) between 1 and 80),
  add column contact_phone text
    check (contact_phone is null or contact_phone ~ '^[0-9 +()-]{7,20}$'),
  add column contact_email text
    check (contact_email is null or contact_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9-]+(\.[A-Z0-9-]+)+$');

drop function public.create_stray_report(
  text, public.urgency, text, text[], double precision, double precision, text, boolean);

create function public.create_stray_report(
  p_animal_type text, p_urgency public.urgency, p_description text,
  p_photo_paths text[], p_latitude double precision, p_longitude double precision,
  p_address text, p_possibly_lost_pet boolean default false,
  p_contact_name text default null, p_contact_phone text default null,
  p_contact_email text default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_id uuid;
begin
  if coalesce(trim(p_contact_name), '') = ''
     or coalesce(trim(p_contact_phone), '') = ''
     or coalesce(trim(p_contact_email), '') = '' then
    raise exception 'Please enter your name, contact number and email.';
  end if;

  insert into public.stray_reports
    (reporter_id, animal_type, urgency, description, photo_paths,
     latitude, longitude, address, possibly_lost_pet,
     contact_name, contact_phone, contact_email)
  values
    (v_uid, p_animal_type, p_urgency, coalesce(trim(p_description), ''),
     coalesce(p_photo_paths, '{}'), p_latitude, p_longitude, trim(p_address),
     coalesce(p_possibly_lost_pet, false),
     trim(p_contact_name), trim(p_contact_phone), trim(p_contact_email))
  returning id into v_id;
  return v_id;
end $$;

drop function public.update_my_report(uuid, text, public.urgency, text, text[], boolean);

create function public.update_my_report(
  p_id uuid,
  p_animal_type text,
  p_urgency public.urgency,
  p_description text,
  p_photo_paths text[],
  p_possibly_lost_pet boolean default false,
  p_contact_name text default null,
  p_contact_phone text default null,
  p_contact_email text default null
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_rep public.stray_reports;
begin
  select * into v_rep from public.stray_reports
  where id = p_id and removed_at is null for update;

  if v_rep.id is null then raise exception 'Report not found.'; end if;
  if v_rep.reporter_id <> v_uid then raise exception 'You can only edit your own report.'; end if;
  if v_rep.rescue_status = 'rescued' then
    raise exception 'This animal was already rescued, so the report can no longer be edited.';
  end if;
  if exists (select 1 from public.rescue_responses
             where report_id = p_id and state = 'active') then
    raise exception 'Someone is responding to this report, so it cannot be edited right now.';
  end if;
  if coalesce(trim(p_contact_name), '') = ''
     or coalesce(trim(p_contact_phone), '') = ''
     or coalesce(trim(p_contact_email), '') = '' then
    raise exception 'Please enter your name, contact number and email.';
  end if;

  update public.stray_reports
  set animal_type       = p_animal_type,
      urgency           = p_urgency,
      description       = coalesce(trim(p_description), ''),
      photo_paths       = coalesce(p_photo_paths, '{}'),
      possibly_lost_pet = coalesce(p_possibly_lost_pet, false),
      contact_name      = trim(p_contact_name),
      contact_phone     = trim(p_contact_phone),
      contact_email     = trim(p_contact_email)
  where id = p_id;
end $$;

-- Only logged-in users can call them (same as the other functions).
revoke execute on function public.create_stray_report(
  text, public.urgency, text, text[], double precision, double precision, text, boolean,
  text, text, text) from public, anon;
grant execute on function public.create_stray_report(
  text, public.urgency, text, text[], double precision, double precision, text, boolean,
  text, text, text) to authenticated;

revoke execute on function public.update_my_report(
  uuid, text, public.urgency, text, text[], boolean, text, text, text) from public, anon;
grant execute on function public.update_my_report(
  uuid, text, public.urgency, text, text[], boolean, text, text, text) to authenticated;

-- ---------------------------------------------------------------- Adoption posts

alter table public.adoption_posts
  add column edit_count int not null default 0;

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
  if v_approved and v_post.edit_count >= 3 then
    raise exception 'You have used all 3 edits for this post.';
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