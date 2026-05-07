# My POS

A simple, modern, and clean Point of Sale (POS) application built with **Flutter** + **Supabase** + **BLoC**. Designed for small-to-medium businesses such as cafes, restaurants, and retail stores.

---

## ✨ Features

- 📊 **Dashboard** — Revenue overview, sales charts, best-selling products
- 🛒 **POS / Cashier** — Fast checkout with cart, discount, and tax support
- 📦 **Product Management** — Add, edit, delete products with image upload and category filtering
- 🧾 **Transaction History** — View, filter, and search past transactions
- 📉 **Inventory Management** — Stock in/out tracking with low stock warnings
- 📈 **Reports** — Daily, weekly, monthly reports with PDF/Excel export
- ⚙️ **Settings** — Store info, tax rate, currency, and theme toggle
- 🌙 **Dark Mode** — Full light and dark theme support
- 📱 **Responsive** — Optimized for tablets and mobile phones

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| State Management | flutter_bloc |
| Backend | Supabase (Auth + Database + Storage) |
| Navigation | go_router |
| Architecture | Clean Architecture + Feature-based folders |
| Charts | fl_chart |
| Barcode | mobile_scanner |
| Export | pdf, printing, syncfusion_flutter_xlsio |

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/artprasetya/My-POS.git
cd My-POS
```

### 2. Set up environment files

Copy the example files and fill in your Supabase credentials:

```bash
cp .env.staging.example .env.staging
cp .env.production.example .env.production
```

Edit each file:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
APP_ENV=staging   # or production
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Set up Supabase

Create the following tables in your Supabase dashboard (SQL editor):

<details>
<summary>Click to expand SQL schema</summary>

```sql
-- profiles
create table profiles (
  id uuid primary key references auth.users(id),
  email text,
  full_name text,
  role text default 'admin',
  pin text,
  avatar_url text,
  created_at timestamptz default now()
);

-- categories
create table categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  color text,
  icon text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- products
create table products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sku text,
  barcode text,
  category_id uuid references categories(id),
  price numeric not null default 0,
  cost_price numeric,
  stock integer default 0,
  image_url text,
  description text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- transactions
create table transactions (
  id uuid primary key default gen_random_uuid(),
  transaction_number text not null unique,
  subtotal numeric not null,
  discount_amount numeric default 0,
  tax_amount numeric default 0,
  total numeric not null,
  payment_method text not null,
  payment_status text default 'completed',
  cashier_id uuid references auth.users(id),
  notes text,
  created_at timestamptz default now()
);

-- transaction_items
create table transaction_items (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid references transactions(id) on delete cascade,
  product_id uuid references products(id),
  product_name text not null,
  quantity integer not null,
  unit_price numeric not null,
  subtotal numeric not null,
  created_at timestamptz default now()
);

-- inventory_logs
create table inventory_logs (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id),
  type text not null check (type in ('in', 'out')),
  quantity integer not null,
  notes text,
  created_at timestamptz default now()
);

-- Helper function for stock decrement
create or replace function decrement_stock(p_product_id uuid, p_quantity int)
returns void as $$
begin
  update products set stock = stock - p_quantity where id = p_product_id;
end;
$$ language plpgsql;
```

</details>

### 5. Run the app

```bash
# Staging
flutter run -t lib/main_staging.dart

# Production
flutter run -t lib/main_production.dart

# Run on specific device
flutter run -t lib/main_staging.dart -d chrome      # Web
flutter run -t lib/main_staging.dart -d android     # Android
flutter run -t lib/main_staging.dart -d ios         # iOS
```

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/          # FlavorConfig (staging/production)
│   ├── constants/       # Colors, sizes, app constants
│   ├── errors/          # Failure & Exception classes
│   ├── extensions/      # DateTime, number, string utilities
│   ├── theme/           # Light & dark theme
│   └── widgets/         # Shared UI components
├── features/
│   ├── auth/            # Login, session, roles
│   ├── dashboard/       # Revenue overview & charts
│   ├── inventory/       # Stock management
│   ├── pos/             # Cashier / checkout flow
│   ├── products/        # Product & category CRUD
│   ├── settings/        # App configuration
│   └── transactions/    # Transaction history & reports
├── routing/             # go_router setup + shell scaffold
├── services/            # Supabase client
├── main_staging.dart    # Staging entry point
└── main_production.dart # Production entry point
```

---

## 🔐 Environment Setup

This project uses two separate Supabase environments:

| Environment | File | Entry Point |
|-------------|------|-------------|
| Staging | `.env.staging` | `lib/main_staging.dart` |
| Production | `.env.production` | `lib/main_production.dart` |

> ⚠️ Never commit `.env.staging` or `.env.production`. They are gitignored. Use the `.example` files as templates.

---

## 📦 Build

```bash
# Android APK
flutter build apk -t lib/main_production.dart --release

# iOS
flutter build ios -t lib/main_production.dart --release

# Web
flutter build web -t lib/main_production.dart --release
```

---

## 🗺 Roadmap

- [x] Phase 1 — Foundation, theming, routing, core architecture
- [ ] Phase 2 — Auth flow & session management
- [ ] Phase 3 — Product management (full CRUD + image upload)
- [ ] Phase 4 — POS / Cashier system
- [ ] Phase 5 — Barcode scanner
- [ ] Phase 6 — Transaction history
- [ ] Phase 7 — Inventory management
- [ ] Phase 8 — Dashboard charts & analytics
- [ ] Phase 9 — Reports & PDF/Excel export
- [ ] Phase 10 — Settings & store configuration

---

## 📄 License

This project is private and not licensed for public distribution.
