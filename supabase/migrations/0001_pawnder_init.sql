-- =====================================================================
-- PAWNDER DATABASE SETUP  (migration 0001)
-- =====================================================================
-- Run this ONCE in Supabase: Dashboard > SQL Editor > New query >
-- paste everything > Run.
--
-- What it creates:
--   1. Types (the fixed choices, e.g. Urgent / Needs Help / Sighted)
--   2. Tables (where the data is saved)
--   3. Helper functions (private, the app cannot call these directly)
--   4. App functions (the ONLY way the app can change data; each one
--      checks the rules first, e.g. "only the admin can screen")
--   5. Security rules (Row Level Security: who can READ which rows)
--   6. Photo storage buckets
--
-- The app can READ tables directly (limited by the security rules) but
-- it can only WRITE through the app functions in part 4.
--
-- Everything runs as ONE transaction: if any line fails, NOTHING is
-- saved, so you can fix the problem and run the whole file again.
-- =====================================================================

begin;


-- =====================================================================
-- 1. TYPES (fixed choices)
-- =====================================================================

create type public.user_role as enum ('user', 'admin');

create type public.rescuer_status as enum ('pending', 'verified', 'rejected');

create type public.urgency as enum ('urgent', 'needs_help', 'sighted');

create type public.rescue_status as enum ('needs_rescue', 'in_progress', 'rescued');

create type public.rescue_outcome as enum (
  'rescued_on_site', 'brought_to_vet_shelter', 'unable_to_locate'
);

create type public.responder_role as enum ('lead', 'assisting');

-- active    = "I'm on my way!" and still responding
-- cancelled = "Cancel / I can't make it" (counts against the track record)
-- finished  = the rescue was closed (rescued, or "Unable to locate")
-- closed    = the report was removed by an admin (not counted)
create type public.response_state as enum ('active', 'cancelled', 'finished', 'closed');

create type public.post_status as enum ('pending', 'approved', 'rejected');

create type public.pet_source as enum ('rescued_stray', 'rehoming');

create type public.application_status as enum (
  'pending_screening', 'forwarded_to_owner', 'approved', 'rejected'
);

create type public.report_target as enum ('adoption_post', 'stray_report');

create type public.report_reason as enum (
  'spam', 'inappropriate', 'misleading', 'scam', 'other'
);

create type public.content_report_status as enum ('pending', 'removed', 'dismissed');

create type public.notification_type as enum (
  'rescue_response',
  'application_submitted',   -- (admins) a new application needs screening
  'application_for_owner',   -- (poster) a forwarded application needs a decision
  'application_forwarded',
  'application_approved',
  'application_rejected',
  'post_approved',
  'post_removed',            -- also used for "post not approved"
  'rescuer_approved',
  'rescuer_rejected',
  'rescuer_flagged'          -- (admins) a Verified Rescuer has a high cancel rate
);


-- =====================================================================
-- 2. TABLES
-- =====================================================================

-- One row per account. Created automatically when someone signs up.
create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  full_name     text not null check (char_length(trim(full_name)) between 1 and 80),
  avatar_path   text,
  role          public.user_role not null default 'user',
  is_restricted boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Verified Rescuer applications (from Sign Up or Profile).
create table public.rescuer_applications (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete restrict,
  applicant_name   text not null,
  applicant_email  text not null,
  organization     text not null check (char_length(trim(organization)) between 1 and 120),
  role_in_org      text not null check (char_length(trim(role_in_org)) between 1 and 80),
  contact_person   text not null check (char_length(trim(contact_person)) between 1 and 80),
  contact_number   text not null check (contact_number ~ '^[0-9 +()-]{7,20}$'),
  official_page    text not null check (char_length(trim(official_page)) between 4 and 200),
  status           public.rescuer_status not null default 'pending',
  rejection_reason text,
  reviewed_by      uuid references public.profiles (id),
  reviewed_at      timestamptz,
  flag_notified_at timestamptz,   -- admins were told about a high cancel rate
  submitted_at     timestamptz not null default now(),
  constraint rescuer_reason_when_rejected
    check (status <> 'rejected' or rejection_reason is not null)
);
-- Only ONE open (pending or verified) application per user.
create unique index rescuer_one_open_per_user
  on public.rescuer_applications (user_id) where status in ('pending', 'verified');

