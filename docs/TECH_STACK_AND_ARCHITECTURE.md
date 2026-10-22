# MONEY — Complete Tech Stack & System Architecture

## Section 1: Application Overview

**MONEY** is an ultra-premium, AI-powered personal finance management ecosystem engineered for young earners, salaried professionals, students, and freelancers. It bridges the gap between conventional offline expense tracking and intelligent, proactive financial coaching.

The application operates with an **offline-first, privacy-respecting core** powered by a local SQLite database, augmented by a secure, decoupled **AI Financial Coach and Budget Planner** powered by Google Gemini and Groq LLMs.

### Principal User Journeys:
1. **Holistic Private-Banking Financial Overview**: Users monitor real-time monthly cash flow, total wealth accumulation, spending breakdown, and day-to-day burn rate on a luxury-themed dashboard.
2. **Deterministic Transaction & Ledger Management**: Multi-asset tracking across cash, UPI, bank accounts, and credit cards with automated debit/credit balancing.
3. **AI Financial Coaching & Portfolio Audits**: Conversational financial advisory that computes analytical context locally before querying Gemini/Groq, preventing model hallucinations.
4. **AI-Powered Monthly Budget Planning**: Automated zero-based budgeting that distributes net monthly income across essential expenses, lifestyle spending, debt servicing, and emergency savings.
5. **Fail-Safe Security & Device Protection**: Local 4-digit PIN secured with per-device salted SHA-256 in hardware-backed storage (`FlutterSecureStorage`), coupled with cloud-managed remote kill-switch telemetry.

---

## Section 2: Complete Technology Stack

| Layer | Technology | Purpose | Where It Is Used in Codebase |
| :--- | :--- | :--- | :--- |
| **Frontend Framework** | **Flutter 3.24.5** (Dart 3.5.4) | Cross-platform UI toolkit targeting Android and Web | `My-Money/lib/main.dart`, `My-Money/pubspec.yaml` |
| **Design System** | **Official Luxury Theme (Vanilla Flutter)** | Jet Black (`#000000`), Champagne Gold (`#D4AF37`), Emerald (`#0F6B4F`), Deep Crimson (`#8B0000`) | `My-Money/lib/utils/theme.dart`, `My-Money/lib/screens/dashboard_screen.dart` |
| **State Management** | **Provider (`provider: ^6.1.1`)** | Reactive change notification, memoized caching, and dependency injection | `My-Money/lib/providers/app_provider.dart` |
| **Local Persistence** | **SQLite (`sqflite: ^2.3.2`, `sqflite_common_ffi: ^2.3.4`)** | Relational data storage with schema migrations (v1 → v5) | `My-Money/lib/database/db_helper.dart`, `My-Money/lib/repositories/financial_repository.dart` |
| **Hardware Secure Storage** | **`flutter_secure_storage: ^9.2.4`** | Hardware-backed keystore/keychain storage (`EncryptedSharedPreferences` on Android) | `My-Money/lib/utils/secure_store.dart` |
| **Local Preferences** | **`shared_preferences: ^2.2.2`** | UI preferences, theme mode, device IDs, and offline cache flags | `My-Money/lib/providers/app_provider.dart`, `My-Money/lib/services/firebase_service.dart` |
| **Cryptography** | **`crypto: ^3.0.3`** | Per-device 32-byte salt generation and SHA-256 PIN hashing | `My-Money/lib/utils/security_utils.dart` |
| **Biometric Authentication** | **`local_auth: ^2.1.8`** | Fingerprint and face unlock hardware checks | `My-Money/lib/screens/pin_screen.dart` |
| **Cloud Device Control** | **Firebase Core, Auth, Firestore (`4.15.9`)** | Device telemetry and owner remote lock enforcement without user authentication barriers | `My-Money/lib/services/firebase_service.dart` |
| **Visual Charts** | **`fl_chart: ^0.68.0`** | High-performance interactive pie charts, category breakdowns, and bar charts | `My-Money/lib/screens/analytics/analytics_screen.dart` |
| **Reporting & Export** | **`pdf: ^3.10.8`, `printing: ^5.13.1`, `csv: ^6.0.0`** | Print-ready PDF statement generation and CSV tabular ledger export | `My-Money/lib/screens/more/data_screen.dart` |
| **AI Backend Service** | **Python 3.10+ (Standard Library `http.server`)** | Production-ready, zero-dependency microservice proxying LLM requests | `server/server.py`, `server/llm_provider.py` |
| **AI LLM Providers** | **Google Gemini (`gemini-1.5-flash`) & Groq (`llama-3.3-70b-versatile`)** | Natural language conversational coaching and category recommendation | `server/llm_provider.py`, `server/.env` |
| **HTTP Client** | **`http: ^1.2.0`** | Asynchronous JSON REST client communicating with the AI service | `My-Money/lib/services/ai_coach_service.dart` |
| **Build & Distribution** | **Gradle Kotlin DSL (`8.0+`) & Webpack/Wasm** | Android APK / AAB compilation and optimized Flutter Web release build | `My-Money/android/app/build.gradle.kts`, `My-Money/web/` |

