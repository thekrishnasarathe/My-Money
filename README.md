# MONEY - Personal Finance Ecosystem 💎
### *Complete 0% to 100% Product Creation & Technical Architecture Blueprint*

![Product Version](https://img.shields.io/badge/version-1.1.0%2B2--release-blue.svg)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)
![Ownership](https://img.shields.io/badge/owner-Krishna%20Sarathe-orange.svg)
![Security](https://img.shields.io/badge/security-Salted%20SHA--256%20%7C%20Anonymous%20Auth-red.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web%20%7C%20Windows-green.svg)

---

## 👨‍💻 Ownership & Creator Information

- **Product Name**: `MONEY` (App Launcher Icon Label) / `My-Money`
- **Product Owner & Lead Engineer**: **Krishna Sarathe**
- **Official Contact**: `thekrishnasarathe000@gmail.com`
- **Package Identifier**: `com.krishnasarathe.mymoney`
- **Current Version**: `1.1.0+2`
- **Copyright**: `© 2026 Krishna Sarathe. All rights reserved.`

---

# 🚀 Product Creation Roadmap (0% ➔ 100%)

This document chronicles the complete end-to-end engineering journey of **MONEY**, from initial concept to a production-grade, multi-platform personal finance management system.

```text
[ 0% ] Requirements & Core Data Architecture
   │
[ 20% ] Local Persistence Engine & SQLite Migration Schema (v4)
   │
[ 40% ] Reactive State Bus & Modern Dark Glassmorphic Design System
   │
[ 60% ] Transaction Engine, Total Balance Toggle & Savings Goal Trackers
   │
[ 80% ] Encrypted PIN Hashing (SecureStore), Biometrics & Anonymous Firebase Auth
   │
[ 100% ] PDF Statement Export, Fail-Safe Remote Lock & Multi-Platform Distribution
```

---

## 📐 Phase 1: Requirements & Core Data Models (0% ➔ 20%)

### 1. Functional Requirements (FR)
- **FR-01 Transaction Management**: Add, edit, delete, and list Expense and Income entries with custom amounts, dates, payment methods (Cash, UPI, Credit/Debit Cards, Net Banking), tags, and descriptions.
- **FR-02 Total & Monthly Balance**: Instant toggle between Monthly Net Balance and All-Time Total Balance across Dashboard and Transactions screens.
- **FR-03 Budget Tracking**: Set weekly and monthly spending thresholds with visual progress alerts and health status indicators.
- **FR-04 Savings Goals**: Track long-term financial targets with deadline countdowns, progress bars, and allocation logs.
- **FR-05 Automated Subscriptions**: Schedule recurring payments (Daily, Weekly, Monthly, Yearly) that automatically debit/credit upon due dates.
- **FR-06 Data Export & Statements**: Export formatted account ledgers and expense summaries into print-ready PDF files and CSV spreadsheets.

### 2. Non-Functional Requirements (NFR)
- **NFR-01 Performance**: Local SQLite database queries execute in `<10ms` for seamless 60fps/120fps UI scrolling. Startup non-blocking initialization ensures main screens render immediately without UI thread blocking.
- **NFR-02 Reliability (Offline-First)**: Complete standalone operation without requiring an active internet connection.
- **NFR-03 Security**: PIN storage protected via salted SHA-256 hashing with per-device 32-byte random salt, persisted via `flutter_secure_storage` (`EncryptedSharedPreferences` on Android / `Keychain` on iOS). Firebase Anonymous Authentication guarantees authenticated session state (`request.auth.uid`) for cloud remote lock telemetry without user login screens.

### 3. Core Model Definitions (`lib/models/`)
- **`Expense`**: Encapsulates `id`, `name`, `amount`, `category`, `paymentMethod`, `description`, `tags`, and `date`.
- **`Income`**: Tracks income source, amount, category, deposit method, and timestamps.
- **`AppCategory`**: Multi-type category metadata (`Expense` vs `Income`), custom hex colors, icon identifiers, and dynamic icon resolver fallback.
- **`SavingsGoal`**: Goal tracker with `targetAmount`, `savedAmount`, color coding, and deadline dates.
- **`RecurringExpense`**: Subscription & recurring bill definition supporting Daily, Weekly, Monthly, and Yearly schedules.
- **`Account`**: Wallet/Bank balance models supporting balance tracking and multi-account transfers.

---

## 💾 Phase 2: Database Schema & Migration Engine (20% ➔ 40%)

### 1. SQLite Database Design (`lib/database/db_helper.dart`)
Built from scratch using `sqflite` with dynamic versioning and performance composite indexes.

```sql
-- Transactions Tables
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL DEFAULT 'default_user',
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  payment_method TEXT DEFAULT "UPI",
  description TEXT DEFAULT "",
  tags TEXT DEFAULT "",
  date INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE TABLE incomes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL DEFAULT 'default_user',
  source TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  payment_method TEXT DEFAULT "Bank",
  description TEXT DEFAULT "",
  tags TEXT DEFAULT "",
  date INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

-- Categories & Subscriptions
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT DEFAULT 'default_user',
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  color TEXT DEFAULT "#1B8A5A",
  icon TEXT DEFAULT "category",
  is_default INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL
);

-- Composite Performance Indexes
CREATE INDEX idx_exp_user_date ON expenses(user_id, date);
CREATE INDEX idx_inc_user_date ON incomes(user_id, date);
```

### 2. Schema Migration & Auto-Seeding (v1 ➔ v4)
- **v1/v2**: Initial local tables and transaction columns.
- **v3**: Added structured category management, savings goals, and v2 recurring tables.
- **v4**: Multi-user data isolation via `user_id` partitioning across all 8 core tables with fallback default category auto-seeding.

---

## 🎨 Phase 3: UI Design System & State Management (40% ➔ 60%)

### 1. Modern Dark Glassmorphic Design System (`lib/utils/theme.dart`)
- **Theme Philosophy**: Sleek dark mode with vibrant emerald green (`#1B8A5A`), crimson red (`#E53935`), and obsidian card layers (`#1E222A` / `#252B36`).
- **Responsive Layout Engine**: All balance headers and segmented controls utilize `Expanded` constraints with text overflow protection (`TextOverflow.ellipsis`) for 100% responsive rendering across Android screen widths (360dp–450dp+) and high accessibility font scale settings.
- **Visual Balance Controls**: Segmented toggles feature distinct visual icon indicators:
  - **This Month / Monthly**: `Icons.calendar_month_outlined`
  - **Total Balance / All-Time**: `Icons.all_inclusive_rounded`

### 2. Reactive State Management (`lib/providers/app_provider.dart`)
- **`AppProvider`**: Single source of truth managing expenses, incomes, categories, recurring engine state, all-time vs monthly balances, category icon resolution, and security session locks.
- **Optimized Caching**: Invalidation caches prevent redundant database queries during frequent UI rebuilds.

---

## 🛡️ Phase 4: Security Design, Automation & Threat Model (60% ➔ 80%)

### 1. Security Architecture & Cryptographic Design
- **PIN Credential Security (`lib/utils/secure_store.dart`)**: User PINs are hashed using SHA-256 with a unique per-device random salt (32 bytes generated via `Random.secure()`). Hashes and salts are stored exclusively in hardware-backed secure storage via `flutter_secure_storage` (`EncryptedSharedPreferences` on Android, `Keychain` on iOS). A one-time migration flow detects legacy plaintext SharedPreferences PIN entries, purges them securely, and prompts the user via a "Security Update" dialog to establish fresh secure PIN credentials.
- **Biometric Authentication**: Hardware-level fingerprint / FaceID verification integrated via native OS authentication API (`local_auth`).
- **ADB Backup Disabled**: Android OS backup is strictly disabled (`android:allowBackup="false"` in `AndroidManifest.xml`) to prevent physical extraction of app data via ADB commands.

### 2. Anonymous Firebase Auth & Fail-Safe Remote Lock
- **Silent Anonymous Auth**: App startup automatically invokes `FirebaseAuth.instance.signInAnonymously()` to establish a valid `request.auth.uid` without any user login UI.
- **Server-Only Remote Lock Check**: `_performLiveCheck()` executes parallel queries using `GetOptions(source: Source.server)` to verify device block status against Firebase Firestore project `money-46719`.
- **Fail-Safe Offline Persistence**: If the device is offline or the server check times out (bounded by 3s auth and 6s check limits), `FirebaseService` catches the exception and falls back to `SharedPreferences` cached status (`kLastKnownBlocked`), ensuring a remotely locked device remains locked offline with an amber status banner.
- **`kDebugMode` Telemetry Guard**: All remote lock telemetry and auth debug logs are wrapped with `if (kDebugMode)` to maintain silent production release builds while preserving diagnostic tracing in debug builds.

### 3. Threat Model & Mitigation Strategy (OWASP Mobile)
| Threat Vector | Risk Level | Mitigation Strategy |
| :--- | :---: | :--- |
| **Data at Rest Theft** | Medium | Local database protected behind OS sandbox; PIN stored in `EncryptedSharedPreferences` as salted SHA-256 hash. |
| **ADB Backup Extraction** | High | `android:allowBackup="false"` enforced in AndroidManifest.xml. |
| **PIN Brute Force** | High | Multi-attempt exponential delay backoff + optional biometric lockout. |
| **Unauthorized Cloud Access** | High | Firestore security rules enforce strict authentication (`request.auth != null`) and ownership checks (`ownerUid == request.auth.uid`). |
| **Transport Interception** | Medium | All cloud synchronization enforced over TLS 1.3 encrypted HTTPS standard. |

### 4. Firestore Security Rules (`firestore.rules`)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User-isolated collection rules
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Remote device status telemetry rules
    match /money_devices/{deviceId} {
      // New docs: ownerUid must match authenticated user
      allow create: if request.auth != null
        && request.resource.data.ownerUid == request.auth.uid;
      // Read access: allow authenticated user if ownerUid matches or during transition backfill
      allow read: if request.auth != null
        && (!('ownerUid' in resource.data) || resource.data.get('ownerUid', '') == '' || resource.data.ownerUid == request.auth.uid);
      // Write access: restricted to matching ownerUid
      allow write: if request.auth != null
        && resource.data.get('ownerUid', null) == request.auth.uid;
      // Transition: allow backfill write on docs missing or empty ownerUid
      allow update: if request.auth != null
        && (!('ownerUid' in resource.data) || resource.data.get('ownerUid', '') == '')
        && request.resource.data.ownerUid == request.auth.uid;
    }

    // Global app settings (read-only for authenticated devices)
    match /money_app/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // app-side should never write global settings
    }
  }
}
```

### 5. Automated Recurring Engine & PDF Export Engine
- **Recurring Bills**: Evaluates due items on application launch and automatically posts periodic debits/credits.
- **PDF Statement Engine**: Vector-rendered formal financial ledger export built using `pdf` and `printing`.

---

## ☁️ Phase 5: Cloud Remote Telemetry & Build Distribution (80% ➔ 100%)

### 1. Backup, Recovery & Remote Telemetry
- **Local Data Backup**: Export/Import JSON database backups from Settings. (Planned — backup encryption via AES-256-GCM planned for v2.1.)
- **Remote Telemetry**: Telemetry state monitored via Firebase Firestore (`money-46719`).

### 2. Platform Support & Validation Status
- **Android (Validated)**: Fully tested on Android 12 through Android 15 (API 31–35) hardware.
- **Web App (Validated)**: Tested and running locally via HTTP server (`Launch-MONEY-Laptop.bat`) on Chrome/Edge.
- **Desktop (Targeted)**: Supported via standard Flutter C++ runner architecture.

---

## 📁 Repository Directory Structure

```text
My-Paisa/
├── My-Money/                           # Core Flutter Source Code
│   ├── android/                        # Android Native Kotlin & Gradle Setup
│   ├── ios/                            # iOS Platform Configuration
│   ├── lib/                            # Application Source Code
│   │   ├── database/                   # SQLite (SQFlite) Helper & Migration Schema (v4)
│   │   ├── models/                     # Data Schemas (Expense, Income, AppCategory, Account)
│   │   ├── providers/                  # Application State & Reactive Bus (AppProvider)
│   │   ├── repositories/               # Repository Abstraction Layer
│   │   ├── screens/                    # UI Screen Views & Modal Sheets
│   │   ├── services/                   # Firebase Remote Telemetry & Anonymous Auth Services
│   │   ├── utils/                      # Theme, SecureStore, SecurityUtils & PDF Engine
│   │   └── main.dart                   # Application Entrypoint
│   ├── web/                            # Web Platform Files & PWA Manifest
│   ├── windows/                        # Windows Native C++ Runner
│   ├── firestore.rules                 # Deployed Authenticated Firestore Security Rules
│   └── pubspec.yaml                    # Flutter Project Dependencies (v1.1.0+2)
├── releases/                           # Empirically Verified Production Binaries
│   ├── MONEY-v1.1.0-release.apk        # Production Release Android APK
│   └── MONEY-v1.1.0-release.aab        # Production Android App Bundle
├── Launch-MONEY-Laptop.bat             # 1-Click Laptop Web App Server Launcher
└── README.md                           # Technical Architecture Blueprint
```

---

## 🧪 Testing & CI/CD Strategy

### 1. Automated Testing Suite
- **Unit Tests**: Business logic and database repository functions (`test/widget_test.dart`).
- **Widget Tests**: UI screen layout, toggle state switches, and modal bottom sheet interactions.

### 2. Release Checklist
- [x] Execute `flutter test` to verify clean test execution.
- [x] Run `flutter analyze` to ensure 0 lints and 0 compilation warnings.
- [x] Verify multi-user isolation queries (`user_id = ? OR is_default = 1`).
- [x] Verify SecureStore hardware PIN migration and anonymous Firebase authentication.
- [x] Compile release targets (`apk`, `appbundle`).
- [x] Calculate and document empirical SHA-256 checksums.

---

## 🔒 Empirically Verified Build Checksums (v1.1.0+2)

*The following binary outputs were built, verified, and hashed locally on the build system:*

| Output Target | Binary Name | Size | Verified SHA-256 Checksum |
| :--- | :--- | :---: | :--- |
| **Android APK** | `MONEY-v1.1.0-release.apk` | **31.4 MB** | `4965EB13B354C1CB03874D9668B115D56A25AF91B65E27AD3FD6724B81BDE5C4` |
| **Android App Bundle** | `MONEY-v1.1.0-release.aab` | **31.1 MB** | `150300068C24E0070FEF627B4171ADD06AB912B2A04A8E97973FC1E864997E57` |

---

## 📄 License & Intellectual Property

Designed, engineered, and maintained by **Krishna Sarathe**.

```text
Copyright © 2026 Krishna Sarathe. All rights reserved.

This software product and its associated documentation files are proprietary.
Unauthorized copying, redistribution, or commercial exploitation is strictly prohibited.
```