-- Stray animal reports.
create table public.stray_reports (
  id                uuid primary key default gen_random_uuid(),
  reporter_id       uuid not null references public.profiles (id) on delete restrict,
  animal_type       text not null check (animal_type in ('Dog', 'Cat', 'Other')),
  urgency           public.urgency not null,
  description       text not null default '' check (char_length(description) <= 1000),
  photo_paths       text[] not null default '{}' check (cardinality(photo_paths) <= 5),
  latitude          double precision not null check (latitude between -90 and 90),
  longitude         double precision not null check (longitude between -180 and 180),
  address           text not null check (char_length(trim(address)) between 1 and 300),
  possibly_lost_pet boolean not null default false,
  rescue_status     public.rescue_status not null default 'needs_rescue',
  outcome           public.rescue_outcome,
  closed_by         uuid references public.profiles (id),
  closed_at         timestamptz,
  removed_at        timestamptz,   -- set when an admin removes it (kept for records)
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index stray_reports_reporter_idx on public.stray_reports (reporter_id);
create index stray_reports_status_idx on public.stray_reports (rescue_status);

-- "I'm on my way!" responses. This table is also the TRACK RECORD
-- (completed rescues, cancellations) used for trust levels.
create table public.rescue_responses (
  id             uuid primary key default gen_random_uuid(),
  report_id      uuid not null references public.stray_reports (id) on delete restrict,
  responder_id   uuid not null references public.profiles (id) on delete restrict,
  role           public.responder_role not null default 'assisting',
  state          public.response_state not null default 'active',
  organization   text,          -- Verified Rescuer's organization when they responded
  checked_in_at  timestamptz,   -- "I've Arrived"
  outcome        public.rescue_outcome,  -- only on the row of the person who closed it
  joined_at      timestamptz not null default now(),
  last_update_at timestamptz not null default now(),
  ended_at       timestamptz
);
-- No duplicate ACTIVE response from the same person on the same report.
create unique index rescue_one_active_per_report
  on public.rescue_responses (report_id, responder_id) where state = 'active';
create index rescue_responses_responder_idx on public.rescue_responses (responder_id);

-- Adoption posts. The public location is barangay + city + province;
-- the street and the contact details are kept in adoption_post_contacts.
create table public.adoption_posts (
  id               uuid primary key default gen_random_uuid(),
  poster_id        uuid not null references public.profiles (id) on delete restrict,
  name             text not null check (char_length(trim(name)) between 1 and 30),
  animal_type      text not null check (animal_type in ('Dog', 'Cat', 'Other')),
  age_text         text not null check (char_length(trim(age_text)) between 1 and 20),
  sex              text not null check (sex in ('Male', 'Female')),
  source           public.pet_source not null default 'rescued_stray',
  description      text not null check (char_length(trim(description)) between 10 and 500),
  health_info      text not null default '' check (char_length(health_info) <= 300),
  reason           text not null check (char_length(trim(reason)) between 1 and 300),
  barangay         text not null check (char_length(trim(barangay)) between 1 and 80),
  city             text not null check (char_length(trim(city)) between 1 and 80),
  province         text not null default 'Batangas',
  location         text generated always as (barangay || ', ' || city || ', ' || province) stored,
  photo_paths      text[] not null check (cardinality(photo_paths) between 1 and 5),
  rescued_by       text,          -- "Rescued by [Organization]" (Verified Rescuers)
  status           public.post_status not null default 'pending',
  rejection_reason text,
  resubmitted      boolean not null default false,  -- edited after a review
  reviewed_by      uuid references public.profiles (id),
  reviewed_at      timestamptz,
  removed_at       timestamptz,   -- removed by the poster or an admin (kept for records)
  removed_by_admin boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint post_reason_when_rejected
    check (status <> 'rejected' or rejection_reason is not null)
);
create index adoption_posts_poster_idx on public.adoption_posts (poster_id);
create index adoption_posts_status_idx on public.adoption_posts (status);

-- Contact details of a post. Separate table so that ONLY the poster, admins
-- and applicants whose application was forwarded can see them.
create table public.adoption_post_contacts (
  post_id        uuid primary key references public.adoption_posts (id) on delete cascade,
  street         text not null default '' check (char_length(street) <= 150),
  contact_person text not null check (char_length(trim(contact_person)) between 1 and 80),
  contact_phone  text not null check (contact_phone ~ '^[0-9 +()-]{7,20}$'),
  contact_email  text not null check (contact_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9-]+(\.[A-Z0-9-]+)+$')
);

-- Adoption applications.
create table public.adoption_applications (
  id                  uuid primary key default gen_random_uuid(),
  post_id             uuid not null references public.adoption_posts (id) on delete restrict,
  applicant_id        uuid not null references public.profiles (id) on delete restrict,
  full_name           text not null check (char_length(trim(full_name)) between 1 and 60),
  phone               text not null check (phone ~ '^[0-9 +()-]{7,20}$'),
  email               text not null check (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9-]+(\.[A-Z0-9-]+)+$'),
  province            text not null default 'Batangas',
  city                text not null check (char_length(trim(city)) between 1 and 80),
  barangay            text not null check (char_length(trim(barangay)) between 1 and 80),
  street              text not null default '' check (char_length(street) <= 150),
  home_environment    text not null check (char_length(trim(home_environment)) between 1 and 300),
  household_members   text not null check (char_length(trim(household_members)) between 1 and 200),
  previous_pets       text not null check (char_length(trim(previous_pets)) between 1 and 200),
  care_experience     text not null check (char_length(trim(care_experience)) between 1 and 300),
  reason_for_adopting text check (char_length(reason_for_adopting) <= 300),  -- optional
  valid_id_agreed     boolean not null check (valid_id_agreed),  -- must be ticked
  status              public.application_status not null default 'pending_screening',
  rejection_reason    text,
  screened_by         uuid references public.profiles (id),
  screened_at         timestamptz,
  forwarded_at        timestamptz,   -- set when the admin forwards it to the poster
  decided_at          timestamptz,   -- the poster's final decision
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint one_application_per_pet unique (post_id, applicant_id)
);
create index applications_applicant_idx on public.adoption_applications (applicant_id);
create index applications_status_idx on public.adoption_applications (status);

-- "Report Post" (reported content).
create table public.content_reports (
  id               uuid primary key default gen_random_uuid(),
  reporter_id      uuid not null references public.profiles (id) on delete restrict,
  target_type      public.report_target not null,
  adoption_post_id uuid references public.adoption_posts (id) on delete restrict,
  stray_report_id  uuid references public.stray_reports (id) on delete restrict,
  target_title     text not null check (char_length(trim(target_title)) between 1 and 80),
  reason           public.report_reason not null,
  details          text not null default '' check (char_length(details) <= 500),
  status           public.content_report_status not null default 'pending',
  admin_action     text,
  reviewed_by      uuid references public.profiles (id),
  reviewed_at      timestamptz,
  created_at       timestamptz not null default now(),
  -- exactly one target, and it matches target_type
  constraint content_report_one_target check (
    (target_type = 'adoption_post' and adoption_post_id is not null and stray_report_id is null)
    or (target_type = 'stray_report' and stray_report_id is not null and adoption_post_id is null)
  )
);
-- The same user can't report the same thing twice while it is still pending.
create unique index content_reports_once_post
  on public.content_reports (reporter_id, adoption_post_id) where status = 'pending';
create unique index content_reports_once_stray
  on public.content_reports (reporter_id, stray_report_id) where status = 'pending';

-- Notifications (created only by the database).
create table public.notifications (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  type         public.notification_type not null,
  title        text not null,
  message      text not null,
  target_id    text,   -- the report / post / application to open when tapped
  is_read      boolean not null default false,
  created_at   timestamptz not null default now()
);
create index notifications_recipient_idx on public.notifications (recipient_id, created_at desc);


-- =====================================================================
-- 3. HELPER FUNCTIONS (private schema: the app cannot call these)
-- =====================================================================

create schema if not exists private;
grant usage on schema private to authenticated;

-- Keeps updated_at current.
create function private.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_touch before update on public.profiles
  for each row execute function private.touch_updated_at();
create trigger stray_reports_touch before update on public.stray_reports
  for each row execute function private.touch_updated_at();
create trigger adoption_posts_touch before update on public.adoption_posts
  for each row execute function private.touch_updated_at();
create trigger applications_touch before update on public.adoption_applications
  for each row execute function private.touch_updated_at();

-- Is the logged-in user an admin?
create function private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- Organization name if the user is a Verified Rescuer, otherwise null.
create function private.rescuer_org(p_user uuid) returns text
language sql stable security definer set search_path = '' as $$
  select organization from public.rescuer_applications
  where user_id = p_user and status = 'verified'
  limit 1;
$$;

-- Stops logged-out or restricted users. Returns the user's id.
create function private.require_user() returns uuid
language plpgsql stable security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Please log in first.';
  end if;
  if exists (select 1 from public.profiles where id = v_uid and is_restricted) then
    raise exception 'Your account is restricted. Please contact the Pawnder team.';
  end if;
  return v_uid;
end $$;

create function private.require_admin() returns uuid
language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.is_admin() then
    raise exception 'Only an admin can do this.';
  end if;
  return auth.uid();
end $$;

-- Used by the security rules (they bypass the rules themselves, which
-- avoids "infinite recursion" between the posts and applications rules).
create function private.owns_post(p_post uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.adoption_posts
                 where id = p_post and poster_id = auth.uid());
$$;

create function private.applied_to(p_post uuid, p_forwarded_only boolean) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.adoption_applications
                 where post_id = p_post and applicant_id = auth.uid()
                   and (not p_forwarded_only or forwarded_at is not null));