---

## Section 3: System Architecture

```mermaid
flowchart TD
    subgraph Client["MONEY Client (Flutter App)"]
        UI["Presentation Layer (Luxury Theme)\n- DashboardScreen\n- AiCoachScreen\n- AiBudgetPlannerScreen\n- 13 Navigation Hubs"]
        Provider["AppProvider (State Bus)\n- Memoized Analytical Caches\n- Reactive ChangeNotifiers\n- Selection State"]
        Repo["FinancialRepository\n- Data Access Layer\n- Multi-User Isolation ('default_user')\n- Transaction Rebalancing"]
        DB[("Local SQLite Database\n- v5 Migration Engine\n- Indexed Tables")]
        SecStore["SecureStore / SecurityUtils\n- Per-Device 32-Byte Salt\n- SHA-256 Encrypted Storage"]
        AICoachService["AiCoachService\n- REST Client\n- Deterministic Offline Fallback"]
    end

    subgraph Backend["AI Backend Microservice (Python)"]
        Server["server.py (ThreadingHTTPServer)\n- Rate Limiting & Max Payload (1MB)\n- CORS Preflight (OPTIONS)\n- Endpoint Routing"]
        LLM["LLMProvider (llm_provider.py)\n- API Key Quarantine\n- Gemini 1.5 Flash\n- Groq LLaMA 3.3 70B\n- Heuristic Emergency Rule Engine"]
    end

    subgraph CloudServices["External Cloud & AI Services"]
        GeminiAPI["Google Gemini REST API\ngenerativelanguage.googleapis.com"]
        GroqAPI["Groq Cloud REST API\napi.groq.com"]
        Firestore["Google Cloud Firestore\nRemote Lock & Telemetry"]
    end

    %% Client Interactions
    UI -->|User Events & Mutations| Provider
    Provider -->|Queries & Updates| Repo
    Repo -->|Direct SQL Execution| DB
    UI -.->|PIN Verification| SecStore
    Provider -->|Extracts Analytics| AICoachService

    %% AI Communication
    AICoachService -->|POST /api/ai/chat\nPOST /api/ai/budget-planner| Server
    Server --> LLM
    LLM -->|HTTPS JSON Request| GeminiAPI
    LLM -->|HTTPS JSON Request (Failover)| GroqAPI

    %% Fallback
    LLM -.->|If APIs Exhausted| LLM
    AICoachService -.->|If Backend Offline| Provider

    %% Remote Lock
    UI -.->|Device Status Check| Firestore
```

---

## Section 4: Application Startup Sequence

1. **Flutter Engine Initialization**: `WidgetsFlutterBinding.ensureInitialized()` starts native platform channel bindings.
2. **Theme Mode Resolution**: Reads cached `theme_mode` and `currency` symbol from `SharedPreferences`.
3. **Database Initialization & Migration**: `DbHelper.database` initializes `money.db` and sequentially runs migration scripts up to schema version 5.
4. **Cryptographic Credential Migration**: `SecureStore.initAndMigrate()` detects any legacy plaintext PINs, purges plaintext entries, generates an unpredictable per-device 32-byte salt, and saves it into hardware secure storage.
5. **Firebase Telemetry Check (Non-Blocking)**: Checks remote lock status in Firestore via `FirebaseService.checkDeviceStatusResult()`. If blocked, the app immediately transitions to `BlockedScreen`.
6. **Authentication Routing**:
   - If `pin_enabled == true`, user lands on `PinScreen`.
   - If PIN is disabled or successfully verified, user is directed to `HomeScreen` (loading `DashboardScreen` as destination 0).
7. **Hydration & Cache Warming**: `AppProvider.refresh()` triggers asynchronous parallel loading of expenses, incomes, debts, accounts, budgets, and memoized category breakdown caches.

---

