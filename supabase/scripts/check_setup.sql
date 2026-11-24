-- =====================================================================
-- PAWNDER: CHECK THE SETUP
-- Run this after 0001_pawnder_init.sql. Every row should say ✅.
-- =====================================================================
select 'Tables (expected 9)' as item,
       count(*)::text as found,
       case when count(*) = 9 then '✅' else '❌' end as ok
from information_schema.tables
where table_schema = 'public'
  and table_name in ('profiles', 'rescuer_applications', 'stray_reports', 'rescue_responses',
                     'adoption_posts', 'adoption_post_contacts', 'adoption_applications',
                     'content_reports', 'notifications')
union all
select 'Security rules ON (expected 9)', count(*)::text,
       case when count(*) = 9 then '✅' else '❌' end
from pg_tables where schemaname = 'public' and rowsecurity
union all
select 'App functions (expected 25)', count(*)::text,
       case when count(*) = 25 then '✅' else '❌' end
from pg_proc where pronamespace = 'public'::regnamespace
union all
select 'Photo buckets (expected 3)', count(*)::text,
       case when count(*) = 3 then '✅' else '❌' end
from storage.buckets where id in ('report-photos', 'pet-photos', 'avatars')
union all
select 'Sign-up trigger', count(*)::text,
       case when count(*) = 1 then '✅' else '❌' end
from pg_trigger where tgname = 'on_auth_user_created'
union all
select 'Admin accounts (need at least 1)', count(*)::text,
       case when count(*) >= 1 then '✅' else '⏳ not yet (Step 6)' end
from public.profiles where role = 'admin';
