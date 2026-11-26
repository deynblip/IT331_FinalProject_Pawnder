-- ===================== PREVIEW (walang binubura) =====================
select u.id, u.email, p.full_name, p.role
from auth.users u join public.profiles p on p.id = u.id
where lower(u.email) in ('test1@gmail.com', 'test2@gmail.com');

-- ===================== DELETE =====================
do $$
declare
  v_ids uuid[];
begin
  select array_agg(u.id) into v_ids
  from auth.users u
  join public.profiles p on p.id = u.id
  where lower(u.email) in ('test1@gmail.com', 'test2@gmail.com')
    and p.role <> 'admin';

  if v_ids is null then
    raise notice 'Walang tumugmang account (o admin ito, kaya hindi binura).';
    return;
  end if;

  update public.rescuer_applications  set reviewed_by = null where reviewed_by = any(v_ids);
  update public.stray_reports         set closed_by   = null where closed_by   = any(v_ids);
  update public.adoption_posts        set reviewed_by = null where reviewed_by = any(v_ids);
  update public.adoption_applications set screened_by = null where screened_by = any(v_ids);
  update public.content_reports       set reviewed_by = null where reviewed_by = any(v_ids);

  delete from public.content_reports
   where reporter_id = any(v_ids)
      or stray_report_id in (select id from public.stray_reports where reporter_id = any(v_ids))
      or adoption_post_id in (select id from public.adoption_posts where poster_id = any(v_ids));

  delete from public.adoption_applications
   where applicant_id = any(v_ids)
      or post_id in (select id from public.adoption_posts where poster_id = any(v_ids));

  delete from public.adoption_posts where poster_id = any(v_ids);

  delete from public.rescue_responses
   where responder_id = any(v_ids)
      or report_id in (select id from public.stray_reports where reporter_id = any(v_ids));

  delete from public.stray_reports where reporter_id = any(v_ids);
  delete from public.rescuer_applications where user_id = any(v_ids);

  delete from auth.users where id = any(v_ids);

  raise notice 'Nabura: % account(s).', array_length(v_ids, 1);
end $$;
