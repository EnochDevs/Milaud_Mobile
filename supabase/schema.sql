-- Milaud app — full schema for the "Mylaud:)" Supabase project
-- (enojnhijfabncaeoyctt). Generated from what the Flutter app actually
-- reads/writes (see lib/services/app_services.dart,
-- lib/providers/content_providers.dart, lib/providers/auth_provider.dart,
-- lib/services/push_notification_service.dart).
--
-- HOW TO RUN: Supabase Dashboard → SQL Editor → New query → paste this
-- whole file → Run. This project was created empty, so there's no
-- cleanup step — every statement here is IF NOT EXISTS / OR REPLACE, so
-- it's safe to re-run.

create extension if not exists pgcrypto;

-- ─────────────────────────────────────────────────────────
-- PROFILES — one row per auth user (auth_provider.dart)
-- ─────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  name       text not null default '',
  email      text not null default '',
  phone      text,
  address    text,
  avatar_url text,
  fcm_token  text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- ─────────────────────────────────────────────────────────
-- ANNOUNCEMENTS (content_providers.dart, app_services.dart)
-- ─────────────────────────────────────────────────────────
create table if not exists public.announcements (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  description  text not null,
  category     text not null default 'General',
  image_url    text,
  is_important boolean not null default false,
  created_by   uuid references auth.users (id),
  created_at   timestamptz not null default now()
);

alter table public.announcements enable row level security;

create policy "Anyone can view announcements"
  on public.announcements for select
  using (true);

-- NOTE: this lets any signed-in resident post an announcement, because
-- this app has no admin-role concept yet. Once you add one (e.g. a
-- `role` column on profiles), tighten this to something like
-- `exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')`.
create policy "Authenticated users can post announcements"
  on public.announcements for insert
  with check (auth.role() = 'authenticated');

-- Per-user read state for announcements (kept separate from the
-- announcement itself since read status is per-resident, not global).
create table if not exists public.announcement_reads (
  user_id         uuid not null references auth.users (id) on delete cascade,
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  read_at         timestamptz not null default now(),
  primary key (user_id, announcement_id)
);

alter table public.announcement_reads enable row level security;

create policy "Users can view their own read receipts"
  on public.announcement_reads for select
  using (auth.uid() = user_id);

create policy "Users can mark announcements as read for themselves"
  on public.announcement_reads for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own read receipts"
  on public.announcement_reads for update
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────
-- NOTIFICATIONS (content_providers.dart, app_services.dart,
-- push_notification_service.dart)
-- ─────────────────────────────────────────────────────────
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  title      text not null,
  message    text not null,
  type       text not null default 'system',
  is_read    boolean not null default false,
  data       jsonb,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create policy "Users can view their own notifications"
  on public.notifications for select
  using (auth.uid() = user_id);

create policy "Users can create their own notifications"
  on public.notifications for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own notifications"
  on public.notifications for update
  using (auth.uid() = user_id);

create policy "Users can delete their own notifications"
  on public.notifications for delete
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────
-- HOTLINES — public read-only reference data (app_services.dart)
-- ─────────────────────────────────────────────────────────
create table if not exists public.hotlines (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  number      text not null,
  type        text not null default 'General',
  description text,
  icon        text,
  is_active   boolean not null default true
);

alter table public.hotlines enable row level security;

create policy "Anyone can view active hotlines"
  on public.hotlines for select
  using (true);

-- ─────────────────────────────────────────────────────────
-- DOCUMENT REQUESTS (content_providers.dart, app_services.dart)
-- ─────────────────────────────────────────────────────────
create table if not exists public.document_requests (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  document_type text not null,
  purpose       text not null,
  status        text not null default 'pending',
  fee           text,
  notes         text,
  created_at    timestamptz not null default now()
);

alter table public.document_requests enable row level security;

create policy "Users can view their own document requests"
  on public.document_requests for select
  using (auth.uid() = user_id);

