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
| Backend | Supabase (Auth + DB + Storage) |
| Navigation | go_router |
| Architecture | Clean Architecture + Feature-based |
| Responsive UI | flutter_screenutil |
| Charts | fl_chart |
| Barcode | mobile_scanner |
| PDF/Export | pdf, printing, syncfusion_flutter_xlsio |

---

## ✅ Phase 1: Foundation & Core Setup (COMPLETE)

The following components have been fully implemented in the initial phase:

- **Project Foundation**: Flutter project initialized for Android, iOS, and Web.
- **Architecture**: Clean architecture folder structure implemented with 35+ files.
- **Services**: Supabase service initialized with environment variable support.
- **Theming**: Premium Material 3 design system with light/dark modes and Inter font.
- **Navigation**: go_router with ShellRoute for persistent bottom navigation.
- **Domain Models**: Full models for UserProfile, Product, Category, CartItem, Transaction, and InventoryLog.
- **Data Layer**: Repositories for Auth, Products, and Transactions with Supabase integration.
- **State Management**: BLoCs for Auth, Product, Cart, Transaction, and Dashboard.
- **UI Components**: Core widgets like PosCard, PosSearchBar, PosStatCard, and PosLoadingIndicator.
- **Screens**: Initial implementations of Login, Dashboard, and Product List screens.

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/artprasetya/My-POS.git
cd My-POS
```

### 2. Set up environment files

This project uses two separate Supabase environments:

| Environment | File | Entry Point |
|-------------|------|-------------|
| Staging | `.env.staging` | `lib/main_staging.dart` |
| Production | `.env.production` | `lib/main_production.dart` |

Copy the example files and fill in your Supabase credentials:

```bash
cp .env.staging.example .env.staging
cp .env.production.example .env.production
```

> ⚠️ Never commit `.env.staging` or `.env.production`. They are gitignored. Use the `.example` files as templates.

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
│   ├── constants/       # app_colors, app_constants, app_sizes
│   ├── errors/          # exceptions, failures
│   ├── extensions/      # datetime, number, string utilities
│   ├── theme/           # app_theme
│   └── widgets/         # pos_card, pos_empty_state, pos_loading_indicator, etc.
├── features/
│   ├── auth/            # AuthRepository, UserProfile, AuthBloc, LoginScreen
│   ├── dashboard/       # DashboardBloc, DashboardScreen
│   ├── inventory/       # InventoryLog model
│   ├── pos/             # CartItem, CartBloc, PosScreen
│   ├── products/        # ProductRepository, Product model, ProductListScreen
│   ├── settings/        # SettingsScreen
│   └── transactions/    # TransactionRepository, Transaction model, TransactionListScreen
├── routing/             # app_router, shell_scaffold
├── services/            # supabase_service
└── main.dart            # Shared bootstrap entry point
```

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

- [x] **Phase 1**: Foundation, theming, routing, core architecture
- [ ] **Phase 2**: Authentication (screens & flow, session persistence, PIN login)
- [ ] **Phase 3**: Product Management (Add/Edit screens, image upload, category CRUD)
- [ ] **Phase 4**: POS / Cashier System (Checkout flow, payment selection, receipt generation)
- [ ] **Phase 5**: Barcode Scanner (Camera scanning integration)
- [ ] **Phase 6**: Transaction History (Detail screens, date filtering)
- [ ] **Phase 7**: Inventory Management (Stock in/out UI, warnings)
- [ ] **Phase 8**: Dashboard (Enhanced charts & real-time analytics)
- [ ] **Phase 9**: Reports & Export (PDF/Excel generation)
- [ ] **Phase 10**: Settings (Store info, tax, currency configuration)

---

## 📄 License

This project is private and not licensed for public distribution.
