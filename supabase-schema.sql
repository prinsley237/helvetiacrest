create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  currency text not null check (currency in ('USD', 'EUR', 'GBP')),
  wallet_name text not null default 'Main' check (length(trim(wallet_name)) > 0),
  balance numeric(14, 2) not null default 0 check (balance >= 0),
  created_at timestamptz not null default now()
);

alter table public.wallets add column if not exists wallet_name text not null default 'Main';
alter table public.wallets drop constraint if exists wallets_user_id_currency_key;
create unique index if not exists wallets_user_currency_name_key on public.wallets (user_id, currency, wallet_name);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  wallet_id uuid references public.wallets (id) on delete set null,
  transaction_type text not null check (transaction_type in ('transfer', 'deposit', 'withdrawal', 'exchange', 'savings')),
  direction text not null check (direction in ('credit', 'debit')),
  title text not null,
  amount numeric(14, 2) not null check (amount >= 0),
  currency text not null check (currency in ('USD', 'EUR', 'GBP')),
  status text not null default 'completed' check (status in ('pending', 'completed', 'failed')),
  created_at timestamptz not null default now()
);

create table if not exists public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  target_amount numeric(14, 2) not null check (target_amount > 0),
  current_amount numeric(14, 2) not null default 0 check (current_amount >= 0),
  currency text not null check (currency in ('USD', 'EUR', 'GBP')),
  target_date date,
  created_at timestamptz not null default now(),
  check (current_amount <= target_amount)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  message text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists wallets_user_id_idx on public.wallets (user_id);
create index if not exists transactions_user_created_idx on public.transactions (user_id, created_at desc);
create index if not exists savings_goals_user_id_idx on public.savings_goals (user_id);
create index if not exists notifications_user_created_idx on public.notifications (user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.transactions enable row level security;
alter table public.savings_goals enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (id = (select auth.uid()));
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists "wallets_select_own" on public.wallets;
create policy "wallets_select_own" on public.wallets for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "wallets_insert_own_zero" on public.wallets;
create policy "wallets_insert_own_zero" on public.wallets for insert to authenticated with check (user_id = (select auth.uid()) and balance = 0);

drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own" on public.transactions for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "savings_goals_select_own" on public.savings_goals;
create policy "savings_goals_select_own" on public.savings_goals for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "savings_goals_insert_own" on public.savings_goals;
create policy "savings_goals_insert_own" on public.savings_goals for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "savings_goals_update_own" on public.savings_goals;
create policy "savings_goals_update_own" on public.savings_goals for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists "savings_goals_delete_own" on public.savings_goals;
create policy "savings_goals_delete_own" on public.savings_goals for delete to authenticated using (user_id = (select auth.uid()));

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert on public.wallets to authenticated;
grant select on public.transactions to authenticated;
grant select, insert, update, delete on public.savings_goals to authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

create or replace function public.handle_new_helvetia_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(coalesce(new.email, ''), '@', 1))
  )
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.wallets (user_id, currency, wallet_name)
  values (new.id, 'USD', 'Main'), (new.id, 'EUR', 'Main'), (new.id, 'GBP', 'Main')
  on conflict (user_id, currency, wallet_name) do nothing;

  insert into public.notifications (user_id, title, message)
  values (new.id, 'Welcome to Helvetia', 'Your account overview is ready.');

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_helvetia on auth.users;
create trigger on_auth_user_created_helvetia
after insert on auth.users
for each row execute function public.handle_new_helvetia_user();

insert into public.profiles (id, full_name)
select
  users.id,
  coalesce(nullif(trim(users.raw_user_meta_data ->> 'full_name'), ''), split_part(coalesce(users.email, ''), '@', 1))
from auth.users as users
on conflict (id) do nothing;

insert into public.wallets (user_id, currency, wallet_name)
select users.id, currencies.currency, 'Main'
from auth.users as users
cross join (values ('USD'), ('EUR'), ('GBP')) as currencies(currency)
on conflict (user_id, currency, wallet_name) do nothing;

create or replace function public.transfer_between_wallets(
  p_source_wallet uuid,
  p_target_wallet uuid,
  p_amount numeric,
  p_description text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_source public.wallets%rowtype;
  v_target public.wallets%rowtype;
  v_description text := coalesce(nullif(trim(p_description), ''), 'Wallet transfer');
begin
  if v_user_id is null then
    raise exception 'Sign in is required to transfer between wallets.';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Enter an amount greater than zero.';
  end if;
  if p_source_wallet = p_target_wallet then
    raise exception 'Choose two different wallets.';
  end if;

  perform wallet.id
  from public.wallets as wallet
  where wallet.user_id = v_user_id
    and wallet.id in (p_source_wallet, p_target_wallet)
  order by wallet.id
  for update;

  select * into v_source
  from public.wallets
  where id = p_source_wallet and user_id = v_user_id;
  if not found then
    raise exception 'Source wallet was not found.';
  end if;

  select * into v_target
  from public.wallets
  where id = p_target_wallet and user_id = v_user_id;
  if not found then
    raise exception 'Destination wallet was not found.';
  end if;
  if v_source.currency <> v_target.currency then
    raise exception 'Internal transfers require wallets in the same currency.';
  end if;

  update public.wallets
  set balance = balance - p_amount
  where id = v_source.id and user_id = v_user_id and balance >= p_amount;
  if not found then
    raise exception 'Insufficient funds.';
  end if;

  update public.wallets
  set balance = balance + p_amount
  where id = v_target.id and user_id = v_user_id;

  insert into public.transactions (user_id, wallet_id, transaction_type, direction, title, amount, currency, status)
  values
    (v_user_id, v_source.id, 'transfer', 'debit', v_description || ' · To wallet', p_amount, v_source.currency, 'completed'),
    (v_user_id, v_target.id, 'transfer', 'credit', v_description || ' · From wallet', p_amount, v_source.currency, 'completed');

  insert into public.notifications (user_id, title, message)
  values (v_user_id, 'Transfer complete', v_description || ' completed between your wallets.');
end;
$$;

revoke all on function public.transfer_between_wallets(uuid, uuid, numeric, text) from public;
revoke all on function public.transfer_between_wallets(uuid, uuid, numeric, text) from anon;
grant execute on function public.transfer_between_wallets(uuid, uuid, numeric, text) to authenticated;
