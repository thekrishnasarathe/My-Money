# MONEY - Master Directory Structure & Educational Teaching Guide 🎓📁
### *Exhaustive Technical Encyclopedia & 10-Module Codebase Curriculum*

![Product](https://img.shields.io/badge/product-MONEY-blue.svg)
![Owner](https://img.shields.io/badge/owner-Krishna%20Sarathe-orange.svg)
![Specification](https://img.shields.io/badge/specification-Technical%20%26%20Educational%20Guide-brightgreen.svg)

> **Master Reference Document**: Created by **Krishna Sarathe** (`thekrishnasarathe000@gmail.com`). Serves a dual purpose: (1) An exhaustive technical specification detailing the **exact code implementation**, **importance**, and **dependencies** for every file, and (2) A complete **10-module educational curriculum** for teaching this project to students, mentees, and engineering teams.

---

## 👨‍💻 Ownership & Educator Metadata
- **Product Name**: `MONEY` (App Launcher Icon Label) / `My-Money`
- **Product Owner, Architect & Lead Educator**: **Krishna Sarathe**
- **Official Contact Email**: `thekrishnasarathe000@gmail.com`
- **Package Identifier**: `com.krishnasarathe.mymoney`
- **Copyright**: `© 2026 Krishna Sarathe. All rights reserved.`

---

# 📑 Executive Overview & Subsystem Summary

### 1. 🌳 Master Workspace Hierarchy (`My-Paisa/`)
- **`My-Money/`**: Main Flutter application source directory.
- **`releases/`**: Production compiled build outputs (`MONEY-v1.0-release.apk` & `MONEY-v1.0-release.aab`).
- **`Launch-MONEY-Laptop.bat`**: 1-click Python HTTP Web App server launcher on port 8080.
- **`README.md`**: Enterprise 10/10 Technical Architecture Blueprint.
- **`DIRECTORY_STRUCTURE.md`**: Master Directory Architecture & Teaching Guide (This File).

### 2. 📱 Detailed `lib/` Codebase Architecture
- **`lib/database/db_helper.dart`**: SQLite singleton, v1➔v4 migrations, B-Tree indexes (`idx_exp_user_date`), auto-seeding.
- **`lib/models/`**: Domain models (`expense.dart`, `income.dart`, `models.dart` for Categories, Goals, Subscriptions, Accounts).
- **`lib/providers/app_provider.dart`**: Master `ChangeNotifier` state bus, calculation caching, reactive dispatchers.
- **`lib/repositories/financial_repository.dart`**: Repository abstraction decoupling SQL execution from UI state.
- **`lib/screens/`**: Complete screen breakdown (`dashboard/`, `transactions/`, `analytics/`, `categories/`, `goals/`, `recurring/`, `settings/`, `pin_lock_screen.dart`, `splash_screen.dart`).
- **`lib/services/`**: `firebase_service.dart` (remote telemetry/lockdown), `notification_service.dart`, `session_manager.dart`.
- **`lib/utils/`**: `theme.dart` (Dark glassmorphism palette), `constants.dart` (Owner metadata: **Krishna Sarathe**), `pdf_export.dart`.
- **`lib/main.dart`**: Application entrypoint & Provider initialization.

### 3. 🤖 Native Platform Configurations
- Detailed breakdown of `android/` (`com.krishnasarathe.mymoney`), `web/` (`index.html` & `manifest.json`), `windows/` (`CMakeLists.txt` & `main.cpp`), `ios/`, `linux/`, and `macos/`.

---

# 🎓 10-Module Educational Curriculum (Teaching Roadmap)

This section maps the codebase into a structured 10-module curriculum for instructing how to build MONEY from 0% to 100%.

```text
[ Module 1 ] Architecture & System Foundations (0% ➔ 10%)
     │
[ Module 2 ] Data Domain Models & Serialization (10% ➔ 20%)
     │
[ Module 3 ] SQLite Database Engine & Migration v4 (20% ➔ 35%)
     │
[ Module 4 ] Repository Pattern & Data Abstraction (35% ➔ 45%)
     │
[ Module 5 ] Reactive State Management with Provider (45% ➔ 60%)
     │
[ Module 6 ] Design System, Dark Theme & Reusable Widgets (60% ➔ 70%)
     │
[ Module 7 ] UI Screen Workflows & Analytics Dashboards (70% ➔ 80%)
     │
[ Module 8 ] Security Architecture, Salted SHA-256 & Biometrics (80% ➔ 90%)
     │
[ Module 9 ] PDF Report Generator & Remote Telemetry (90% ➔ 95%)
     │
[ Module 10 ] Multi-Platform Building, Packaging & Deployment (95% ➔ 100%)
```

---

# 🔍 Complete File-by-File Technical & Educational Breakdown

## 1. 📁 Root Level Directories & Workspace Files

### 📄 1.1 `My-Paisa/README.md`
- **Exact Work Performed**: 0% ➔ 100% technical architecture blueprint, functional requirements, threat model, security rules, and setup guide.
- **Technical Importance**: Primary product documentation for developers, auditors, and engineering teams.
- **Dependencies**: References build paths in `releases/` and source in `My-Money/`.
- **🎓 Teaching Point**: Teach students how to write enterprise-grade software architecture documentation.

---

### 📄 1.2 `My-Paisa/DIRECTORY_STRUCTURE.md`
- **Exact Work Performed**: Comprehensive specification and curriculum guide mapping every single file, dependency, work item, and teaching lesson.
- **Technical Importance**: Provides exact system mapping for maintenance, refactoring, and student instruction.
- **Dependencies**: Maps the complete workspace.
- **🎓 Teaching Point**: Instruct students on how to maintain structural codebase transparency.

---

### 📄 1.3 `My-Paisa/Launch-MONEY-Laptop.bat`
- **Exact Work Performed**: Windows Command Batch script that sets working directory to `My-Money\build\web`, launches default browser at `http://localhost:8080`, and runs local Python HTTP server.
- **Technical Importance**: Enables 1-click execution on any Windows laptop without needing Flutter SDK installed.
- **Dependencies**: Requires `python` and compiled Web assets.
- **🎓 Teaching Point**: Teach students deployment scripts for non-technical end users.

---

## 2. 📱 Core Application Source Code (`lib/`)

### 2.1 Database Layer (`lib/database/`)

#### 📄 `lib/database/db_helper.dart` (Module 3 Target)
- **Exact Work Performed**:
  - Implements SQLite Database Singleton using `sqflite`.
  - Creates 8 relational SQL tables (`expenses`, `incomes`, `categories`, `savings_goals`, `recurring_v2`, `accounts`, `debts`, `budgets`).
  - Manages schema migrations from v1 to v4 (adding multi-user `user_id` columns, payment methods, tags, descriptions).
  - Configures composite performance indexes (`idx_exp_user_date` & `idx_inc_user_date`).
  - Implements multi-user isolation queries (`user_id = ? OR is_default = 1`) and auto-seeds default fallback categories.
- **Technical Importance**: CRITICAL. Single local persistence layer. If this file fails, no app data can be stored.
- **Dependencies**: Imports `sqflite`, `path`, `models.dart`, `expense.dart`, `income.dart`.
- **🎓 Teaching Point**:
  - Teach Singleton pattern: `static final DbHelper instance = DbHelper._init();`.
  - Demonstrate why composite B-Tree indexes drop query latency from `O(N)` scans to `<10ms` `O(log N)` lookups.
  - **Student Lab Exercise**: Write an `ALTER TABLE` migration block for adding a `is_favorite` column.

---

### 2.2 Data Domain Models (`lib/models/`)

#### 📄 `lib/models/expense.dart` (Module 2 Target)
- **Exact Work Performed**: Defines `Expense` data class (`id`, `userId`, `name`, `amount`, `category`, `paymentMethod`, `description`, `tags`, `date`, `createdAt`). Implements `toMap()`, `fromMap()`, and `copyWith()`.
- **Technical Importance**: Standardizes expense transaction data structures across storage and UI.
- **Dependencies**: Used by `db_helper.dart`, `financial_repository.dart`, `app_provider.dart`, UI screens.
- **🎓 Teaching Point**: Explain storing `DateTime` as Unix epoch milliseconds (`date.millisecondsSinceEpoch`).

---

#### 📄 `lib/models/income.dart` (Module 2 Target)
- **Exact Work Performed**: Defines `Income` data class (`id`, `userId`, `source`, `amount`, `category`, `paymentMethod`, `description`, `tags`, `date`, `createdAt`). Implements `toMap()`, `fromMap()`, and `copyWith()`.
- **Technical Importance**: Standardizes income data structures across storage and UI.
- **Dependencies**: Used by `db_helper.dart`, `financial_repository.dart`, `app_provider.dart`, UI screens.
- **🎓 Teaching Point**: Contrast domain entity differences between `Income` (`source`) and `Expense` (`name`).

---

#### 📄 `lib/models/models.dart` (Module 2 Target)
- **Exact Work Performed**: Defines secondary domain entities: `AppCategory`, `SavingsGoal`, `RecurringExpense`, `Account`, and `SpendingLimit`.
- **Technical Importance**: Centralizes domain entities for categories, goals, and recurring subscriptions.
- **Dependencies**: Used across database, repository, provider, and UI screens.
- **🎓 Teaching Point**: Teach modeling immutable objects and copy constructors (`copyWith`).

---

### 2.3 State Management Layer (`lib/providers/`)

#### 📄 `lib/providers/app_provider.dart` (Module 5 Target)
- **Exact Work Performed**:
  - Implements master `ChangeNotifier` reactive state bus.
  - Manages state arrays for expenses, incomes, categories, goals, recurring subscriptions, accounts, theme mode, and security locks.
  - Implements fallback category generators (`expenseCategories()` & `incomeCategories()`) preventing empty screen states.
  - Exposes mutation dispatchers (`addExpense`, `updateExpense`, `deleteExpense`, `addIncome`) that trigger `notifyListeners()`.
  - Calculates net balance, spending velocity, and category ratios with calculation caching.
- **Technical Importance**: CRITICAL. Connects data models to UI widgets. The reactive brain of the application.
- **Dependencies**: Imports `financial_repository.dart`, `models.dart`, `constants.dart`, `shared_preferences`.
- **🎓 Teaching Point**:
  - Differentiate `context.watch<AppProvider>()` (re-builds UI on change) vs `context.read<AppProvider>()` (calls action methods without rebuild).
  - **Student Lab Exercise**: Trace the execution flow from tapping "Save" button to updating `AppProvider` and refreshing the Dashboard card.

---

### 2.4 Repository Layer (`lib/repositories/`)

#### 📄 `lib/repositories/financial_repository.dart` (Module 4 Target)
- **Exact Work Performed**: Implements Repository Pattern, abstracting database SQL execution from provider state logic. Injects user session keys (`_currentUserId`) into calls.
- **Technical Importance**: Decouples UI state from database engine, enabling effortless future cloud sync integration.
- **Dependencies**: Wraps `db_helper.dart`.
- **🎓 Teaching Point**: Explain why Provider should call Repository methods rather than calling raw SQL statements directly.

---

### 2.5 UI Screen Views & Flow (`lib/screens/`)

#### 📄 `lib/screens/splash_screen.dart` (Module 7 Target)
- **Exact Work Performed**: Initial application splash view that checks PIN lock configuration, initializes preferences, displays brand logo, and routes to PIN unlock or Dashboard.
- **Technical Importance**: Entry gatekeeper ensuring security PIN checks run before exposing data.
- **Dependencies**: Navigates to `PinLockScreen` or `DashboardScreen`.
- **🎓 Teaching Point**: Teach async initialization flow in splash screens.

---

#### 📄 `lib/screens/pin_lock_screen.dart` (Module 8 Target)
- **Exact Work Performed**: Secure numeric keypad UI supporting 4-digit PIN authentication using salted SHA-256 password hashing. Integrates hardware biometric authentication trigger via `local_auth`.
- **Technical Importance**: Primary physical security protection for financial records.
- **Dependencies**: Uses `crypto`, `local_auth`, `session_manager.dart`, `theme.dart`.
- **🎓 Teaching Point**:
  - Explain salted password hashing: `sha256(pin + salt)`.
  - Demonstrate hardware biometric integration using `local_auth`.

---

#### 📄 `lib/screens/dashboard/dashboard_screen.dart` (Module 7 Target)
- **Exact Work Performed**: Main app dashboard containing Net Balance overview cards, monthly budget velocity progress bars, quick action bar, and recent transactions feed.
- **Technical Importance**: Primary user view displaying financial health at a glance.
- **Dependencies**: Watches `AppProvider`, renders `AddTransactionSheet` and `CommonWidgets`.
- **🎓 Teaching Point**: Teach building responsive dashboard layouts with cards and progress bars.

---

#### 📄 `lib/screens/transactions/add_transaction_sheet.dart` (Module 7 Target)
- **Exact Work Performed**: Modal bottom sheet for logging or editing Expenses and Incomes. Features segment buttons, dynamic category pill selectors, payment method pickers, date selector, and validation.
- **Technical Importance**: Main transaction data entry form.
- **Dependencies**: Modifies `AppProvider` state.
- **🎓 Teaching Point**: Show how switching between Expense/Income tabs auto-selects valid categories.

---

#### 📄 `lib/screens/analytics/analytics_screen.dart` (Module 7 Target)
- **Exact Work Performed**: Visual financial intelligence view displaying category ratio pie charts (`fl_chart`), spending speed gauges, category breakdowns, and date range filters.
- **Technical Importance**: Visual breakdown helping users identify spending patterns.
- **Dependencies**: Uses `fl_chart`, watches `AppProvider`.
- **🎓 Teaching Point**: Teach connecting third-party chart libraries (`fl_chart`) to state streams.

---

#### 📄 `lib/screens/categories/categories_screen.dart` (Module 7 Target)
- **Exact Work Performed**: Category manager screen displaying default and custom expense/income categories, icon pickers, and category creation dialogs.
- **Technical Importance**: Allows user category customization.
- **Dependencies**: Interacts with `AppProvider`.
- **🎓 Teaching Point**: Teach managing dynamic lists with color and icon pickers.

---

#### 📄 `lib/screens/goals/goals_screen.dart` (Module 7 Target)
- **Exact Work Performed**: Savings goals manager displaying progress bars, deposit bottom sheets, deadline badges, and completion progress metrics.
- **Technical Importance**: Enables users to set and track long-term savings targets.
- **Dependencies**: Interacts with `AppProvider`.
- **🎓 Teaching Point**: Teach progress calculation algorithms (`saved / target * 100`).

---

#### 📄 `lib/screens/recurring/recurring_screen.dart` (Module 7 Target)
- **Exact Work Performed**: Subscription and recurring bill manager allowing users to track, pause, resume, edit, or execute due recurring transactions.
- **Technical Importance**: Automates fixed periodic expenses.
- **Dependencies**: Interacts with `AppProvider` recurring engine.
- **🎓 Teaching Point**: Teach automated background payment scheduling.

---

#### 📄 `lib/screens/settings/settings_screen.dart` (Module 7 Target)
- **Exact Work Performed**: Control panel for configuring PIN security, biometric toggle, theme mode (Dark/Light/Auto), currency symbol, PDF statement export, database backup/restore, and owner info (**Krishna Sarathe**).
- **Technical Importance**: Central configuration screen for security, theme, and data export.
- **Dependencies**: Uses `pdf_export.dart`, `shared_preferences`, `AppProvider`.
- **🎓 Teaching Point**: Teach setting up user preference persistence with `shared_preferences`.

---

## 2.6 Services Layer (`lib/services/`)

#### 📄 `lib/services/firebase_service.dart` (Module 9 Target)
- **Exact Work Performed**: Connects to Firebase Core and Firestore project `money-46719`. Listens to real-time remote telemetry under `global_settings/lock_state` to enable remote device lockdown by **Krishna Sarathe**.
- **Technical Importance**: Emergency remote security service protecting stolen devices.
- **Dependencies**: Imports `cloud_firestore`, `firebase_core`.
- **🎓 Teaching Point**: Teach Firestore real-time snapshot streams (`snapshots()`).

---

#### 📄 `lib/services/notification_service.dart` (Module 9 Target)
- **Exact Work Performed**: Configures local device notifications via `flutter_local_notifications` for recurring bill reminders and spending limit warnings.
- **Technical Importance**: Keeps users informed about upcoming bills and budget thresholds.
- **Dependencies**: Imports `flutter_local_notifications`.
- **🎓 Teaching Point**: Teach native device local notification triggers.

---

#### 📄 `lib/services/session_manager.dart` (Module 8 Target)
- **Exact Work Performed**: Generates and persists unique device hardware signatures (`kDeviceId`) and maintains user session security tokens.
- **Technical Importance**: Identifies physical devices for multi-user database partitioning.
- **Dependencies**: Imports `uuid`, `shared_preferences`.
- **🎓 Teaching Point**: Teach UUID hardware signature generation.

---

## 2.7 Utilities & Design Theme (`lib/utils/`)

#### 📄 `lib/utils/constants.dart` (Module 1 Target)
- **Exact Work Performed**: Stores global application constants, owner metadata (**Krishna Sarathe**, `thekrishnasarathe000@gmail.com`), default category lists, category icon mappings, and preference keys.
- **Technical Importance**: Centralized configuration store preventing hardcoded strings across codebase.
- **Dependencies**: Referenced across all layers.
- **🎓 Teaching Point**: Teach maintaining clean constant registries in large apps.

---

#### 📄 `lib/utils/theme.dart` (Module 6 Target)
- **Exact Work Performed**: Defines Material 3 dark glassmorphic theme tokens, obsidian card surfaces (`#1E222A`), emerald green highlights (`#1B8A5A`), crimson red accents (`#E53935`), typography, and input decorations.
- **Technical Importance**: Ensures consistent visual presentation and branding across all screens.
- **Dependencies**: Used by all UI widgets and screens.
- **🎓 Teaching Point**: Teach creating custom `ThemeData` tokens in Flutter.

---

#### 📄 `lib/utils/pdf_export.dart` (Module 9 Target)
- **Exact Work Performed**: Vector PDF statement generator engine that compiles transaction records into formal print-ready PDF document reports using `pdf` and `printing`.
- **Technical Importance**: Enables users to generate formal account statements for accounting or printing.
- **Dependencies**: Imports `pdf`, `printing`, `intl`, `expense.dart`, `income.dart`.
- **🎓 Teaching Point**: Teach vector PDF layout construction in Flutter.

---

## 2.8 Reusable UI Components (`lib/widgets/`)

#### 📄 `lib/widgets/common_widgets.dart` (Module 6 Target)
- **Exact Work Performed**: Contains shared UI widgets: custom action buttons, glassmorphic container cards, summary chips, loading spinners, and empty-state placeholders.
- **Technical Importance**: Reduces code duplication across UI screen implementations.
- **Dependencies**: Used across all screens.
- **🎓 Teaching Point**: Teach Atomic Design principles in UI component construction.

---

## 2.9 Core Entrypoints

#### 📄 `lib/main.dart` (Module 1 Target)
- **Exact Work Performed**: Application entry point. Initializes Flutter binding, initializes Firebase, configures `MultiProvider`, and runs `MyMoneyApp`.
- **Technical Importance**: CRITICAL. The entry point executed when app launches.
- **Dependencies**: Initializes `AppProvider`, `FirebaseService`, `SplashScreen`.
- **🎓 Teaching Point**: Teach `MultiProvider` dependency injection at root app level.

---

#### 📄 `lib/firebase_options.dart` (Module 9 Target)
- **Exact Work Performed**: Firebase configuration options containing API keys, App IDs, and project identifiers (`money-46719`) for Android, Web, and macOS targets.
- **Technical Importance**: Connects app to Firebase cloud infrastructure.
- **Dependencies**: Used by `main.dart` and `firebase_service.dart`.
- **🎓 Teaching Point**: Teach multi-platform cloud configuration setup.

---

# 3. Native Platform Configurations

## 3.1 Android Native Specs (`android/`) (Module 10 Target)

### 📄 `android/app/build.gradle.kts`
- **Exact Work Performed**: Android application build script. Defines `namespace = "com.krishnasarathe.mymoney"`, `applicationId = "com.krishnasarathe.mymoney"`, target SDK 35, Java 17 compatibility, and desugaring dependencies.
- **Technical Importance**: Governs native Android build compilation and package identification.
- **🎓 Teaching Point**: Teach Gradle build configuration and SDK versioning.

---

### 📄 `android/app/src/main/AndroidManifest.xml`
- **Exact Work Performed**: Android system manifest. Defines app icon label `android:label="MONEY"`, launcher icon, exact alarm permissions, storage permissions, and `MainActivity` declaration.
- **Technical Importance**: Required by Android OS to declare app permissions and launcher entry.
- **🎓 Teaching Point**: Teach Android permissions and manifest declarations.

---

### 📄 `android/app/src/main/kotlin/com/krishnasarathe/mymoney/MainActivity.kt`
- **Exact Work Performed**: Native Kotlin Android Activity inheriting from `FlutterActivity`.
- **Technical Importance**: Native Android entrypoint hosting Flutter engine view.
- **🎓 Teaching Point**: Teach Kotlin FlutterActivity integration.

---

### 📄 `android/app/google-services.json`
- **Exact Work Performed**: Firebase Android credentials matching package `com.krishnasarathe.mymoney`.
- **Technical Importance**: Required for Firebase services on Android.
- **🎓 Teaching Point**: Teach Google Services integration on Android.

---

## 3.2 Web Platform Specs (`web/`) (Module 10 Target)

### 📄 `web/index.html`
- **Exact Work Performed**: HTML5 web app entrypoint setting page title `My-Money - Personal Finance Manager` and loading Flutter Web bootstrap script.
- **Technical Importance**: Web browser host document.
- **🎓 Teaching Point**: Teach Flutter Web HTML host configuration.

---

### 📄 `web/manifest.json`
- **Exact Work Performed**: Progressive Web App (PWA) manifest setting app name `MONEY`, theme color `#1B8A5A`, and icon shortcuts.
- **Technical Importance**: Enables browser PWA installation on desktop and mobile web.
- **🎓 Teaching Point**: Teach Progressive Web App (PWA) configuration.

---

## 3.3 Windows Desktop C++ Specs (`windows/`) (Module 10 Target)

### 📄 `windows/runner/main.cpp`
- **Exact Work Performed**: Win32 C++ application entrypoint initializing COM, creating main window `My-Money` (1280x720), and handling Windows message loops.
- **Technical Importance**: Desktop executable host for Windows OS.
- **🎓 Teaching Point**: Teach Win32 C++ application host wrappers.

---

### 📄 `windows/runner/Runner.rc`
- **Exact Work Performed**: Windows resource file containing executable metadata (`My-Money.exe`, **Krishna Sarathe**, Copyright 2026).
- **Technical Importance**: Defines file properties visible in Windows File Explorer.
- **🎓 Teaching Point**: Teach Windows resource metadata configuration.

---

### 📄 `windows/CMakeLists.txt`
- **Exact Work Performed**: CMake build configuration defining project `My-Money` and executable binary name `My-Money`.
- **Technical Importance**: Compiles native C++ wrapper for Windows binary.
- **🎓 Teaching Point**: Teach CMake build configurations for desktop apps.

---

# 4. Test Suite & Dependencies

### 📄 `test/widget_test.dart`
- **Exact Work Performed**: Basic Flutter widget test importing `package:my_money/main.dart` and verifying `MyMoneyApp` component mounting.
- **Technical Importance**: Sanity check for build automation.
- **🎓 Teaching Point**: Teach automated Flutter widget testing principles.

---

### 📄 `pubspec.yaml`
- **Exact Work Performed**: Project manifest declaring package `my_money`, version `1.0.0+1`, Flutter SDK constraints, and dependencies (`provider`, `sqflite`, `fl_chart`, `local_auth`, `cloud_firestore`, `pdf`, `printing`).
- **Technical Importance**: Central dependency registry governing third-party libraries and assets.
- **🎓 Teaching Point**: Teach Dart package management and version constraints.

---

# 5. Production Build Outputs

### 📄 `releases/MONEY-v1.0-release.apk`
- **Exact Work Performed**: Standalone production Android APK executable (**29.1 MB**, SHA-256: `D83DF7E7285B5FC4AC0DD99895E221841C8A5808DFBE32B58BDA160E59382A8C`).
- **Technical Importance**: Production installer binary for Android mobile devices.

---

### 📄 `releases/MONEY-v1.0-release.aab`
- **Exact Work Performed**: Android App Bundle (**28.8 MB**, SHA-256: `C292D07EB18A5E78C6CE0326E3961A2AB83F484183F3F1B25A0D4BD6C66FE542`).
- **Technical Importance**: Production deployment archive for Google Play Store publishing.

---

## 📄 Educator Copyright & Attribution

Designed, architected, and created by **Krishna Sarathe**.

```text
Copyright © 2026 Krishna Sarathe. All rights reserved.

This master handbook and associated codebase files are proprietary intellectual property.
Released for educational instruction, mentoring, and academic course use.
```
