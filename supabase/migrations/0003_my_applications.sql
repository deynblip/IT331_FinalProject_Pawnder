-- Rules:
--  * Only the applicant can edit or withdraw their application.
--  * EDIT: only while the application is still pending screening.
--  * WITHDRAW: while pending screening or forwarded to the poster.
--  * Approved, rejected or withdrawn applications cannot be changed.
--  * Withdrawn applications are kept (never deleted).

alter type public.application_status add value if not exists 'withdrawn';

begin;

-- ---------------------------------------------------------------- Edit my application
create function public.update_my_application(
  p_id uuid,
  p_full_name text, p_phone text, p_email text,
  p_city text, p_barangay text, p_street text,
  p_home_environment text, p_household_members text, p_previous_pets text,
  p_care_experience text, p_reason_for_adopting text default null
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_app public.adoption_applications;
begin
  select * into v_app from public.adoption_applications
  where id = p_id for update;

  if v_app.id is null or v_app.applicant_id <> v_uid then
    raise exception 'Application not found.';
  end if;
  if v_app.status <> 'pending_screening' then
    raise exception 'This application can no longer be edited. It is already %.',
      case v_app.status
        when 'forwarded_to_owner' then 'with the poster'
        else v_app.status::text
      end;
  end if;

  update public.adoption_applications
  set full_name = trim(p_full_name),
      phone = trim(p_phone),
      email = trim(p_email),
      city = trim(p_city),
      barangay = trim(p_barangay),
      street = coalesce(trim(p_street), ''),
      home_environment = trim(p_home_environment),
      household_members = trim(p_household_members),
      previous_pets = trim(p_previous_pets),
      care_experience = trim(p_care_experience),
      reason_for_adopting = nullif(trim(p_reason_for_adopting), '')
  where id = p_id;
end $$;

-- ---------------------------------------------------------------- Withdraw my application
create function public.withdraw_my_application(p_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_app public.adoption_applications;
  v_post public.adoption_posts;
begin
  select * into v_app from public.adoption_applications
  where id = p_id for update;

  if v_app.id is null or v_app.applicant_id <> v_uid then
    raise exception 'Application not found.';
  end if;
  if v_app.status not in ('pending_screening', 'forwarded_to_owner') then
    raise exception 'This application can no longer be withdrawn.';
  end if;

  select * into v_post from public.adoption_posts where id = v_app.post_id;

  update public.adoption_applications
  set status = 'withdrawn', rejection_reason = null
  where id = p_id;

  -- Tell the poster only if the application had already reached them.
  if v_app.status = 'forwarded_to_owner' then
    perform private.notify(v_post.poster_id, 'application_for_owner',
      'Application withdrawn',
      'An applicant withdrew their application for ' || v_post.name || '.', null);
  end if;
end $$;

revoke execute on function public.update_my_application(uuid, text, text, text, text, text, text, text, text, text, text, text) from public, anon;
revoke execute on function public.withdraw_my_application(uuid) from public, anon;
grant execute on function public.update_my_application(uuid, text, text, text, text, text, text, text, text, text, text, text) to authenticated;
grant execute on function public.withdraw_my_application(uuid) to authenticated;

commit;