$$;

-- Distance in meters between two GPS points (haversine formula).
create function private.distance_m(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision
) returns double precision
language sql immutable as $$
  select 2 * 6371000 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2)
    + cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lng2 - lng1) / 2), 2)
  ));
$$;

-- Sends a notification to one user.
create function private.notify(
  p_recipient uuid, p_type public.notification_type,
  p_title text, p_message text, p_target text default null
) returns void
language sql security definer set search_path = '' as $$
  insert into public.notifications (recipient_id, type, title, message, target_id)
  values (p_recipient, p_type, p_title, p_message, p_target);
$$;

-- Sends a notification to every admin.
create function private.notify_admins(
  p_type public.notification_type, p_title text, p_message text, p_target text default null
) returns void
language sql security definer set search_path = '' as $$
  insert into public.notifications (recipient_id, type, title, message, target_id)
  select id, p_type, p_title, p_message, p_target
  from public.profiles where role = 'admin';
$$;

-- Track record numbers for one user.
create function private.stats_for(p_user uuid)
returns table (responses int, rescues int, cancelled int, unable_to_locate int, check_ins int)
language sql stable security definer set search_path = '' as $$
  select
    count(*)::int,
    count(*) filter (where state = 'finished' and checked_in_at is not null
                     and (outcome is null or outcome <> 'unable_to_locate'))::int,
    count(*) filter (where state = 'cancelled')::int,
    count(*) filter (where outcome = 'unable_to_locate')::int,
    count(*) filter (where checked_in_at is not null)::int
  from public.rescue_responses
  where responder_id = p_user and state in ('cancelled', 'finished');
$$;

-- After someone leaves a report: if nobody is left it goes back to
-- Needs Rescue; if the lead left, a Verified Rescuer becomes the lead.
create function private.after_responder_left(p_report uuid) returns public.rescue_status
language plpgsql security definer set search_path = '' as $$
declare
  v_next uuid;
begin
  if not exists (select 1 from public.rescue_responses
                 where report_id = p_report and state = 'active') then
    update public.stray_reports set rescue_status = 'needs_rescue'
    where id = p_report and rescue_status = 'in_progress';
    return 'needs_rescue';
  end if;

  if not exists (select 1 from public.rescue_responses
                 where report_id = p_report and state = 'active' and role = 'lead') then
    select id into v_next from public.rescue_responses
    where report_id = p_report and state = 'active' and organization is not null
    order by joined_at limit 1;
    if v_next is not null then
      update public.rescue_responses set role = 'lead' where id = v_next;
    end if;
  end if;
  return 'in_progress';
end $$;

