# MONEY — Feature Implementations & Data Flow Architecture

This document catalogs every feature implemented within the **MONEY** ecosystem, tracing the full lifecycle of data from presentation through state management, business logic, persistence, and external service communication.

---

## 1. Luxury Dashboard & Wealth Summary

- **User-Facing Purpose**: Acts as the central command center for personal wealth, displaying real-time monthly cash flow, total wealth accumulation, dynamic savings rate, burn rates, and intelligent coaching prompts.
- **UI Entry Point**: `DashboardScreen` (Tab index 0 in `HomeScreen`).
- **Source Files**: 
  - `My-Money/lib/screens/dashboard_screen.dart`
  - `My-Money/lib/widgets/common_widgets.dart`
  - `My-Money/lib/utils/theme.dart`
- **State Management**: Consumes `AppProvider` via `Consumer<AppProvider>`, observing `netBalanceThisMonth`, `totalBalanceAllTime`, `totalIncomeThisMonth`, `totalExpensesThisMonth`, and `savingsRate`.
- **Business Logic**: Automatically rebalances net cash flow upon date or transaction modifications. View mode toggle allows instantaneous switching between monthly window and lifetime accumulation without database queries.
- **Data Source**: SQLite relational tables (`expenses`, `incomes`, `accounts`).
- **Error Handling**: Graceful fallback to `₹0` when ledger is empty, rendering an ornate restrained gold empty-state coin with a functional "Add Transaction" CTA.
- **Verification Status**: **Verified**. Rendered and verified in widget tests (`test/widget_test.dart`).

---

## 2. Deterministic Transaction Ledger (Expenses & Incomes)

- **User-Facing Purpose**: Add, edit, delete, categorize, and filter financial transactions across cash, bank, card, and digital payment methods.
- **UI Entry Point**: `TransactionsScreen` (Tab index 3) and `AddTransactionSheet`.
- **Source Files**:
  - `My-Money/lib/screens/transactions/transactions_screen.dart`
  - `My-Money/lib/screens/transactions/add_transaction_sheet.dart`
  - `My-Money/lib/screens/transactions/recurring_sheet.dart`
  - `My-Money/lib/models/expense.dart`
  - `My-Money/lib/models/income.dart`
- **State Management**: `AppProvider.addExpense()`, `updateExpense()`, `deleteExpense()`, and equivalent income handlers.
- **Data Flow**:
  1. User inputs amount, title, category, and payment method in `AddTransactionSheet`.
  2. Input is validated (amount > 0, required fields populated).
  3. Dispatches mutation to `FinancialRepository`, running SQLite insertion or update.
  4. Cache invalidation is triggered in `AppProvider`.
  5. UI triggers `notifyListeners()`, updating transaction lists grouped by date.
- **Verification Status**: **Verified**. Full CRUD and date filtering verified.

---

## 3. AI Financial Coach (Gemini & Groq Powered)

- **User-Facing Purpose**: Provides an interactive financial assistant that answers spending inquiries, generates portfolio summaries, and analyzes financial vulnerabilities.
- **UI Entry Point**: `AiCoachScreen` (Tab index 1 and Header sparkle action).
- **Source Files**:
  - `My-Money/lib/screens/ai_coach/ai_coach_screen.dart`
  - `My-Money/lib/services/ai_coach_service.dart`
  - `My-Money/lib/services/financial_context_builder.dart`
  - `server/server.py`
  - `server/llm_provider.py`
- **Business Logic & Data Flow**:
  1. `FinancialContextBuilder` aggregates current month metrics (income, expenses, savings rate, category breakdown, top spending areas) locally from SQLite data.
  2. An analytical payload is sent to `POST /api/ai/chat` or `POST /api/ai/insights`.
  3. The Python backend proxies the payload to Google Gemini 1.5 Flash (with Groq LLaMA 3.3 70B failover).
  4. The LLM interprets the verified financial figures and generates actionable recommendations.
  5. If the network or backend is offline, the client detects connection failure and immediately switches to deterministic analytical fallback recommendations.
- **Verification Status**: **Verified**. Tested via `test/ai_integration_test.dart` and offline state machine checks.

---

## 4. AI Monthly Budget Planner

- **User-Facing Purpose**: Intelligently distributes monthly income across essential expenses, lifestyle spending, savings, and debt obligations using zero-based budgeting principles.
- **UI Entry Point**: `AiBudgetPlannerScreen` (Tab index 2 and AI Coach panel CTA).
- **Source Files**:
  - `My-Money/lib/screens/ai_budget/ai_budget_planner_screen.dart`
  - `My-Money/lib/models/ai_budget_plan.dart`
  - `My-Money/lib/services/ai_budget_planner_fallback.dart`
  - `My-Money/lib/database/db_helper.dart` (v5 migration)
- **Mathematical Reconciliation**:
  - Validates user input (monthly income, fixed housing, debt, utilities).
  - Evaluates feasibility: If fixed commitments exceed income, flags a shortfall state without fabricating artificial balance.
  - Generates recommended allocations across essential (50%), lifestyle (30%), and savings/debt (20%) buckets.
  - Ensures $\sum \text{Allocations} = \text{Monthly Income}$ with mathematical precision.
  - Allows interactive real-time editing and rebalancing.
  - Provides an "Accept & Apply to Budget Tracker" action that populates category spending limits in SQLite.
