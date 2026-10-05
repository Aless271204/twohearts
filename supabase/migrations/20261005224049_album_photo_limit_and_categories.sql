alter table public.memory_albums add column if not exists category text not null default 'general';
alter table public.memory_albums add constraint memory_albums_category_check check (category in ('general','lugar','fecha','especial','viaje','cita'));
alter table public.memory_albums add constraint memory_albums_photo_limit check (cardinality(photo_urls) between 1 and 5) not valid;
alter policy users_can_update_own_memory_albums on public.memory_albums with check (user_id = auth.uid() and couple_id = public.get_couple_id_for_user(auth.uid()));