-- Tells the admins (once) when a Verified Rescuer's cancel rate is high:
-- at least 3 responses and 30% or more cancelled.
create function private.check_cancel_rate(p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  s record;
  v_app public.rescuer_applications;
  v_high boolean;
begin
  select * into v_app from public.rescuer_applications
  where user_id = p_user and status = 'verified';
  if v_app.id is null then return; end if;

  select * into s from private.stats_for(p_user);
  v_high := s.responses >= 3 and s.cancelled::numeric / s.responses >= 0.30;

  if not v_high then
    update public.rescuer_applications set flag_notified_at = null where id = v_app.id;
  elsif v_app.flag_notified_at is null then
    update public.rescuer_applications set flag_notified_at = now() where id = v_app.id;
    perform private.notify_admins(
      'rescuer_flagged', 'Verified Rescuer flagged',
      v_app.applicant_name || ' (' || v_app.organization || ') has cancelled '
        || s.cancelled || ' of ' || s.responses || ' responses ('
        || round(s.cancelled * 100.0 / s.responses) || '%). Review their badge in Rescuers.',
      v_app.id::text);
  end if;
end $$;

-- Closes the waiting applications of a post (used when a post is removed
-- or another applicant was picked) and tells each applicant.
create function private.close_waiting_applications(
  p_post uuid, p_reason text, p_except uuid default null
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  a record;
begin
  for a in
    update public.adoption_applications ap
    set status = 'rejected', rejection_reason = p_reason, decided_at = now()
    from public.adoption_posts p
    where ap.post_id = p_post and p.id = ap.post_id
      and ap.status in ('pending_screening', 'forwarded_to_owner')
      and ap.id is distinct from p_except
    returning ap.id, ap.applicant_id, p.name
  loop
    perform private.notify(a.applicant_id, 'application_rejected',
      'Application not approved',
      'Your application for ' || a.name || ' was not approved. Reason: ' || p_reason,
      a.id::text);
  end loop;
end $$;

-- Creates the profile when someone signs up. If they chose
-- "Professional Rescuer", their Verified Rescuer application is saved too.
create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_name text := coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
                          split_part(new.email, '@', 1));
  r jsonb := new.raw_user_meta_data -> 'rescuer_application';
begin
  insert into public.profiles (id, full_name) values (new.id, left(v_name, 80));

  if r is not null then
    insert into public.rescuer_applications
      (user_id, applicant_name, applicant_email, organization, role_in_org,
       contact_person, contact_number, official_page)
    values
      (new.id, left(v_name, 80), new.email, trim(r ->> 'organization'),
       trim(r ->> 'role_in_org'), trim(r ->> 'contact_person'),
       trim(r ->> 'contact_number'), trim(r ->> 'official_page'));
  end if;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();


-- =====================================================================
-- 4. APP FUNCTIONS (called from Flutter with supabase.rpc('name', ...))
-- =====================================================================

-- ---------------------------------------------------------------- Profile

create function public.update_my_profile(p_full_name text, p_avatar_path text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
begin
  update public.profiles
  set full_name = trim(p_full_name), avatar_path = p_avatar_path
  where id = v_uid;
end $$;

-- ---------------------------------------------------------------- Verified Rescuers

create function public.submit_rescuer_application(
  p_organization text, p_role_in_org text, p_contact_person text,
  p_contact_number text, p_official_page text
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_id uuid;
begin
  if exists (select 1 from public.rescuer_applications
             where user_id = v_uid and status = 'pending') then
    raise exception 'You already have an application waiting for review.';
  end if;
  if exists (select 1 from public.rescuer_applications
             where user_id = v_uid and status = 'verified') then
    raise exception 'You are already a Verified Rescuer.';
  end if;

  insert into public.rescuer_applications
    (user_id, applicant_name, applicant_email, organization, role_in_org,
     contact_person, contact_number, official_page)
  select v_uid, p.full_name, u.email, trim(p_organization), trim(p_role_in_org),
         trim(p_contact_person), trim(p_contact_number), trim(p_official_page)
  from public.profiles p join auth.users u on u.id = p.id
  where p.id = v_uid
  returning id into v_id;
  return v_id;
end $$;

create function public.admin_review_rescuer(p_id uuid, p_approve boolean, p_reason text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
  v_app public.rescuer_applications;
begin
  select * into v_app from public.rescuer_applications where id = p_id for update;
  if v_app.id is null then raise exception 'Application not found.'; end if;
  if v_app.status <> 'pending' then raise exception 'This application was already reviewed.'; end if;

  if p_approve then
    update public.rescuer_applications
    set status = 'verified', reviewed_by = v_admin, reviewed_at = now()
    where id = p_id;
    perform private.notify(v_app.user_id, 'rescuer_approved',
      'You are now a Verified Rescuer',
      'Your application for ' || v_app.organization || ' was approved. '
        || 'Your Verified Rescuer badge and permissions are now active.', p_id::text);
  else
    if coalesce(trim(p_reason), '') = '' then
      raise exception 'Please give a reason for rejecting this application.';
    end if;
    update public.rescuer_applications
    set status = 'rejected', rejection_reason = trim(p_reason),
        reviewed_by = v_admin, reviewed_at = now()
    where id = p_id;
    perform private.notify(v_app.user_id, 'rescuer_rejected',
      'Rescuer application not approved',
      'Your application was not approved. Reason: ' || trim(p_reason)
        || ' You can apply again from your Profile.', p_id::text);
  end if;
end $$;

-- Removes a Verified Rescuer badge (e.g. high cancel rate).
create function public.admin_revoke_rescuer(p_id uuid, p_reason text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
  v_app public.rescuer_applications;
begin
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Please give a reason for removing the badge.';
  end if;
  select * into v_app from public.rescuer_applications where id = p_id for update;
  if v_app.id is null then raise exception 'Application not found.'; end if;
  if v_app.status <> 'verified' then raise exception 'This user is not a Verified Rescuer.'; end if;

  update public.rescuer_applications
  set status = 'rejected', rejection_reason = 'Badge removed: ' || trim(p_reason),
      reviewed_by = v_admin, reviewed_at = now(), flag_notified_at = null
  where id = p_id;
  perform private.notify(v_app.user_id, 'rescuer_rejected',
    'Verified Rescuer badge removed',
    'An admin removed your Verified Rescuer badge. Reason: ' || trim(p_reason)
      || ' You can apply again from your Profile.', p_id::text);
end $$;

-- ---------------------------------------------------------------- Stray reports

create function public.create_stray_report(
  p_animal_type text, p_urgency public.urgency, p_description text,
  p_photo_paths text[], p_latitude double precision, p_longitude double precision,
  p_address text, p_possibly_lost_pet boolean default false
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_id uuid;
begin
  insert into public.stray_reports
    (reporter_id, animal_type, urgency, description, photo_paths,
     latitude, longitude, address, possibly_lost_pet)
  values
    (v_uid, p_animal_type, p_urgency, coalesce(trim(p_description), ''),
     coalesce(p_photo_paths, '{}'), p_latitude, p_longitude, trim(p_address),
     coalesce(p_possibly_lost_pet, false))
  returning id into v_id;
  return v_id;
end $$;

-- ---------------------------------------------------------------- Rescue responses

-- "I'm on my way!"
-- Regular users: one active response at a time, always "assisting".
-- Verified Rescuers: several at a time; the first one becomes the lead.
create function public.respond_to_report(p_report_id uuid)
returns public.rescue_status
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_org text := private.rescuer_org(v_uid);
  v_report public.stray_reports;
  v_has_lead boolean;
  v_name text;
begin
  select * into v_report from public.stray_reports
  where id = p_report_id and removed_at is null for update;
  if v_report.id is null then raise exception 'Report not found.'; end if;
  if v_report.rescue_status = 'rescued' then
    raise exception 'This animal was already rescued.';
  end if;
  if exists (select 1 from public.rescue_responses
             where report_id = p_report_id and responder_id = v_uid and state = 'active') then
    raise exception 'You are already responding here.';
  end if;
  if v_org is null and exists (select 1 from public.rescue_responses
                               where responder_id = v_uid and state = 'active') then
    raise exception 'You can only respond to one report at a time. Finish or withdraw from your current response first.';
  end if;

  select exists (select 1 from public.rescue_responses
                 where report_id = p_report_id and state = 'active' and role = 'lead')
  into v_has_lead;

  insert into public.rescue_responses (report_id, responder_id, role, organization)
  values (p_report_id, v_uid,
          case when v_org is not null and not v_has_lead then 'lead' else 'assisting' end::public.responder_role,
          v_org);

  update public.stray_reports set rescue_status = 'in_progress' where id = p_report_id;

  if v_report.reporter_id <> v_uid then
    select full_name into v_name from public.profiles where id = v_uid;
    perform private.notify(v_report.reporter_id, 'rescue_response',
      'Someone is on the way',
      coalesce(v_name, 'A community member') || ' is responding to your '
        || v_report.animal_type || ' report.', p_report_id::text);
  end if;
  return 'in_progress';
end $$;

-- "I've Arrived": must be within 200 m of the report's pin.
create function public.check_in(p_report_id uuid, p_latitude double precision, p_longitude double precision)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_report public.stray_reports;
  v_meters double precision;
begin
  select * into v_report from public.stray_reports where id = p_report_id;
  if not exists (select 1 from public.rescue_responses
                 where report_id = p_report_id and responder_id = v_uid and state = 'active') then
    raise exception 'You are not responding to this report.';
  end if;

  v_meters := private.distance_m(p_latitude, p_longitude, v_report.latitude, v_report.longitude);
  if v_meters > 200 then
    raise exception 'You are about % m away. You must be within 200 m of the animal.', round(v_meters);
  end if;

  update public.rescue_responses
  set checked_in_at = coalesce(checked_in_at, now()), last_update_at = now()
  where report_id = p_report_id and responder_id = v_uid and state = 'active';
end $$;

-- "Cancel / I can't make it". Counts as a cancelled response.
create function public.cancel_response(p_report_id uuid)
returns public.rescue_status
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_status public.rescue_status;
begin
  update public.rescue_responses
  set state = 'cancelled', role = 'assisting', ended_at = now(), last_update_at = now()
  where report_id = p_report_id and responder_id = v_uid and state = 'active';
  if not found then raise exception 'You are not responding to this report.'; end if;

  v_status := private.after_responder_left(p_report_id);
  perform private.check_cancel_rate(v_uid);
  return v_status;
end $$;

-- Verified Rescuers only: take over a report with no updates for 24 hours.
create function public.take_over_report(p_report_id uuid)
returns public.rescue_status
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_org text := private.rescuer_org(v_uid);
  v_report public.stray_reports;
  v_latest timestamptz;
begin
  if v_org is null then raise exception 'Only Verified Rescuers can take over a report.'; end if;

  select * into v_report from public.stray_reports
  where id = p_report_id and removed_at is null for update;
  if v_report.id is null then raise exception 'Report not found.'; end if;

  select max(last_update_at) into v_latest from public.rescue_responses
  where report_id = p_report_id and state = 'active';
  if v_report.rescue_status <> 'in_progress'
     or (v_latest is not null and v_latest > now() - interval '24 hours') then
    raise exception 'This report still has recent updates.';
  end if;

  update public.rescue_responses set role = 'assisting'
  where report_id = p_report_id and state = 'active' and responder_id <> v_uid;

  if exists (select 1 from public.rescue_responses
             where report_id = p_report_id and responder_id = v_uid and state = 'active') then
    update public.rescue_responses set role = 'lead', last_update_at = now()
    where report_id = p_report_id and responder_id = v_uid and state = 'active';
  else
    insert into public.rescue_responses (report_id, responder_id, role, organization)
    values (p_report_id, v_uid, 'lead', v_org);
  end if;
  return 'in_progress';
end $$;

-- Mark as rescued / choose an outcome.
--  * Rescue outcomes: only the reporter or a checked-in responder, and they
--    must be within 200 m right now. Regular users: "Rescued on site" only.
--  * "Unable to locate": Verified Rescuers only; ends only their own response.
create function public.finish_rescue(
  p_report_id uuid, p_outcome public.rescue_outcome,
  p_latitude double precision default null, p_longitude double precision default null
) returns public.rescue_status
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_verified boolean := private.rescuer_org(v_uid) is not null;
  v_report public.stray_reports;
  v_me public.rescue_responses;
  v_is_reporter boolean;
  v_meters double precision;
  v_name text;
begin
  select * into v_report from public.stray_reports
  where id = p_report_id and removed_at is null for update;
  if v_report.id is null then raise exception 'Report not found.'; end if;
  if v_report.rescue_status = 'rescued' then raise exception 'This animal was already rescued.'; end if;

  select * into v_me from public.rescue_responses
  where report_id = p_report_id and responder_id = v_uid and state = 'active';
  v_is_reporter := v_report.reporter_id = v_uid;

  if p_outcome = 'unable_to_locate' then
    if v_me.id is null then raise exception 'You are not responding to this report.'; end if;
    if not v_verified then raise exception 'Only Verified Rescuers can choose this outcome.'; end if;
    update public.rescue_responses
    set state = 'finished', outcome = p_outcome, role = 'assisting',
        ended_at = now(), last_update_at = now()
    where id = v_me.id;
    return private.after_responder_left(p_report_id);
  end if;

  if v_me.id is null and not v_is_reporter then
    raise exception 'Only the person who reported this animal, or a responder who has checked in, can mark it as rescued.';
  end if;
  if not v_is_reporter and v_me.checked_in_at is null then
    raise exception 'Please check in at the location first.';
  end if;
  if not v_verified and p_outcome <> 'rescued_on_site' then
    raise exception 'Only Verified Rescuers can choose this outcome.';
  end if;
  if p_latitude is null or p_longitude is null then
    raise exception 'Your location is needed to mark the animal as rescued.';
  end if;
  v_meters := private.distance_m(p_latitude, p_longitude, v_report.latitude, v_report.longitude);
  if v_meters > 200 then
    raise exception 'You are about % m away. You must be within 200 m of the animal.', round(v_meters);
  end if;

  update public.rescue_responses
  set state = 'finished', ended_at = now(), last_update_at = now(),
      outcome = case when responder_id = v_uid then p_outcome else null end
  where report_id = p_report_id and state = 'active';

  update public.stray_reports
  set rescue_status = 'rescued', outcome = p_outcome, closed_by = v_uid, closed_at = now()
  where id = p_report_id;

  if not v_is_reporter then
    select full_name into v_name from public.profiles where id = v_uid;
    perform private.notify(v_report.reporter_id, 'rescue_response',
      'Animal rescued',
      'The ' || lower(v_report.animal_type) || ' you reported was marked as rescued by '
        || coalesce(v_name, 'a responder') || '. Thank you for reporting!', p_report_id::text);
  end if;
  return 'rescued';
end $$;

-- Track record numbers for several users at once (responders list, profile,
-- admin Rescuers page). Trust level is calculated in the app from these.
create function public.responder_stats(p_user_ids uuid[])
returns table (user_id uuid, responses int, rescues int, cancelled int,
               unable_to_locate int, check_ins int)
language sql stable security definer set search_path = '' as $$
  select u.id, s.responses, s.rescues, s.cancelled, s.unable_to_locate, s.check_ins
  from unnest(p_user_ids) as u(id)
  cross join lateral private.stats_for(u.id) s
  where auth.uid() is not null;
$$;

-- ---------------------------------------------------------------- Adoption posts

-- New post: always starts as PENDING (waits for an admin).
create function public.create_adoption_post(
  p_name text, p_animal_type text, p_age_text text, p_sex text,
  p_source public.pet_source, p_description text, p_health_info text, p_reason text,
  p_barangay text, p_city text, p_street text, p_photo_paths text[],
  p_contact_person text, p_contact_phone text, p_contact_email text
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_id uuid;
begin
  insert into public.adoption_posts
    (poster_id, name, animal_type, age_text, sex, source, description, health_info,
     reason, barangay, city, photo_paths, rescued_by)
  values
    (v_uid, trim(p_name), p_animal_type, trim(p_age_text), p_sex, p_source,
     trim(p_description), coalesce(trim(p_health_info), ''), trim(p_reason),
     trim(p_barangay), trim(p_city), p_photo_paths, private.rescuer_org(v_uid))
  returning id into v_id;

  insert into public.adoption_post_contacts
    (post_id, street, contact_person, contact_phone, contact_email)
  values
    (v_id, coalesce(trim(p_street), ''), trim(p_contact_person),
     trim(p_contact_phone), trim(p_contact_email));
  return v_id;
end $$;

-- Owner edits their post: it goes back to PENDING for re-review.
create function public.update_adoption_post(
  p_id uuid, p_name text, p_animal_type text, p_age_text text, p_sex text,
  p_source public.pet_source, p_description text, p_health_info text, p_reason text,
  p_barangay text, p_city text, p_street text, p_photo_paths text[],
  p_contact_person text, p_contact_phone text, p_contact_email text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_post public.adoption_posts;
begin
  select * into v_post from public.adoption_posts where id = p_id for update;
  if v_post.id is null or v_post.removed_at is not null then raise exception 'Pet not found.'; end if;
  if v_post.poster_id <> v_uid then raise exception 'You can only edit your own posts.'; end if;

  update public.adoption_posts
  set name = trim(p_name), animal_type = p_animal_type, age_text = trim(p_age_text),
      sex = p_sex, source = p_source, description = trim(p_description),
      health_info = coalesce(trim(p_health_info), ''), reason = trim(p_reason),
      barangay = trim(p_barangay), city = trim(p_city), photo_paths = p_photo_paths,
      status = 'pending', rejection_reason = null,
      resubmitted = v_post.resubmitted or v_post.status <> 'pending'
  where id = p_id;

  update public.adoption_post_contacts
  set street = coalesce(trim(p_street), ''), contact_person = trim(p_contact_person),
      contact_phone = trim(p_contact_phone), contact_email = trim(p_contact_email)
  where post_id = p_id;
end $$;

-- Owner removes their post. It is hidden (not deleted) so applications
-- about it still make sense; waiting applicants are told.
create function public.remove_my_adoption_post(p_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_post public.adoption_posts;
begin
  select * into v_post from public.adoption_posts where id = p_id for update;
  if v_post.id is null or v_post.removed_at is not null then raise exception 'Pet not found.'; end if;
  if v_post.poster_id <> v_uid then raise exception 'You can only remove your own posts.'; end if;

  update public.adoption_posts set removed_at = now() where id = p_id;
  perform private.close_waiting_applications(p_id, 'The poster removed this adoption post.');
end $$;

-- Admin approves (published) or rejects (reason required) a post.
create function public.admin_review_post(p_id uuid, p_approve boolean, p_reason text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
  v_post public.adoption_posts;
begin
  select * into v_post from public.adoption_posts where id = p_id for update;
  if v_post.id is null or v_post.removed_at is not null then raise exception 'Pet not found.'; end if;

  if p_approve then
    update public.adoption_posts
    set status = 'approved', rejection_reason = null, resubmitted = false,
        reviewed_by = v_admin, reviewed_at = now()
    where id = p_id;
    perform private.notify(v_post.poster_id, 'post_approved', 'Post approved',
      'Your adoption post for ' || v_post.name
        || ' was approved and is now listed in the Adoption Bulletin.', p_id::text);
  else
    if coalesce(trim(p_reason), '') = '' then
      raise exception 'Please give a reason for rejecting this post.';
    end if;
    update public.adoption_posts
    set status = 'rejected', rejection_reason = trim(p_reason), resubmitted = false,
        reviewed_by = v_admin, reviewed_at = now()
    where id = p_id;
    perform private.notify(v_post.poster_id, 'post_removed', 'Post not approved',
      'Your adoption post for ' || v_post.name || ' was not approved. Reason: '
        || trim(p_reason) || ' You can edit the post and submit it again.', p_id::text);
  end if;
end $$;

-- ---------------------------------------------------------------- Adoption applications

create function public.submit_application(
  p_post_id uuid, p_full_name text, p_phone text, p_email text,
  p_city text, p_barangay text, p_street text,
  p_home_environment text, p_household_members text, p_previous_pets text,
  p_care_experience text, p_valid_id_agreed boolean, p_reason_for_adopting text default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_post public.adoption_posts;
  v_id uuid;
begin
  select * into v_post from public.adoption_posts where id = p_post_id;
  if v_post.id is null or v_post.removed_at is not null or v_post.status <> 'approved' then
    raise exception 'This pet is not available for adoption.';
  end if;
  if v_post.poster_id = v_uid then raise exception 'You cannot apply for your own pet.'; end if;
  if exists (select 1 from public.adoption_applications
             where post_id = p_post_id and applicant_id = v_uid) then
    raise exception 'Already applied for this pet.';
  end if;
  if exists (select 1 from public.adoption_applications
             where post_id = p_post_id and status = 'approved') then
    raise exception '% already has an approved adopter.', v_post.name;
  end if;
  if not coalesce(p_valid_id_agreed, false) then
    raise exception 'Please agree to present a valid ID during the meet-up.';
  end if;

  insert into public.adoption_applications
    (post_id, applicant_id, full_name, phone, email, city, barangay, street,
     home_environment, household_members, previous_pets, care_experience,
     reason_for_adopting, valid_id_agreed)
  values
    (p_post_id, v_uid, trim(p_full_name), trim(p_phone), trim(p_email), trim(p_city),
     trim(p_barangay), coalesce(trim(p_street), ''), trim(p_home_environment),
     trim(p_household_members), trim(p_previous_pets), trim(p_care_experience),
     nullif(trim(p_reason_for_adopting), ''), true)
  returning id into v_id;

  perform private.notify_admins('application_submitted', 'New adoption application',
    trim(p_full_name) || ' applied to adopt ' || v_post.name || '. It is waiting for screening.',
    v_id::text);
  return v_id;
end $$;

-- ADMIN screening: forward to the poster, or reject (reason optional).
create function public.admin_screen_application(p_id uuid, p_forward boolean, p_reason text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
  v_app public.adoption_applications;
  v_post public.adoption_posts;
begin
  select * into v_app from public.adoption_applications where id = p_id for update;
  if v_app.id is null then raise exception 'Application not found.'; end if;
  select * into v_post from public.adoption_posts where id = v_app.post_id;

  if p_forward then
    if v_app.status <> 'pending_screening' then
      raise exception 'Only pending applications can be forwarded.';
    end if;
    if v_post.removed_at is not null then raise exception 'This adoption post was removed.'; end if;
    if exists (select 1 from public.adoption_applications
               where post_id = v_app.post_id and status = 'approved') then
      raise exception '% already has an approved adopter, so this application cannot be forwarded.', v_post.name;
    end if;

    update public.adoption_applications
    set status = 'forwarded_to_owner', screened_by = v_admin, screened_at = now(),
        forwarded_at = now(), rejection_reason = null
    where id = p_id;

    perform private.notify(v_app.applicant_id, 'application_forwarded', 'Application forwarded',
      'Your application for ' || v_post.name || ' passed screening and was forwarded to '
        || 'the pet''s poster, who will make the final decision.', p_id::text);
    perform private.notify(v_post.poster_id, 'application_for_owner',
      'New application for ' || v_post.name,
      'An application passed admin screening and needs your decision.', p_id::text);
  else
    if v_app.status in ('approved', 'rejected') then
      raise exception 'This application was already decided.';
    end if;
    update public.adoption_applications
    set status = 'rejected', rejection_reason = nullif(trim(p_reason), ''),
        screened_by = v_admin, screened_at = now()
    where id = p_id;
    perform private.notify(v_app.applicant_id, 'application_rejected', 'Application not approved',
      'Your application for ' || v_post.name || ' was not approved.'
        || coalesce(' Reason: ' || nullif(trim(p_reason), ''), ''), p_id::text);
  end if;
end $$;

-- POSTER's final decision on a forwarded application. Approving one closes
-- the other waiting applications for the same pet.
create function public.owner_decide_application(p_id uuid, p_approve boolean, p_reason text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_app public.adoption_applications;
  v_post public.adoption_posts;
begin
  select * into v_app from public.adoption_applications where id = p_id for update;
  if v_app.id is null then raise exception 'Application not found.'; end if;
  select * into v_post from public.adoption_posts where id = v_app.post_id;
  if v_post.poster_id <> v_uid then
    raise exception 'You can only decide on applications for your pets.';
  end if;
  if v_app.status <> 'forwarded_to_owner' then
    raise exception 'This application is not waiting for a decision.';
  end if;

  if p_approve then
    update public.adoption_applications
    set status = 'approved', rejection_reason = null, decided_at = now()
    where id = p_id;
    perform private.notify(v_app.applicant_id, 'application_approved', 'Application approved',
      'Good news! Your application for ' || v_post.name || ' was approved.', p_id::text);
    perform private.close_waiting_applications(
      v_app.post_id, 'Another applicant was selected for this pet.', p_id);
  else
    update public.adoption_applications
    set status = 'rejected', rejection_reason = nullif(trim(p_reason), ''), decided_at = now()
    where id = p_id;
    perform private.notify(v_app.applicant_id, 'application_rejected', 'Application not approved',
      'Your application for ' || v_post.name || ' was not approved.'
        || coalesce(' Reason: ' || nullif(trim(p_reason), ''), ''), p_id::text);
  end if;
end $$;

-- ---------------------------------------------------------------- Reported content

create function public.submit_content_report(
  p_target_type public.report_target, p_target_id uuid, p_target_title text,
  p_reason public.report_reason, p_details text default ''
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_id uuid;
begin
  if p_target_type = 'adoption_post' and not exists
     (select 1 from public.adoption_posts where id = p_target_id and removed_at is null) then
    raise exception 'This post is no longer available.';
  end if;
  if p_target_type = 'stray_report' and not exists
     (select 1 from public.stray_reports where id = p_target_id and removed_at is null) then
    raise exception 'This report is no longer available.';
  end if;

  begin
    insert into public.content_reports
      (reporter_id, target_type, adoption_post_id, stray_report_id, target_title, reason, details)
    values
      (v_uid, p_target_type,
       case when p_target_type = 'adoption_post' then p_target_id end,
       case when p_target_type = 'stray_report' then p_target_id end,
       left(trim(p_target_title), 80), p_reason, coalesce(trim(p_details), ''))
    returning id into v_id;
  exception when unique_violation then
    raise exception 'You already reported this. The admin will review it soon.';
  end;
  return v_id;
end $$;

-- ADMIN: no violation found, close the report.
create function public.admin_dismiss_content_report(p_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
begin
  update public.content_reports
  set status = 'dismissed', admin_action = 'No violation found',
      reviewed_by = v_admin, reviewed_at = now()
  where id = p_id and status = 'pending';
  if not found then raise exception 'Report not found or already reviewed.'; end if;
end $$;

-- ADMIN: remove the reported content (hidden, not deleted). Every waiting
-- report about the same content is closed as "removed" too.
create function public.admin_remove_reported_content(p_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
  v_rep public.content_reports;
  v_post public.adoption_posts;
  v_stray public.stray_reports;
begin
  select * into v_rep from public.content_reports where id = p_id;
  if v_rep.id is null then raise exception 'Report not found.'; end if;

  if v_rep.target_type = 'adoption_post' then
    select * into v_post from public.adoption_posts where id = v_rep.adoption_post_id for update;
    if v_post.removed_at is null then
      update public.adoption_posts set removed_at = now(), removed_by_admin = true where id = v_post.id;
      perform private.notify(v_post.poster_id, 'post_removed', 'Post removed by admin',
        'Your adoption post for ' || v_post.name || ' was removed by an administrator '
          || 'because it did not follow the community guidelines.', v_post.id::text);
      perform private.close_waiting_applications(v_post.id, 'This adoption post was removed.');
    end if;
  else
    select * into v_stray from public.stray_reports where id = v_rep.stray_report_id for update;
    if v_stray.removed_at is null then
      update public.stray_reports set removed_at = now() where id = v_stray.id;
      -- active responders are released without affecting their track record
      update public.rescue_responses set state = 'closed', ended_at = now()
      where report_id = v_stray.id and state = 'active';
      perform private.notify(v_stray.reporter_id, 'post_removed', 'Report removed by admin',
        'Your ' || v_stray.animal_type || ' report was removed by an administrator '
          || 'because it did not follow the community guidelines.', v_stray.id::text);
    end if;
  end if;

  update public.content_reports
  set status = 'removed', admin_action = 'Content removed',
      reviewed_by = v_admin, reviewed_at = now()
  where status = 'pending'
    and target_type = v_rep.target_type
    and adoption_post_id is not distinct from v_rep.adoption_post_id
    and stray_report_id is not distinct from v_rep.stray_report_id;
end $$;

-- ADMIN: restrict / unrestrict an account (restricted users can still log
-- in and read, but cannot post, respond or apply).
create function public.admin_set_user_restricted(p_user_id uuid, p_restricted boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_admin uuid := private.require_admin();
begin
  if p_user_id = v_admin then raise exception 'You cannot restrict your own account.'; end if;
  update public.profiles set is_restricted = p_restricted where id = p_user_id;
end $$;

-- ---------------------------------------------------------------- Notifications

create function public.mark_notification_read(p_id uuid)
returns void
language sql security definer set search_path = '' as $$
  update public.notifications set is_read = true
  where id = p_id and recipient_id = auth.uid();
$$;

create function public.mark_all_notifications_read()
returns void
language sql security definer set search_path = '' as $$
  update public.notifications set is_read = true
  where recipient_id = auth.uid() and not is_read;
$$;

-- ---------------------------------------------------------------- Admin dashboard

create function public.admin_dashboard_counts()
returns json
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_admin();
  return json_build_object(
    'posts_total',          (select count(*) from public.adoption_posts where removed_at is null),
    'posts_pending',        (select count(*) from public.adoption_posts where removed_at is null and status = 'pending'),
    'posts_approved',       (select count(*) from public.adoption_posts where removed_at is null and status = 'approved'),
    'applications_total',   (select count(*) from public.adoption_applications),
    'applications_pending', (select count(*) from public.adoption_applications where status = 'pending_screening'),
    'reports_pending',      (select count(*) from public.content_reports where status = 'pending'),
    'registered_users',     (select count(*) from public.profiles where role = 'user'),
    'rescuers_pending',     (select count(*) from public.rescuer_applications where status = 'pending'),
    'rescuers_flagged',     (select count(*) from public.rescuer_applications
                             where status = 'verified' and flag_notified_at is not null)
  );
end $$;


-- =====================================================================
-- 5. SECURITY RULES (Row Level Security)
-- =====================================================================
-- Logged-out visitors can't read anything. Logged-in users can only READ
-- what the rules below allow, and can't write to any table directly.

alter table public.profiles               enable row level security;
alter table public.rescuer_applications   enable row level security;
alter table public.stray_reports          enable row level security;
alter table public.rescue_responses       enable row level security;
alter table public.adoption_posts         enable row level security;
alter table public.adoption_post_contacts enable row level security;
alter table public.adoption_applications  enable row level security;
alter table public.content_reports        enable row level security;
alter table public.notifications          enable row level security;

grant usage on schema public to authenticated;
revoke all on all tables in schema public from anon;
revoke insert, update, delete, truncate on all tables in schema public from authenticated;
grant select on all tables in schema public to authenticated;

-- Names and avatars are shown on reports, posts and responder lists.
create policy "Logged-in users can see profiles"
  on public.profiles for select to authenticated using (true);

create policy "Own rescuer applications, or admin"
  on public.rescuer_applications for select to authenticated
  using (user_id = auth.uid() or private.is_admin());

create policy "Reports that are not removed, own reports, or admin"
  on public.stray_reports for select to authenticated
  using (removed_at is null or reporter_id = auth.uid() or private.is_admin());

create policy "Logged-in users can see responders"
  on public.rescue_responses for select to authenticated using (true);

create policy "Approved posts, own posts, posts you applied to, or admin"
  on public.adoption_posts for select to authenticated
  using (
    (status = 'approved' and removed_at is null)
    or poster_id = auth.uid()
    or private.is_admin()
    or private.applied_to(id, false)
  );

create policy "Contacts: poster, admin, or forwarded applicant"
  on public.adoption_post_contacts for select to authenticated
  using (
    private.is_admin()
    or private.owns_post(post_id)
    or private.applied_to(post_id, true)
  );

create policy "Own apps, forwarded apps for your pets, or admin"
  on public.adoption_applications for select to authenticated
  using (
    applicant_id = auth.uid()
    or private.is_admin()
    or (forwarded_at is not null and private.owns_post(post_id))
  );

create policy "Own content reports, or admin"
  on public.content_reports for select to authenticated
  using (reporter_id = auth.uid() or private.is_admin());

create policy "Own notifications"
  on public.notifications for select to authenticated
  using (recipient_id = auth.uid());

-- Function permissions: only logged-in users can call the app functions,
-- and nobody can call the private helpers.
revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function private.is_admin() to authenticated;
grant execute on function private.owns_post(uuid) to authenticated;
grant execute on function private.applied_to(uuid, boolean) to authenticated;

revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;


-- =====================================================================
-- 6. PHOTO STORAGE
-- =====================================================================
-- Three public buckets (anyone with the link can VIEW a photo, like on
-- Facebook). Uploads: logged-in users, images only, max 5 MB, and only
-- inside their own folder: <user id>/<file name>.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('report-photos', 'report-photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/heic']),
  ('pet-photos',    'pet-photos',    true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/heic']),
  ('avatars',       'avatars',       true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do nothing;

create policy "Upload photos to your own folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id in ('report-photos', 'pet-photos', 'avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Replace photos in your own folder"
  on storage.objects for update to authenticated
  using (
    bucket_id in ('report-photos', 'pet-photos', 'avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Delete photos in your own folder"
  on storage.objects for delete to authenticated
  using (
    bucket_id in ('report-photos', 'pet-photos', 'avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

commit;

-- Done! 🐾
