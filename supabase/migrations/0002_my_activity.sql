-- Rules:
--  * Only the reporter can edit / remove the report.
--  * Not allowed when the report is already Rescued (it is part of the rescue record).
--  * Not allowed while someone is responding ("I'm on my way" is active).
--  * The location pin cannot be changed.
--  * Remove = hidden (removed_at), never deleted.

begin;

-- ---------------------------------------------------------------- Edit my report
create function public.update_my_report(
  p_id uuid,
  p_animal_type text,
  p_urgency public.urgency,
  p_description text,
  p_photo_paths text[],
  p_possibly_lost_pet boolean default false
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

  update public.stray_reports
  set animal_type       = p_animal_type,
      urgency           = p_urgency,
      description       = coalesce(trim(p_description), ''),
      photo_paths       = coalesce(p_photo_paths, '{}'),
      possibly_lost_pet = coalesce(p_possibly_lost_pet, false)
  where id = p_id;
end $$;

-- ---------------------------------------------------------------- Remove my report
create function public.remove_my_report(p_id uuid)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := private.require_user();
  v_rep public.stray_reports;
begin
  select * into v_rep from public.stray_reports
  where id = p_id and removed_at is null for update;

  if v_rep.id is null then raise exception 'Report not found.'; end if;
  if v_rep.reporter_id <> v_uid then raise exception 'You can only remove your own report.'; end if;
  if v_rep.rescue_status = 'rescued' then
    raise exception 'This animal was already rescued, so the report can no longer be removed.';
  end if;
  if exists (select 1 from public.rescue_responses
             where report_id = p_id and state = 'active') then
    raise exception 'Someone is responding to this report, so it cannot be removed right now.';
  end if;

  update public.stray_reports set removed_at = now() where id = p_id;
end $$;

-- Only logged-in users can call them (same as the other functions).
revoke execute on function public.update_my_report(uuid, text, public.urgency, text, text[], boolean) from public, anon;
revoke execute on function public.remove_my_report(uuid) from public, anon;
grant execute on function public.update_my_report(uuid, text, public.urgency, text, text[], boolean) to authenticated;
grant execute on function public.remove_my_report(uuid) to authenticated;

commit;
