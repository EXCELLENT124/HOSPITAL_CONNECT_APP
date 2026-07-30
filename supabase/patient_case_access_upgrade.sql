-- Health Connect patient case access upgrade
-- Run this once in Supabase SQL Editor.
-- It allows patients to log in with the email captured on a RAF case
-- and see only their own linked case information.

alter table public.raf_cases
  add column if not exists patient_email text,
  add column if not exists patient_user_id uuid references auth.users(id);

create index if not exists raf_cases_patient_email_idx
on public.raf_cases(lower(patient_email));

create index if not exists raf_cases_patient_user_idx
on public.raf_cases(patient_user_id);

create or replace function public.is_case_participant(target_case text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.raf_cases c
    join public.memberships m
      on m.organisation_id in (c.hospital_id, c.assigned_lawyer_id)
    where c.id = target_case
      and m.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.raf_cases c
    where c.id = target_case
      and (
        c.patient_user_id = auth.uid()
        or lower(c.patient_email) = lower(coalesce(auth.email(), ''))
      )
  )
  or public.is_platform_admin();
$$;

drop policy if exists "patients view own cases" on public.raf_cases;
create policy "patients view own cases"
on public.raf_cases
for select
to authenticated
using (
  patient_user_id = auth.uid()
  or lower(patient_email) = lower(coalesce(auth.email(), ''))
);

drop policy if exists "patients view documents" on public.case_documents;
create policy "patients view documents"
on public.case_documents
for select
to authenticated
using (public.is_case_participant(case_id));

drop policy if exists "patients view messages" on public.case_messages;
create policy "patients view messages"
on public.case_messages
for select
to authenticated
using (public.is_case_participant(case_id));

drop policy if exists "patients send messages" on public.case_messages;
create policy "patients send messages"
on public.case_messages
for insert
to authenticated
with check (
  sender_id = auth.uid()
  and public.is_case_participant(case_id)
);