create policy "Users can create their own document requests"
  on public.document_requests for insert
  with check (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────
-- CITIZEN REPORTS (app_services.dart, ai_triage_service.dart results)
-- ─────────────────────────────────────────────────────────
create table if not exists public.citizen_reports (
  id                           uuid primary key default gen_random_uuid(),
  user_id                      uuid not null references auth.users (id) on delete cascade,
  category                     text not null,
  subcategory                  text not null,
  description                  text not null,
  location                     text not null,
  photo_urls                   text[] not null default '{}',
  contact                      text,
  severity                     text,
  ai_suggested_severity        text,
  ai_severity_confidence       numeric,
  ai_detected_image_category   text,
  ai_image_valid               boolean,
  requires_manual_review       boolean not null default false,
  status                       text not null default 'received',
  created_at                   timestamptz not null default now(),
  updated_at                   timestamptz not null default now()
);

alter table public.citizen_reports enable row level security;

create policy "Users can view their own citizen reports"
  on public.citizen_reports for select
  using (auth.uid() = user_id);

create policy "Users can create their own citizen reports"
  on public.citizen_reports for insert
  with check (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────
-- FLOOD ALERTS — public read-only (app_services.dart)
-- ─────────────────────────────────────────────────────────
create table if not exists public.flood_alerts (
  id             uuid primary key default gen_random_uuid(),
  level          text not null default 'Low',
  affected_areas text[] not null default '{}',
  water_level    text,
  advice         text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

alter table public.flood_alerts enable row level security;

create policy "Anyone can view flood alerts"
  on public.flood_alerts for select
  using (true);

-- ─────────────────────────────────────────────────────────
-- DASHBOARD STATS SOURCE TABLES — public read-only
-- (content_providers.dart: DashboardStatsNotifier)
-- ─────────────────────────────────────────────────────────
create table if not exists public.projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null default '',
  description text,
  status      text not null default 'active', -- 'active' counts toward the dashboard
  created_at  timestamptz not null default now()
);

alter table public.projects enable row level security;

create policy "Anyone can view projects"
  on public.projects for select
  using (true);

create table if not exists public.municipal_budget (
  fiscal_year     int primary key,
  total_allocated numeric not null default 0,
  total_utilized  numeric not null default 0
);

alter table public.municipal_budget enable row level security;

create policy "Anyone can view the municipal budget"
  on public.municipal_budget for select
  using (true);

create table if not exists public.barangay_assemblies (
  id       uuid primary key default gen_random_uuid(),
  title    text not null default '',
  held_at  timestamptz not null default now()
);

alter table public.barangay_assemblies enable row level security;

create policy "Anyone can view barangay assemblies"
  on public.barangay_assemblies for select
  using (true);

-- ─────────────────────────────────────────────────────────
-- STORAGE — report-photos bucket (app_services.dart:
-- CitizenReportService.submitReport() uploads here)
-- ─────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('report-photos', 'report-photos', true)
on conflict (id) do nothing;

-- storage.objects is a shared system table, so re-running this script
-- would otherwise hit "policy already exists" on a second run — drop
-- first so this block stays safe to re-run.
drop policy if exists "Anyone can view report photos" on storage.objects;
drop policy if exists "Users can upload their own report photos" on storage.objects;

create policy "Anyone can view report photos"
  on storage.objects for select
  using (bucket_id = 'report-photos');

-- Upload path is '<uid>/<timestamp>_<n>.jpg' — this restricts uploads to
-- each resident's own folder (see submitReport() in app_services.dart).
create policy "Users can upload their own report photos"
  on storage.objects for insert
  with check (
    bucket_id = 'report-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ─────────────────────────────────────────────────────────
-- SEED DATA — optional, so screens aren't empty on first run.
-- Delete or edit freely; the app works fine with none of this.
-- ─────────────────────────────────────────────────────────
insert into public.hotlines (name, number, type, is_active) values
  ('BFP Milaor',  '0920-983-9802', 'Fire',   true),
  ('PNP Milaor',  '0917-000-0000', 'Police', true),
  ('MDRRMO',      '0918-000-0000', 'Rescue', true)
on conflict do nothing;
