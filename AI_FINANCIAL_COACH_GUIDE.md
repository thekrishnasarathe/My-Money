# 🤖 MONEY — AI-Powered Personal Finance Coach

### *Smart FinTech Hackathon Implementation Blueprint & Operating Guide*

---

## 🌟 Overview

**MONEY** has been upgraded with a production-ready, security-first **AI Personal Finance Coach** powered by **Google Gemini** (default: `gemini-1.5-flash`) with dynamic failover support for **Groq** (`llama-3.3-70b-versatile`).

This integration strictly follows the **Non-Negotiable Directive**:
1. **Preserve Existing Codebase**: All existing screens (Dashboard, Transactions, Debts, Categories, Analytics, Goals, Budgets, Recurring, Settings), SQLite persistence, PIN authentication, and financial engines remain 100% intact.
2. **Calculation Integrity**: The LLM is **never** the source of truth for arithmetic. Exact totals, balances, category allocations, savings rates, and debt burdens are pre-calculated by `AppProvider` and injected into the prompt as verified ground truth.
3. **Server-Side API Security**: Private API keys (`GEMINI_API_KEY` or `GROQ_API_KEY`) are stored solely on the server in `.env`. The client communicates over a lightweight local REST API with origin CORS enforcement and request payload validation.
4. **Deterministic Fallbacks**: If the server is offline or keys are unconfigured, a deterministic rule-based analytical engine provides verified financial guidance, clearly badged as offline analysis.

---

## 🏗️ Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   Flutter Client (Mobile / Web / Desktop)              │
│                                                                        │
│   [ HomeScreen ] ─── [ AiCoachScreen (Chat / Insights / Strategist) ]  │
│   [ Dashboard  ] ─── [ Analytics AI Explainer ]                        │
│   [ Quick Categorizer Chip in AddTransactionSheet ]                   │
│                                │                                       │
│                                ▼                                       │
│            [ FinancialContextBuilder (Client-Side) ]                  │
│       Extracts verified numbers from AppProvider (SQLite)              │
│                                │                                       │
│                                ▼                                       │
│              [ AiCoachService (HTTP Client) ]                          │
└────────────────────────────────┬───────────────────────────────────────┘
                                 │ POST /api/ai/* (JSON payload)
                                 ▼
┌────────────────────────────────────────────────────────────────────────┐
│                Python AI Backend (`server/server.py`)                  │
│                                                                        │
│   - Multi-threaded HTTP Server with CORS & 1MB payload ceiling        │
│   - Environment Variable Loader (`.env`)                               │
│   - Google Gemini API (`google-generativeai`)                         │
│   - Groq API (`groq`)                                                 │
│   - Ground Truth Financial Prompt Formatter                            │
│   - Deterministic Rule-Based Fallback Engine                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 8 Target Capabilities Implemented

| # | Feature | Location in UI | Endpoint | Description |
|---|---------|----------------|----------|-------------|
| 1 | **Conversational Financial Q&A** | AI Coach > Chat Tab | `POST /api/ai/chat` | Natural language queries with verified financial context and suggested quick prompts. |
| 2 | **AI-Powered Financial Insights** | AI Coach > Spending Insights Tab | `POST /api/ai/insights` | Comprehensive spending health audit and actionable alerts. |
| 3 | **Context-Aware Analytics Explanations** | Analytics Screen > "Explain with AI" | `POST /api/ai/insights` | Directly explains current month category distribution and budget velocity. |
| 4 | **Personalized Spending Recommendations** | AI Coach > Savings Strategist Tab | `POST /api/ai/savings-recommendations` | Benchmarks spending against the 50/30/20 budget framework. |
| 5 | **Savings Goal Recommendations** | AI Coach > Savings Strategist Tab | `POST /api/ai/savings-recommendations` | Assesses goal deadlines, monthly target savings, and debt-to-savings ratio. |
| 6 | **Natural-Language Summaries** | AI Coach Quick Prompt Chip | `POST /api/ai/summary` | Instant executive narrative summarizing income, expenses, and cash flow. |
| 7 | **Spending Anomaly Explanations** | AI Coach > Spending Insights Tab | `POST /api/ai/insights` | Detects transactions exceeding 35% of total budget or sudden category spikes. |
| 8 | **AI Data Categorization Assistance** | Add Transaction Sheet | `POST /api/ai/categorize` | 'AI Auto-Detect' suggestion chip matching transaction name against verified schema. |

---

## ⚡ Quick Start Instructions

### Step 1: Configure Provider Credentials
Copy `server/.env.example` to `server/.env` and insert your API key:
```bash
cd server
copy .env.example .env
```
Edit `server/.env`:
```env
LLM_PROVIDER=gemini
GEMINI_API_KEY=AIzaSy...your_gemini_api_key...
GEMINI_MODEL=gemini-1.5-flash

# Or for Groq:
# LLM_PROVIDER=groq
# GROQ_API_KEY=gsk_...your_groq_api_key...
# GROQ_MODEL=llama-3.3-70b-versatile
```

### Step 2: Start the AI Backend
Run the root batch file:
```cmd
run_ai_backend.bat
```
*The server will start on `http://127.0.0.1:5005`.*

### Step 3: Run the Application
You can run the web or desktop version:
- **Web App**: Double click `Launch-MONEY-Laptop.bat` (serves the pre-compiled production web bundle on `http://localhost:8080`).
- **Flutter Dev**: Run `flutter run -d chrome` or `flutter run -d windows` from `My-Money/`.

---

## 🧪 Automated Test Verification

All unit, widget, and integration tests have been run and verified:

```cmd
cd My-Money
flutter test
```

### Test Suite Output:
- `test/ai_integration_test.dart`:
  - `AiCoachResponse parses successful Gemini response correctly` (PASSED)
  - `AiCoachResponse parses Groq responses and alternative keys` (PASSED)
  - `AiCoachResponse marks offline analytical fallback clearly` (PASSED)
  - `AiCoachResponse failure constructor creates valid error object` (PASSED)
  - `FinancialContextBuilder extracts structured metrics safely without crashing` (PASSED)
  - `AiCoachService base URL defaults to valid address` (PASSED)
- `test/remote_lock_cache_test.dart`:
  - `Scenario 1: Live check updates cache unconditionally` (PASSED)
  - `Scenario 2: Device blocked remotely while online, lands on BlockedScreen` (PASSED)
  - `Scenario 3: First launch ever (no cache) defaults to allowed` (PASSED)
- `test/widget_test.dart`:
  - `AiCoachScreen renders correctly with tabs and prompt chips` (PASSED)

**Result: 10/10 tests passed.**
**Web Release Compilation: `flutter build web --release` successfully completed.**
