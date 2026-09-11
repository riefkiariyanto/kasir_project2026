-- Kasir 2026 backend schema (Postgres, Railway)

-- fallback untuk gen_random_uuid() di Postgres < 13 (Railway biasanya >= 15, tapi aman dijaga)
create extension if not exists pgcrypto;

create table if not exists store_settings (
  id smallint primary key default 1,
  name text not null default '',
  address text not null default '',
  phone text not null default '',
  updated_at timestamptz not null default now(),
  constraint store_settings_single_row check (id = 1)
);
insert into store_settings (id) values (1) on conflict (id) do nothing;

create table if not exists admins (
  id uuid primary key default gen_random_uuid(),
  username text not null unique,
  password_hash text not null,
  created_at timestamptz not null default now()
);

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon_key text,
  created_at timestamptz not null default now()
);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price integer not null check (price >= 0),
  category_id uuid references categories (id) on delete set null,
  tag text,
  image_path text,
  created_at timestamptz not null default now()
);
create index if not exists products_category_id_idx on products (category_id);

create table if not exists employees (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  pin_hash text not null,
  created_at timestamptz not null default now()
);

create sequence if not exists orders_invoice_seq;

create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  invoice_no text not null unique,
  total integer not null check (total >= 0),
  method text not null check (method in ('qris', 'cash')),
  cashier_id uuid references employees (id) on delete set null,
  cashier_name text not null,
  created_at timestamptz not null default now()
);

create or replace function set_order_invoice_no()
returns trigger
language plpgsql
as $$
begin
  if new.invoice_no is null then
    new.invoice_no := 'INV-' || lpad(nextval('orders_invoice_seq')::text, 3, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists orders_set_invoice_no on orders;
create trigger orders_set_invoice_no
  before insert on orders
  for each row
  execute function set_order_invoice_no();

-- snapshot (product_name/price) + FK nullable: histori harga akurat meski produk diedit/dihapus
create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  product_id uuid references products (id) on delete set null,
  product_name text not null,
  price integer not null check (price >= 0),
  quantity integer not null check (quantity > 0)
);
create index if not exists order_items_order_id_idx on order_items (order_id);
create index if not exists order_items_product_id_idx on order_items (product_id);

create table if not exists finance_entries (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid references employees (id) on delete set null,
  employee_name text not null,
  type text not null check (type in ('loan', 'transfer')),
  amount integer not null check (amount >= 0),
  created_at timestamptz not null default now()
);

-- session store untuk express-session (connect-pg-simple)
create table if not exists session (
  sid varchar not null collate "default",
  sess json not null,
  expire timestamp(6) not null,
  constraint session_pkey primary key (sid)
);
create index if not exists idx_session_expire on session (expire);
