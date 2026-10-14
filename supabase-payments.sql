-- Run AFTER supabase.sql. Adds the KSh 50 M-Pesa fee (30 days of listing per payment).
alter table businesses add column paid_until timestamptz;
update businesses set paid_until = now() + interval '30 days' where status='approved'; -- keeps your existing test listings live; delete this line if unwanted

create table payments(
  id bigint generated always as identity primary key,
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  mpesa_code text not null unique check(mpesa_code ~ '^[A-Z0-9]{10}$'),
  amount int not null default 50,
  status text not null default 'pending' check(status in ('pending','confirmed','rejected')),
  created_at timestamptz not null default now()
);
alter table payments enable row level security;
create policy "owner sees payments" on payments for select to authenticated using (owner=auth.uid());
create policy "owner submits payment" on payments for insert to authenticated with check (owner=auth.uid() and status='pending' and amount=50);

-- You set a payment to 'confirmed' in the Table Editor -> listing is approved and extended 30 days
create or replace function activate_on_payment() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status='confirmed' and old.status<> 'confirmed' then
    update businesses set status='approved', paid_until=greatest(coalesce(paid_until,now()),now())+interval '30 days'
    where owner=new.owner and status<>'rejected';
  end if;
  return new;
end $$;
create trigger payment_confirmed after update on payments for each row execute function activate_on_payment();

-- Only paid, approved listings are public; owners can't pre-set paid_until
drop policy "read businesses" on businesses;
create policy "read businesses" on businesses for select using ((status='approved' and paid_until>now()) or owner=auth.uid());
drop policy "owner registers" on businesses;
create policy "owner registers" on businesses for insert to authenticated with check (owner=auth.uid() and status='pending' and paid_until is null);
drop policy "read deals" on deals;
create policy "read deals" on deals for select using (exists(select 1 from businesses b where b.id=business_id and b.status='approved' and b.paid_until>now()));
drop policy "owner adds deals" on deals;
create policy "owner adds deals" on deals for insert to authenticated with check (exists(select 1 from businesses b where b.id=business_id and b.owner=auth.uid() and b.status='approved' and b.paid_until>now()));
