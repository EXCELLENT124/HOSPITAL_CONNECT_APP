-- Health Connect accident report upgrade
-- Run this once in Supabase SQL Editor to permanently store Step 2 fields.

alter table public.raf_cases
  add column if not exists accident_location text,
  add column if not exists police_station text,
  add column if not exists police_case_number text,
  add column if not exists accident_report_number text,
  add column if not exists patient_accident_role text,
  add column if not exists hit_and_run boolean not null default false,
  add column if not exists vehicle_details text,
  add column if not exists witness_details text;

create index if not exists raf_cases_police_case_number_idx
on public.raf_cases(police_case_number);

create index if not exists raf_cases_accident_location_idx
on public.raf_cases(accident_location);
