-- HAPA database setup. Paste into Supabase > SQL Editor > Run.
create table businesses(
  id bigint generated always as identity primary key,
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check(char_length(name) between 2 and 80),
  category text not null check(category in ('food','beauty','stay','shop','auto','fun')),
  phone text not null check(phone ~ '^254[0-9]{9}$'),
  lat double precision, lng double precision,
  open_h int not null default 8 check(open_h between 0 and 23),
  close_h int not null default 19 check(close_h between 1 and 24),
  services text[] not null default '{}',
  status text not null default 'pending' check(status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  unique(owner)
);
create table deals(
  id bigint generated always as identity primary key,
  business_id bigint not null references businesses(id) on delete cascade,
  title text not null check(char_length(title) between 2 and 80),
  price int not null check(price > 0),
  pct int not null check(pct between 1 and 90),
  qty int not null check(qty > 0),
  end_at timestamptz not null,
  created_at timestamptz not null default now()
);
alter table businesses enable row level security;
alter table deals enable row level security;
-- Anyone sees approved businesses; owners also see their own (even pending)
create policy "read businesses" on businesses for select using (status='approved' or owner=auth.uid());
-- Owners can only create PENDING listings for themselves (you approve in the dashboard)
create policy "owner registers" on businesses for insert to authenticated with check (owner=auth.uid() and status='pending');
create policy "read deals" on deals for select using (exists(select 1 from businesses b where b.id=business_id and b.status='approved'));
create policy "owner adds deals" on deals for insert to authenticated with check (exists(select 1 from businesses b where b.id=business_id and b.owner=auth.uid() and b.status='approved'));
create policy "owner removes deals" on deals for delete to authenticated using (exists(select 1 from businesses b where b.id=business_id and b.owner=auth.uid()));
