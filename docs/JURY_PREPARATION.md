# MONEY — Hackathon Jury Evaluation & Technical Defense

This document equips the team with concise, confident, and factually grounded responses to technical, architectural, product, AI, and security questions during hackathon jury evaluation.

---

## 1. Product & Value Proposition

### Q: What problem does MONEY solve?
> **Answer**: Most young earners, freelancers, and students struggle with financial anxiety not because they lack income, but because they lack clear visibility into discretionary burn and realistic allocation frameworks. Traditional expense trackers act as passive spreadsheets—they record spending after the damage is done. **MONEY** transforms passive tracking into an active, private-banking advisory experience by pairing real-time cash flow monitoring with intelligent, context-aware AI coaching and zero-based budget planning.

### Q: Who is the target audience?
> **Answer**: Young working professionals, salaried employees, college students, and gig workers who need a disciplined yet non-judgmental financial companion that operates with strict privacy (offline-first).

### Q: What is the main differentiator?
> **Answer**: 
> 1. **Ultra-Premium Aesthetics**: A private-banking luxury design (Jet Black, Champagne Gold, Emerald, Crimson) that makes financial review feel empowering rather than chore-like.
> 2. **Offline-First Privacy**: Financial transactions remain on the user's device in SQLite. They are never synchronized to commercial advertising databases.
> 3. **Deterministic Math + AI Advisory**: The AI explains verified figures rather than inventing calculations. Math is solved by deterministic algorithms; narrative guidance is delivered by the LLM.

---

## 2. Architecture & Engineering Decisions

### Q: How is the application structured?
> **Answer**: The application adheres to a clean, decoupled layered architecture:
> - **Presentation Layer**: Flutter widgets adhering to a centralized luxury theme (`lib/utils/theme.dart`).
> - **State Management**: Reactive, memoized caching with Provider (`AppProvider.dart`).
> - **Data Access Layer**: `FinancialRepository` abstracting direct SQLite queries.
> - **Persistence**: Relational SQLite database (`money.db`) with an automated migration engine (v1 through v5).
> - **Hardware Security**: `SecureStore` interfacing with Android `EncryptedSharedPreferences` / iOS Keychain.
> - **AI Integration**: A decoupled Python backend (`server/server.py`) isolating LLM credentials from the client.

### Q: Why Flutter over React Native or Native Android?
> **Answer**: Flutter's Skia/Impeller rendering pipeline provides pixel-perfect control required for high-contrast luxury UI typography, custom borders, and dynamic animations across mobile and web with a single codebase. It compiles directly to native ARM machine code on Android and CanvasKit/Wasm on Web.

### Q: How would the system scale to millions of users?
> **Answer**: Because data persistence is **client-side in SQLite**, client device scaling is $O(1)$ on infrastructure costs. For cloud features, the stateless Python AI microservice can be horizontally autoscaled behind an Nginx or AWS Application Load Balancer with Redis response caching for standard prompts.

---

## 3. Artificial Intelligence & LLM Strategy

### Q: Why did you select Google Gemini and Groq?
> **Answer**: 
> - **Google Gemini 1.5 Flash**: Chosen for its massive context window, exceptional JSON instruction following, low latency, and native understanding of structured financial parameters.
> - **Groq LLaMA 3.3 70B**: Selected as an ultra-fast hardware-accelerated failover. If Gemini experiences rate-limits or latency spikes, Groq steps in within sub-500ms to guarantee uninterrupted user conversations.

### Q: How do you prevent AI hallucinations in financial amounts?
> **Answer**: 
> **We never ask the LLM to do arithmetic.**
> 1. `FinancialContextBuilder` calculates all financial sums, monthly balances, category breakdowns, and savings rates deterministically in Dart.
> 2. The pre-calculated mathematical facts are supplied to the LLM in the system prompt.
> 3. The LLM is strictly instructed: *"Interpret and explain these pre-calculated facts; do not invent new amounts."*
> 4. In the Budget Planner, the proposed allocations are validated by Dart logic to ensure $\sum \text{Allocations} = \text{Income}$ before being presented to the user.

