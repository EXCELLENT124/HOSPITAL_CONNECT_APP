-- Health Connect initial schema
create extension if not exists pgcrypto;

create table public.organisations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null check (type in ('hospital', 'lawyer')),
  city text not null,
  created_by uuid not null references auth.users(id),
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.memberships (
  user_id uuid not null references auth.users(id) on delete cascade,
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  member_role text not null default 'member' check (member_role in ('admin', 'member')),
  created_at timestamptz not null default now(),
  primary key (user_id, organisation_id)
);

create table public.raf_cases (
  id text primary key,
  patient_name text not null,
  hospital_id uuid not null references public.organisations(id),
  accident_city text not null,
  status text not null default 'New referral',
  assigned_lawyer_id uuid references public.organisations(id),
  assigned_lawyer_name text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.case_documents (
  id uuid primary key default gen_random_uuid(),
  case_id text not null references public.raf_cases(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id),
  file_name text not null,
  storage_path text not null unique,
  created_at timestamptz not null default now()
);

create table public.case_messages (
  id uuid primary key default gen_random_uuid(),
  case_id text not null references public.raf_cases(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  body text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $
declare new_org_id uuid;
begin
  if new.raw_user_meta_data->>'organisation' is not null then
    insert into public.organisations (name, type, city, created_by)
    values (new.raw_user_meta_data->>'organisation', new.raw_user_meta_data->>'account_type', new.raw_user_meta_data->>'city', new.id)
    returning id into new_org_id;
    insert into public.memberships (user_id, organisation_id, member_role)
    values (new.id, new_org_id, 'admin');
  end if;
  return new;
end;
$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create index memberships_user_idx on public.memberships(user_id);
create index memberships_org_idx on public.memberships(organisation_id);
create index raf_cases_hospital_idx on public.raf_cases(hospital_id);
create index raf_cases_lawyer_idx on public.raf_cases(assigned_lawyer_id);
create index messages_case_idx on public.case_messages(case_id);
create index documents_case_idx on public.case_documents(case_id);

alter table public.organisations enable row level security;
alter table public.memberships enable row level security;
alter table public.raf_cases enable row level security;
alter table public.case_documents enable row level security;
alter table public.case_messages enable row level security;

create policy "authenticated can create organisations"
on public.organisations for insert to authenticated
with check ((select auth.uid()) = created_by);

create policy "members view their organisations"
on public.organisations for select to authenticated
using (
  created_by = (select auth.uid())
  or exists (
    select 1 from public.memberships m
    where m.organisation_id = id and m.user_id = (select auth.uid())
  )
);

create policy "creator starts membership"
on public.memberships for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.organisations o
    where o.id = organisation_id and o.created_by = (select auth.uid())
  )
);

create policy "members view their memberships"
on public.memberships for select to authenticated
using (user_id = (select auth.uid()));

create policy "hospital members create cases"
on public.raf_cases for insert to authenticated
with check (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.memberships m
    join public.organisations o on o.id = m.organisation_id
    where m.user_id = (select auth.uid())
      and m.organisation_id = hospital_id
      and o.type = 'hospital'
  )
);

create policy "participants view cases"
on public.raf_cases for select to authenticated
using (
  exists (
    select 1 from public.memberships m
    where m.user_id = (select auth.uid())
      and m.organisation_id in (hospital_id, assigned_lawyer_id)
  )
);

create policy "participants update cases"
on public.raf_cases for update to authenticated
using (
  exists (
    select 1 from public.memberships m
    where m.user_id = (select auth.uid())
      and m.organisation_id in (hospital_id, assigned_lawyer_id)
  )
)
with check (
  exists (
    select 1 from public.memberships m
    where m.user_id = (select auth.uid())
      and m.organisation_id in (hospital_id, assigned_lawyer_id)
  )
);

create policy "participants view documents"
on public.case_documents for select to authenticated
using (
  exists (
    select 1 from public.raf_cases c
    join public.memberships m
      on m.organisation_id in (c.hospital_id, c.assigned_lawyer_id)
    where c.id = case_id and m.user_id = (select auth.uid())
  )
);

create policy "participants add documents"
on public.case_documents for insert to authenticated
with check (
  uploaded_by = (select auth.uid())
  and exists (
    select 1 from public.raf_cases c
    join public.memberships m
      on m.organisation_id in (c.hospital_id, c.assigned_lawyer_id)
    where c.id = case_id and m.user_id = (select auth.uid())
  )
);

create policy "participants view messages"
on public.case_messages for select to authenticated
using (
  exists (
    select 1 from public.raf_cases c
    join public.memberships m
      on m.organisation_id in (c.hospital_id, c.assigned_lawyer_id)
    where c.id = case_id and m.user_id = (select auth.uid())
  )
);

create policy "participants send messages"
on public.case_messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and exists (
    select 1 from public.raf_cases c
    join public.memberships m
      on m.organisation_id in (c.hospital_id, c.assigned_lawyer_id)
    where c.id = case_id and m.user_id = (select auth.uid())
  )
);

insert into storage.buckets (id, name, public)
values ('case-documents', 'case-documents', false)
on conflict (id) do nothing;

create policy "case participants read stored files"
on storage.objects for select to authenticated
using (
  bucket_id = 'case-documents'
  and exists (
    select 1 from public.raf_cases c
    join public.memberships m
      on m.organisation_id in (c.hospital_id, c.assigned_lawyer_id)
    where c.id = (storage.foldername(name))[1]
      and m.user_id = (select auth.uid())
  )
);

create policy "case participants upload stored files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'case-documents'
  and exists (
    select 1 from public.raf_cases c
    join public.memberships m
      on m.organisation_id in (c.hospital_id, c.assigned_lawyer_id)
    where c.id = (storage.foldername(name))[1]
      and m.user_id = (select auth.uid())
  )
);
