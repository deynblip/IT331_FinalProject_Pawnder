-- Let the Edge Function (service role) read and clean up device tokens
grant select, delete on public.device_tokens to service_role;