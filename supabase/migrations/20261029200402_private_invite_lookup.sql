-- Looking up an email must never reveal a private invitation credential.
-- Existing code-based pairing remains available to installed clients.
revoke execute on function public.search_user_by_email(text) from public,anon,authenticated;
do $$ begin
 if has_function_privilege('authenticated','public.search_user_by_email(text)','EXECUTE')
 then raise exception 'Email lookup still exposes invitation credentials';end if;
 if not has_function_privilege('authenticated','public.link_partner_by_invite_code(text,date,text)','EXECUTE')
 then raise exception 'Code pairing unexpectedly unavailable';end if;
end $$;