### Q: What happens if the AI provider or Internet is offline?
> **Answer**: The architecture has **four tiers of resilience**:
> 1. Primary remote LLM (Gemini 1.5 Flash).
> 2. Failover remote LLM (Groq LLaMA 3.3 70B).
> 3. Backend Heuristic Rule Engine (Local 50/30/20 algorithm in Python).
> 4. Client-side Analytical Fallback (`FinancialContextBuilder` in Dart synthesizes insights directly from SQLite if the server cannot be reached).

---

## 4. Security, Cryptography & Compliance

### Q: How are API keys protected?
> **Answer**: LLM API keys are **never bundled in the mobile APK or web bundle**. They reside strictly in server environment variables (`server/.env`). Reverse-engineering the client APK exposes zero third-party API secrets.

### Q: How is PIN security implemented?
> **Answer**: 
> 1. When a user creates a PIN, `SecurityUtils` generates a cryptographically secure 32-byte per-device random salt.
> 2. The PIN is hashed using **Salted SHA-256** ($\text{SHA-256}(\text{salt} + \text{pin})$).
> 3. The resulting hash and salt are stored in hardware-backed encrypted storage via `FlutterSecureStorage`.
> 4. Plaintext credentials are systematically purged on startup via `SecureStore.initAndMigrate()`.

### Q: What is the Firebase Remote Lock feature?
> **Answer**: A fail-safe device protection mechanism. If an owner misplaces their device or flags it compromised, a status flag in Cloud Firestore triggers an instant, unbypassable lockout screen (`BlockedScreen`). The client caches this status locally so the lockout persists even if the user disconnects the device from the internet.

---

## 5. Technical Deep Dive — Files to Open During Presentation

When judges ask to inspect the codebase, navigate to these key source files:

1. **Centralized Luxury Design System**:
   - [`My-Money/lib/utils/theme.dart`](file:///c:/Users/krish/Desktop/My-Money/My-Money/lib/utils/theme.dart) — Point to the exact official hex color tokens (`jetBlack`, `champagneGold`, `forestGreen`, `emeraldGreen`, `deepCrimson`).
2. **Luxury Dashboard Implementation**:
   - [`My-Money/lib/screens/dashboard_screen.dart`](file:///c:/Users/krish/Desktop/My-Money/My-Money/lib/screens/dashboard_screen.dart) — Show `_BalanceCard` dominant numerals, `_IncomeExpenseCards`, `_AiCoachPanel`, and the ornate empty-state.
3. **AI Monthly Budget Planner**:
   - [`My-Money/lib/screens/ai_budget/ai_budget_planner_screen.dart`](file:///c:/Users/krish/Desktop/My-Money/My-Money/lib/screens/ai_budget/ai_budget_planner_screen.dart) — Demonstrate dynamic shortfall detection and real-time category rebalancing.
4. **AI Backend Proxy & Failover**:
   - [`server/llm_provider.py`](file:///c:/Users/krish/Desktop/My-Money/server/llm_provider.py) — Show Gemini → Groq fallback logic and prompt engineering.
5. **Database Migration Engine**:
   - [`My-Money/lib/database/db_helper.dart`](file:///c:/Users/krish/Desktop/My-Money/My-Money/lib/database/db_helper.dart) — Show v1 through v5 schema migrations.
6. **Salted Hash Security Engine**:
   - [`My-Money/lib/utils/secure_store.dart`](file:///c:/Users/krish/Desktop/My-Money/My-Money/lib/utils/secure_store.dart) and [`My-Money/lib/utils/security_utils.dart`](file:///c:/Users/krish/Desktop/My-Money/My-Money/lib/utils/security_utils.dart).

---

## 6. Honest Claims & Current Limitations

- **What works 100%**:
  - Full transaction CRUD and balance tracking.
  - Multi-account portfolio management.
  - Category spending analytics and visual pie charts.
  - AI Financial Coach and AI Budget Planner with failover.
  - Salted SHA-256 PIN security and remote kill-switch.
  - Android APK/AAB release builds and production Web build.
- **What is on the future roadmap**:
  - Direct Account Aggregator (AA) banking APIs (currently uses manual input and CSV import).
  - Multi-currency live Forex conversion (currently Indian Rupee `₹`).
  - Native On-device quantized SLM inference (Gemma 2B).