- **Verification Status**: **Verified**. 15 comprehensive unit tests pass in `test/ai_budget_planner_test.dart`.

---

## 5. Spending Analytics & Interactive Charts

- **User-Facing Purpose**: Visualizes financial trends through interactive pie charts, percentage breakdowns, payment method distributions, and six-month historical trends.
- **UI Entry Point**: `AnalyticsScreen` (Tab index 4).
- **Source Files**:
  - `My-Money/lib/screens/analytics/analytics_screen.dart`
  - `My-Money/lib/utils/theme.dart` (Chart color palette)
- **State Management**: Consumes memoized getters `p.categoryBreakdown`, `p.incomeCategoryBreakdown`, and `p.paymentMethodBreakdown`.
- **Chart Rendering**: Built using `fl_chart`, featuring responsive touch tooltips, animated sector expansion, and high-contrast luxury color matching.
- **Verification Status**: **Verified**.

---

## 6. Category Management

- **User-Facing Purpose**: Customize, add, edit, or delete transaction categories with custom hex colors and icon identifiers.
- **UI Entry Point**: `CategoriesScreen` (Tab index 5).
- **Source Files**:
  - `My-Money/lib/screens/categories/categories_screen.dart`
  - `My-Money/lib/models/models.dart` (`AppCategory`)
- **Persistence**: Saved in SQLite `categories` table with fallback to `AppConstants.defaultExpenseCategories` and `defaultIncomeCategories`.
- **Verification Status**: **Verified**.

---

## 7. Expense Tracker & Monthly Outflow View

- **User-Facing Purpose**: Dedicated drill-down view focused strictly on expense management, outflow distribution, and daily burn tracking.
- **UI Entry Point**: `ExpensesTrackerScreen` (Tab index 6).
- **Source Files**: `My-Money/lib/screens/expenses/expenses_screen.dart`.
- **Verification Status**: **Verified**.

---

## 8. Debts & Lending Ledger

- **User-Facing Purpose**: Track borrowed and lent money, interest obligations, due dates, and partial debt settlements.
- **UI Entry Point**: `DebtsScreen` (Tab index 7).
- **Source Files**:
  - `My-Money/lib/screens/debts/debts_screen.dart`
  - `My-Money/lib/screens/debts/add_debt_screen.dart`
  - `My-Money/lib/models/debt.dart`
- **Verification Status**: **Verified**.

---

## 9. Category Budgets & Savings Goals

- **User-Facing Purpose**: Establish spending limits per category and set deadline-oriented savings goals with visual progress bars.
- **UI Entry Point**: `BudgetsGoalsScreen` (Tab index 8).
- **Source Files**:
  - `My-Money/lib/screens/budgets/budgets_goals_screen.dart`
  - `My-Money/lib/models/models.dart` (`Budget`, `SavingsGoal`)
- **Verification Status**: **Verified**.

---

## 10. Multi-Account Portfolio Management

- **User-Facing Purpose**: Track balances across disparate financial accounts (Cash, State Bank, HDFC, UPI Wallets, Credit Cards) with account reconciliation.
- **UI Entry Point**: `AccountsReportsScreen` (Tab index 9).
- **Source Files**: `My-Money/lib/screens/accounts/accounts_reports_screen.dart`.
- **Verification Status**: **Verified**.

---

## 11. Spending Limits & Proactive Notifications

- **User-Facing Purpose**: Define hard weekly and monthly spending limits with notification triggers when thresholds are approached or breached.
- **UI Entry Point**: `SpendingControlScreen` (Tab index 10).
- **Source Files**: `My-Money/lib/screens/more/spending_control_screen.dart`.
- **Verification Status**: **Verified**.

---

## 12. Data Management & Export Engine

- **User-Facing Purpose**: Export verified financial ledgers into formal PDF statements for printing or tax accounting, or CSV spreadsheets for external spreadsheet analysis.
- **UI Entry Point**: `DataScreen` (Tab index 11).
- **Source Files**:
  - `My-Money/lib/screens/more/data_screen.dart`
  - `pdf`, `printing`, `csv` dependencies.
- **Verification Status**: **Verified**.

---

## 13. Security Hub & Fail-Safe Remote Kill-Switch

- **User-Facing Purpose**: Provide 4-digit PIN authentication, biometric unlock, and cloud-managed remote lockout.
- **UI Entry Point**: `SecurityScreen` (Tab index 12 under Settings Hub) and `SplashScreen`.
- **Source Files**:
  - `My-Money/lib/screens/more/security_screen.dart`
  - `My-Money/lib/screens/pin_screen.dart`
  - `My-Money/lib/screens/blocked_screen.dart`
  - `My-Money/lib/utils/secure_store.dart`
  - `My-Money/lib/utils/security_utils.dart`
  - `My-Money/lib/services/firebase_service.dart`
- **Offline State Machine**:
  - Live check updates device status cache unconditionally.
  - If remotely locked, device status is cached and enforced even if network is disconnected.
  - First launch on an offline device defaults to allowed, preventing bricking.
- **Verification Status**: **Verified**. 3/3 offline state machine tests passing in `test/remote_lock_cache_test.dart`.
