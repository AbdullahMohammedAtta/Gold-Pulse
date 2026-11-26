# GoldPulse — Real-Time Gold Market Tracker & Portfolio Manager

**GoldPulse** is a cross-platform mobile application built with **Flutter** for tracking live gold prices, inspecting market trends across historical timeframes, and managing personal gold holdings with real-time Profit & Loss (`PnL`) calculations. It includes full `RTL`/`LTR` support for **Arabic** and **English**, **Dark** and **Light** themes, multi-currency display, and local persistence.

![GoldPulse Overview](screenshots/overview_banner.png)

---

## Problem Statement & Value Proposition

Tracking physical gold investments and market movements often involves fragmented tools and manual math:

- **Fragmented Market & Karat Views:** Checking live prices across multiple karats (`24K`, `22K`, `21K`, `18K`) and troy ounces in different currencies can be scattered and inconsistent.
- **Unclear Portfolio Performance:** Investors who hold bars, coins, or jewelry need an easy way to compare total buy cost against current market value, total weight, and net gain/loss (`PnL`).
- **Rigid User Experience:** Users benefit from fast local storage, bilingual support (`AR`/`EN`), theme switching (`Dark`/`Light`), and clean mobile ergonomics without unnecessary clutter.

**How GoldPulse Helps:** It brings live gold rates, trend charts, a persistent gold vault/portfolio, and customization settings together into a unified mobile experience with consistent gram-based calculations.

![GoldPulse Portfolio & PnL Value](screenshots/problem_solution_vault.png)

---

## Key Features

- **Live Gold Market & Currency Switching:**
  - Displays real-time gold prices across karats (`24K`, `22K`, `21K`, `18K`) and ounce references.
  - Supports switching currencies (such as `EGP`, `USD`, etc.) and recalculating values seamlessly.
- **Historical Trend Charts:**
  - Visualizes gold price movements across selectable timeframes (`1W`, `1M`, `3M`) with interactive inspection.
- **Gold Portfolio & PnL Tracking:**
  - Full `CRUD` support (Add, Edit, Delete) for gold items with item name, weight in grams, karat, and total purchase cost.
  - Automatically computes total weight (grams and approximate troy ounces), total current market value, total cost basis, and net Profit/Loss (`PnL`) in both currency and percentage with clear positive/negative/neutral styling.
  - Persists holdings locally via `SharedPreferences`.
- **Settings & Localization:**
  - Switch between **Arabic (`ar`)** and **English (`en`)** with automatic `RTL`/`LTR` layout adaptation.
  - Switch between **Dark Mode** and **Light Mode**.
  - Configure default currency and export/share a portfolio summary.
- **App Branding & Quick Launch:**
  - Unified navigation shell (`LayOutScreen`) featuring the **GoldPulse** brand mark in the app bar, a brief in-app logo entrance on startup, and custom launcher icon support.

![Live Gold Prices & Historical Charts](screenshots/features_market_chart.png)

---

## Tech Stack & Architecture

- **Framework & Language:** Flutter, Dart.
- **State Management:** `flutter_bloc` (`Cubit` / `Bloc`), including `GoldCubit`, `SettingsCubit`, and `LayOutCubit`.
- **Local Storage:** `shared_preferences` for persisting portfolio holdings and user preferences/currency.
- **Data & Networking Layer:** `GoldService` and `GoldPriceModel` for fetching and parsing gold market data.
- **Localization & Theming:** `flutter_localizations` (`ar`, `en`) paired with custom Light and Dark `ThemeData` definitions.

![GoldPulse Architecture & State Flow](screenshots/architecture_flow.png)

---

## Prerequisites

Before running or building the project, make sure you have:

1. **Flutter SDK** and **Dart SDK** installed and added to your system `PATH`.
2. **Android SDK** and **Android Studio** (or **Xcode** on macOS if building for iOS).
3. A connected **Android physical device** (with USB Debugging enabled) or an **Android Emulator** / **iOS Simulator**.
4. An active **internet connection** to fetch live gold market data.

Verify your environment before starting:

```bash
flutter doctor -v
