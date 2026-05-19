# My POS

A simple, modern, and clean Point of Sale (POS) application designed to help small-to-medium businesses (cafes, restaurants, and retail stores) manage daily sales, products, and inventory with ease.

---

## ✨ Features

- 📊 **Dashboard** — Monitor revenue overview, sales charts, and see your best-selling products in real time.
- 🛒 **POS / Cashier** — Perform fast checkout with an interactive cart, support for discounts, and simplified cash payments.
- 📦 **Product Management** — Easily add, edit, and organize products with categories, pricing tiers, and stock numbers.
- 🧾 **Transaction History** — Track and view previous transactions, and search/filter through your sales records.
- 📉 **Inventory Tracking** — Stay on top of your stock levels with automated inventory logs and low stock alerts.
- 📈 **Reports** — View and export daily, weekly, or monthly sales reports into Excel or PDF format.
- ⚙️ **Settings** — Customize your store information, tax rates, local currency, and system preferences.
- 🌙 **Dark Mode** — Fully responsive design that works beautifully in both light and dark modes.

---

## 💡 How to Use

### 1. Cashier & Checkout Flow
- Select products from the screen to add them to the cart.
- Adjust quantities or apply a discount if needed.
- Click the **Checkout** button to confirm payment (currently supporting Cash payment).
- Print or save the receipt once the transaction is complete.

### 2. Product & Stock Management
- Go to the **Products** section to see your catalog.
- Add new items with specific stock quantities, pricing, and cost prices.
- When sales are completed, the app automatically deducts stock and records the change in your inventory log.

### 3. Analytics & Reporting
- Check the **Dashboard** for a quick summary of today's, this week's, and this month's revenue.
- Generate and download reports in **PDF** or **Excel** formats to easily share with your team or keep for accounting.

---

## 🚀 Launching the Application

To run the application on your device:

```bash
# Start the application
flutter run -t lib/main_production.dart
```

To run on a specific platform:
- **Web (Chrome):** `flutter run -t lib/main_production.dart -d chrome`
- **Android:** `flutter run -t lib/main_production.dart -d android`
- **iOS:** `flutter run -t lib/main_production.dart -d ios`

---

## 📄 Privacy & License

This application is private and intended solely for internal store operations.
