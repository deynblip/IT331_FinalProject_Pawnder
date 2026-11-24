-- =====================================================================
-- PAWNDER: MAKE AN ACCOUNT AN ADMIN
-- =====================================================================
update public.profiles
set role = 'admin',
    full_name = 'Partner Org Admin'
where id = (select id from auth.users where email = 'admin@pawnder.com');

-- Check: dapat lumabas ang admin account dito.
select p.full_name, u.email, p.role
from public.profiles p join auth.users u on u.id = p.id
where u.email = 'admin@pawnder.com';
