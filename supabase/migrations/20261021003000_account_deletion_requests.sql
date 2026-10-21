-- User-initiated requests only. This migration does not erase existing accounts.
create table if not exists nido_private.account_deletion_requests (
 user_id uuid primary key references auth.users(id) on delete cascade,
 requested_at timestamptz not null default now(),
 status text not null default 'pending' check(status in ('pending','processing','completed')),
 completed_at timestamptz
);
alter table nido_private.account_deletion_requests enable row level security;
revoke all on nido_private.account_deletion_requests from public,anon,authenticated;
grant select,update,delete on nido_private.account_deletion_requests to service_role;
create or replace function public.request_account_deletion()
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r nido_private.account_deletion_requests;
begin
 if u is null then raise exception 'Inicia sesión para solicitar la eliminación';end if;
 insert into nido_private.account_deletion_requests(user_id) values(u)
 on conflict(user_id) do nothing;
 select * into r from nido_private.account_deletion_requests where user_id=u;
 return jsonb_build_object('status',r.status,'requested_at',r.requested_at);
end $$;
revoke all on function public.request_account_deletion() from public,anon;
grant execute on function public.request_account_deletion() to authenticated;