## Section 5: Data Flow (From Input to UI)

```text
[ User Action: Enters ₹500 Coffee Expense in AddTransactionSheet ]
                           │
                           ▼
[ Form Validation: Amount > 0, Title not empty, Category selected ]
                           │
                           ▼
[ AppProvider.addExpense(Expense e) ]
                           │
                           ▼
[ FinancialRepository.insertExpense(Expense e) ]
                           │
                           ▼
[ SQLite INSERT into 'expenses' Table (user_id = 'default_user') ]
                           │
                           ▼
[ AppProvider: _invalidateCaches() ]
  ├── Nullifies _cachedTransactionsByDay
  ├── Nullifies _cachedCategoryBreakdown
  └── Nullifies _cachedSixMonthOverview
                           │
                           ▼
[ AppProvider: notifyListeners() ]
                           │
                           ▼
[ Reactive UI Re-render (Consumer<AppProvider>) ]
  ├── _BalanceCard: Calculates new Monthly Net Balance
  ├── _IncomeExpenseCards: Updates Deep Crimson expense total
  ├── _SecondaryIndicators: Recomputes Daily Avg burn rate
  └── _RecentSection: Re-groups transactions by day
```

---

## Section 6: Database Design (Schema v5)

The database schema (`money.db`) is managed by `DbHelper` and currently runs on **Schema Version 5**:

### 1. `expenses` Table
Stores all outgoing cash, bank, card, and digital transactions.
```sql
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL DEFAULT 'default_user',
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  payment_method TEXT DEFAULT "UPI",
  description TEXT DEFAULT "",
  tags TEXT DEFAULT "",
  date INTEGER NOT NULL,          -- Unix epoch milliseconds
  created_at INTEGER NOT NULL     -- Unix epoch milliseconds
);
CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_expenses_user ON expenses(user_id);
```

### 2. `incomes` Table
Stores all incoming revenue streams.
```sql
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
CREATE INDEX idx_incomes_date ON incomes(date);
```

### 3. `ai_budget_plans` Table (Added in v5)
Stores AI-generated monthly allocation plans.
```sql
CREATE TABLE ai_budget_plans (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL DEFAULT 'default_user',
  summary TEXT NOT NULL,
  monthly_income REAL NOT NULL,
  allocations_json TEXT NOT NULL,  -- JSON serialized list of category allocations
  total_essential REAL NOT NULL,
  total_lifestyle REAL NOT NULL,
  total_savings REAL NOT NULL,
  savings_percentage REAL NOT NULL,
  ai_explanation TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_ai_budget_plans_user ON ai_budget_plans(user_id);
```

### Supporting Tables:
- **`budgets`**: Category-specific monthly spending caps (`category`, `amount`, `month`, `year`).
- **`savings_goals`**: Goal tracking with target amounts, current saved balances, and target completion dates.
- **`debts`**: Borrower/lender obligations tracking partial payments and debt resolution statuses.
- **`recurring_expenses`**: Subscriptions automatically debited on due dates.
- **`accounts`**: Balances across Cash, Bank, UPI Wallets, and Credit Cards.
- **`categories`**: User-customizable expense and income category metadata with icon and color mapping.

---

## Section 7: Deterministic Financial Calculations

To guarantee financial precision and prevent AI hallucinations, all mathematical operations are calculated deterministically by Dart code:

1. **Monthly Net Balance**:
   $$\text{Net Balance} = \sum \text{Income}_{\text{Selected Month}} - \sum \text{Expenses}_{\text{Selected Month}}$$
2. **Total All-Time Net Wealth**:
   $$\text{Total Balance} = \sum \text{Income}_{\text{All-Time}} - \sum \text{Expenses}_{\text{All-Time}}$$
3. **Savings Rate**:
   $$\text{Savings Rate} = \begin{cases} \left( \frac{\text{Net Balance}}{\text{Total Income}} \right) \times 100 & \text{if Total Income} > 0 \\ 0.0 & \text{otherwise} \end{cases}$$
4. **Daily Average Burn Rate**:
   $$\text{Daily Average} = \frac{\text{Total Expenses This Month}}{\max(1, \text{Current Day of Month})}$$
5. **Budget Allocation Normalization**:
   $$\sum_{i=1}^{n} \text{Allocated Amount}_i = \text{Monthly Income}$$
   In feasible budget plans, the discretionary and goal savings are normalized to ensure the sum of allocations reconciles to the user's available income without rounding drift.

---

