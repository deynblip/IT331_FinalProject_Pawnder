--  Device tokens for push notifications (FCM)

-- Rules:
--  * One row per phone token. The app cannot read or write this table
--    directly; it only calls the two functions below.
--  * If a phone logs in as another user, the same token moves to that
--    user (so the old user stops getting pushes on that phone).
--  * Only the Edge Function (service role) reads the tokens


begin;

create table public.device_tokens (
  token      text primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  platform   text not null default 'android',
  updated_at timestamptz not null default now()
);
create index device_tokens_user_idx on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;
revoke all on public.device_tokens from anon, authenticated;

-- ---------------------------------------------------------------- Save my token
create function public.register_device_token(p_token text, p_platform text default 'android')
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'Not logged in.';
  end if;
  if p_token is null or length(p_token) < 20 then
    raise exception 'Invalid device token.';
  end if;

  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (p_token, auth.uid(), coalesce(p_platform, 'android'), now())
  on conflict (token) do update
    set user_id = auth.uid(),
        platform = excluded.platform,
        updated_at = now();
end $$;

-- ---------------------------------------------------------------- Remove my token (log out)
create function public.unregister_device_token(p_token text)
returns void
language sql security definer set search_path = '' as $$
  delete from public.device_tokens
  where token = p_token and user_id = auth.uid();
$$;

revoke execute on function public.register_device_token(text, text) from public, anon;
revoke execute on function public.unregister_device_token(text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;
grant execute on function public.unregister_device_token(text) to authenticated;

commit;
