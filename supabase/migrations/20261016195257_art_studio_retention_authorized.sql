-- Explicit user authorization in chat: delete old drawing matches, expired widget
-- capabilities and notes whose accounts are no longer reciprocally linked.
create function nido_private.cleanup_art_studio() returns void language sql security definer set search_path='' as $$
 delete from nido_private.art_rooms where created_at<now()-interval '30 days';
 delete from nido_private.art_widget_tokens where expires_at<now();
 delete from nido_private.partner_art_notes n where not exists(
  select 1 from public.user_profiles p join public.user_profiles q on q.id=p.partner_id and q.partner_id=p.id where p.id=n.sender and q.id=n.recipient);
$$;
revoke all on function nido_private.cleanup_art_studio() from public,anon,authenticated;
select cron.schedule('nido-art-studio-retention','17 4 * * *','select nido_private.cleanup_art_studio()');