## Section 8: AI Integration Architecture

### Endpoint Specifications (`server/server.py`):

| Endpoint | Method | Input Parameters | Output Response |
| :--- | :--- | :--- | :--- |
| `/api/health` | `GET` | None | `{ "status": "ok", "provider": "gemini\|groq", "model": "..." }` |
| `/api/ai/chat` | `POST` | `{ "message": str, "context": dict, "history": list }` | `{ "reply": str, "provider": str, "model": str }` |
| `/api/ai/insights` | `POST` | `{ "context": dict }` | `{ "insights": str, "provider": str }` |
| `/api/ai/savings-recommendations`| `POST` | `{ "context": dict }` | `{ "recommendations": str, "provider": str }` |
| `/api/ai/categorize` | `POST` | `{ "name": str, "amount": float, "categories": list }` | `{ "category": str, "confidence": float }` |
| `/api/ai/budget-planner` | `POST` | `{ "name": str, "monthly_income": float, "fixed_expenses": dict, ... }` | Structured JSON containing verified allocations |

### Multi-Tiered Fail-Safe Hierarchy:
1. **Tier 1 (Google Gemini 1.5 Flash)**: Primary LLM delivering structured JSON allocations and high-speed financial advice.
2. **Tier 2 (Groq Cloud LLaMA 3.3 70B)**: Automatic fallback if Gemini encounters rate-limits (HTTP 429), quota exhaustion, or gateway timeouts.
3. **Tier 3 (Local Heuristic Engine)**: If both remote APIs are unavailable, the backend invokes a deterministic financial rule engine that computes valid allocations based on the classic 50/30/20 budget framework.
4. **Tier 4 (Client-Side Analytical Fallback)**: If the Python backend itself is completely offline, `FinancialContextBuilder` on the mobile device synthesizes analytical insights from local SQLite data so the user is never left with an empty screen.

---

## Section 9: Security Architecture

1. **Secret Quarantine**:
   - API keys for Google Gemini (`GEMINI_API_KEY`) and Groq (`GROQ_API_KEY`) are quarantined inside `server/.env`.
   - The Flutter mobile client never contains embedded API keys, preventing reverse-engineering leaks.
2. **PIN Security**:
   - PINs are hashed using cryptographic **Salted SHA-256** with per-device 32-byte random salts.
   - Credentials are stored exclusively in hardware-backed encrypted storage (`EncryptedSharedPreferences` on Android, `Keychain` on iOS). Plaintext storage is completely eliminated.
3. **Multi-User Isolation**:
   - All relational database tables enforce a `user_id` column (defaulting to `'default_user'`), isolating future multi-account or tenant operations.
4. **Remote Lock Telemetry**:
   - Uses Firebase Anonymous Authentication so devices receive a cryptographically signed UID without requiring user email or password entry.
   - Firestore security rules protect status endpoints so only the verified owner can trigger remote device lockouts.

---

## Section 10: Build and Deployment Outputs

### 1. Android Release Binary:
- **File**: `releases/MONEY-v2.0.0-release.apk`
- **Output Size**: `32,257,619 bytes` (30.76 MB)
- **SHA-256 Checksum**: `9BB5589AF04C053B9BCBD6625D09A383C662F853AADE23CC9AAE0BA4699E2AED`
- **Signing**: Debug/local release signing configured in Gradle.

### 2. Android App Bundle:
- **File**: `releases/MONEY-v2.0.0-release.aab`
- **Output Size**: `31,939,712 bytes` (30.46 MB)
- **SHA-256 Checksum**: `AB628D64AEEF3D20CC49B7CD9840D46D7C439B666FF0A78BC024AB97FA1A136B`

### 3. Web Production Distribution:
- **Directory**: `My-Money/build/web/`
- **Engine**: Flutter Web with CanvasKit/Wasm rendering.
- **Local Serve Command**: `python -m http.server 8080 --directory My-Money/build/web`

---

## Section 11: Limitations & Future Roadmap

- **Multi-Currency Dynamic Conversion**: Current financial values are denominated in Indian Rupees (`₹`); future milestones will incorporate live Forex conversion rates.
- **Direct Open-Banking / Account Aggregator Sync**: Current transactions are entered manually or imported via CSV; future work will interface with RBI-regulated Account Aggregators (AA).
- **On-Device SLM (Small Language Model)**: Future roadmap includes testing quantized on-device models (e.g., Gemma 2B via MediaPipe) for 100% offline edge inference.
