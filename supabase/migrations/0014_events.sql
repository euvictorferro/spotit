create table events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  location text not null,
  lat double precision,
  lng double precision,
  event_date timestamptz not null,
  description text,
  created_at timestamptz not null default now()
);

alter table events enable row level security;

create policy "events sao publicamente legiveis"
  on events for select using (true);

create policy "usuario cria evento por conta propria"
  on events for insert with check (auth.uid() = organizer_id);


create table event_attendees (
  event_id uuid not null references events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

alter table event_attendees enable row level security;

create policy "attendees sao publicamente legiveis"
  on event_attendees for select using (true);

create policy "usuario confirma presenca por conta propria"
  on event_attendees for insert with check (auth.uid() = user_id);

create policy "usuario cancela a propria presenca"
  on event_attendees for delete using (auth.uid() = user_id);
