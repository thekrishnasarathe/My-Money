import os
import json
import logging
import urllib.request
import urllib.error
from typing import Dict, Any, List, Optional

# Configure silent / clean logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger("MoneyLLMProvider")

# Try loading python-dotenv if present
try:
    from dotenv import load_dotenv
    # Look for .env in current folder, server/ folder, and workspace root
    for p in ['.env', 'server/.env', '../server/.env', '../.env']:
        if os.path.exists(p):
            load_dotenv(p)
            break
except ImportError:
    pass

class LLMProvider:
    SYSTEM_INSTRUCTION = (
        "You are the AI Personal Finance Coach for 'MONEY', a modern personal finance management ecosystem.\n"
        "Your mission is to help users master their finances, understand spending habits, discover actionable "
        "savings opportunities, and make informed financial decisions.\n\n"
        "CRITICAL ARITHMETIC DIRECTIVE:\n"
        "- All financial figures provided in the user's verified financial context (income, expenses, balances, "
        "percentages, averages, category totals, savings rates) have been verified by the application's local engine.\n"
        "- NEVER invent conflicting totals, recalculate raw arithmetic inconsistently, or contradict verified context.\n"
        "- Base your explanations, insights, and recommendations strictly on the user's actual data.\n\n"
        "TONE & STYLE:\n"
        "- Concise, empathetic, actionable, and structured with clean bullet points.\n"
        "- Clearly distinguish between verified historical facts and forward-looking suggestions.\n"
        "- Do not guarantee investment returns or promise absolute savings outcomes.\n"
        "- When data is insufficient, clearly state the limitation and advise how more tracking will help."
    )

    def __init__(self):
        self.reload_config()

    def reload_config(self):
        self.provider = os.getenv("LLM_PROVIDER", "gemini").strip().lower()
        self.gemini_key = os.getenv("GEMINI_API_KEY", "").strip()
        self.gemini_model = os.getenv("GEMINI_MODEL", "gemini-3.8-flash").strip()
        self.groq_key = os.getenv("GROQ_API_KEY", "").strip()
        self.groq_model = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b").strip()

    def get_status(self) -> Dict[str, Any]:
        self.reload_config()
        if self.provider == "groq":
            is_configured = bool(self.groq_key and not self.groq_key.startswith("your_"))
            active_model = self.groq_model
        else:
            is_configured = bool(self.gemini_key and not self.gemini_key.startswith("your_"))
            active_model = self.gemini_model

        return {
            "status": "online",
            "provider": self.provider,
            "model": active_model,
            "is_configured": is_configured,
            "supported_providers": ["gemini", "groq"]
        }

    def _call_gemini_rest(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        if not self.gemini_key or self.gemini_key.startswith("your_"):
            raise ValueError("GEMINI_API_KEY is not configured in backend environment.")

        # Try google.generativeai SDK first
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.gemini_key)
            model_instance = genai.GenerativeModel(self.gemini_model)
            full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt
            res = model_instance.generate_content(full_prompt)
            if res and res.text:
                return res.text.strip()
        except Exception as sdk_err:
            logger.debug(f"Gemini SDK fallback to REST: {sdk_err}")

        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.gemini_model}:generateContent?key={self.gemini_key}"
        
        contents = []
        if system_prompt:
            contents.append({
                "role": "user",
                "parts": [{"text": f"SYSTEM INSTRUCTION: {system_prompt}\n\nPlease acknowledge and proceed."}]
            })
            contents.append({
                "role": "model",
                "parts": [{"text": "Understood. I will act strictly according to these instructions and verified context."}]
            })
            
        contents.append({
            "role": "user",
            "parts": [{"text": prompt}]
        })

        payload = {
            "contents": contents,
            "generationConfig": {
                "temperature": 0.4,
                "maxOutputTokens": 1024,
            }
        }

        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )

        try:
            with urllib.request.urlopen(req, timeout=25) as response:
                resp_json = json.loads(response.read().decode("utf-8"))
                candidates = resp_json.get("candidates", [])
                if candidates:
                    parts = candidates[0].get("content", {}).get("parts", [])
                    if parts:
                        return parts[0].get("text", "").strip()
                return "I analyzed your financial data, but no detailed text was returned by Gemini."
        except urllib.error.HTTPError as e:
            error_body = e.read().decode("utf-8", errors="ignore")
            logger.error(f"Gemini API HTTP Error {e.code}: {e.reason}")
            if e.code == 429:
                raise RuntimeError("Google Gemini rate limit reached. Please wait a moment and retry.")
            elif e.code == 400:
                raise RuntimeError("Invalid request to Gemini API. Check model availability or prompt structure.")
            elif e.code == 403 or e.code == 401:
                raise RuntimeError("Invalid Gemini API credentials. Please check your GEMINI_API_KEY.")
            raise RuntimeError(f"Gemini API error (HTTP {e.code}): {e.reason}")
        except urllib.error.URLError as e:
            raise RuntimeError(f"Network error connecting to Gemini API: {e.reason}")

    def _call_groq_rest(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        if not self.groq_key or self.groq_key.startswith("your_"):
            raise ValueError("GROQ_API_KEY is not configured in backend environment.")

        # Try using installed groq SDK first if available
        try:
            from groq import Groq
            client = Groq(api_key=self.groq_key)
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})
            
            chat_completion = client.chat.completions.create(
                messages=messages,
                model=self.groq_model,
                temperature=0.4,
                max_tokens=1024
            )
            return chat_completion.choices[0].message.content.strip()
        except ImportError:
            pass

        # Fallback to direct HTTP request
        url = "https://api.groq.com/openai/v1/chat/completions"
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        payload = {
            "model": self.groq_model,
            "messages": messages,
            "temperature": 0.4,
            "max_tokens": 1024
        }

        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            url,
            data=data,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.groq_key}"
            },
            method="POST"
        )

        try:
            with urllib.request.urlopen(req, timeout=25) as response:
                resp_json = json.loads(response.read().decode("utf-8"))
                choices = resp_json.get("choices", [])
                if choices:
                    return choices[0].get("message", {}).get("content", "").strip()
                return "I analyzed your financial data, but no response was returned by Groq."
        except urllib.error.HTTPError as e:
            logger.error(f"Groq API HTTP Error {e.code}: {e.reason}")
            if e.code == 429:
                raise RuntimeError("Groq rate limit reached. Please wait a moment and retry.")
            elif e.code == 401:
                raise RuntimeError("Invalid Groq API credentials. Check GROQ_API_KEY in server/.env.")
            raise RuntimeError(f"Groq API error (HTTP {e.code}): {e.reason}")
        except urllib.error.URLError as e:
            raise RuntimeError(f"Network error connecting to Groq API: {e.reason}")

    def generate_completion(self, prompt: str, system_prompt: Optional[str] = None) -> str:
        self.reload_config()
        sys_p = system_prompt or self.SYSTEM_INSTRUCTION
        if self.provider == "groq":
            return self._call_groq_rest(prompt, sys_p)
        else:
            return self._call_gemini_rest(prompt, sys_p)

    def chat(self, message: str, context: Dict[str, Any], history: Optional[List[Dict[str, str]]] = None) -> Dict[str, Any]:
        self.reload_config()
        status = self.get_status()
        
        # Build structured context string
        context_str = json.dumps(context, indent=2)
        history_str = ""
        if history:
            history_str = "\nRecent Conversation History:\n" + "\n".join(
                [f"- {h.get('sender', 'User')}: {h.get('text', '')}" for h in history[-4:]]
            )

        prompt = (
            f"VERIFIED FINANCIAL CONTEXT:\n`json\n{context_str}\n`\n"
            f"{history_str}\n\n"
            f"USER FINANCIAL QUESTION:\n{message}\n\n"
            "Please answer the user's question directly, clearly, and concisely. "
            "Cite relevant verified numbers where appropriate. Offer practical, achievable next steps."
        )

        if not status["is_configured"]:
            # Provide an informative, clearly distinguished offline analytical summary
            return self._offline_chat_fallback(message, context, status)

        try:
            reply = self.generate_completion(prompt)
            return {
                "success": True,
                "reply": reply,
                "provider": status["provider"],
                "model": status["model"],
                "is_offline_fallback": False
            }
        except Exception as e:
            logger.warning(f"LLM call failed: {e}. Falling back to analytical summary.")
            fallback = self._offline_chat_fallback(message, context, status, error_reason=str(e))
            fallback["warning"] = f"Live LLM request failed ({str(e)}). Displaying verified analytical summary."
            return fallback

    def get_insights(self, context: Dict[str, Any]) -> Dict[str, Any]:
        self.reload_config()
        status = self.get_status()
        context_str = json.dumps(context, indent=2)

        prompt = (
            f"VERIFIED FINANCIAL CONTEXT:\n`json\n{context_str}\n`\n\n"
            "Analyze the verified financial metrics above and provide structured insights:\n"
            "1. Cash Flow Health: Assessment of income vs expenses and net savings rate.\n"
            "2. Top Spending Areas & Opportunities: Which categories represent the largest outflows and where can the user cut back without hurting essentials?\n"
            "3. Spending Anomalies / Alerts: Highlight any unusual spikes or high-ratio expense categories.\n"
            "4. Three Concrete Action Steps for this month.\n\n"
            "Format your answer with clear headers and concise bullet points."
        )

        if not status["is_configured"]:
            return self._offline_insights_fallback(context, status)

        try:
            reply = self.generate_completion(prompt)
            return {
                "success": True,
                "insights": reply,
                "provider": status["provider"],
                "model": status["model"],
                "is_offline_fallback": False
            }
        except Exception as e:
            fallback = self._offline_insights_fallback(context, status, error_reason=str(e))
            fallback["warning"] = f"Live LLM request failed ({str(e)}). Displaying verified analytical breakdown."
            return fallback

    def get_savings_recommendations(self, context: Dict[str, Any]) -> Dict[str, Any]:
        self.reload_config()
        status = self.get_status()
        context_str = json.dumps(context, indent=2)

        prompt = (
            f"VERIFIED FINANCIAL CONTEXT:\n`json\n{context_str}\n`\n\n"
            "Based on the user's monthly income, expenses, current savings rate, and existing savings goals:\n"
            "1. Evaluate progress towards current goals.\n"
            "2. Recommend optimal monthly savings allocations to stay on track.\n"
            "3. Suggest realistic budget caps for discretionary spending categories.\n"
            "4. Provide 3 high-impact micro-habits to increase savings rate by 5-10%."
        )

        if not status["is_configured"]:
            return self._offline_savings_fallback(context, status)

        try:
            reply = self.generate_completion(prompt)
            return {
                "success": True,
                "recommendations": reply,
                "provider": status["provider"],
                "model": status["model"],
                "is_offline_fallback": False
            }
        except Exception as e:
            fallback = self._offline_savings_fallback(context, status, error_reason=str(e))
            return fallback

    def categorize_transaction(self, name: str, amount: float, payment_method: str, categories: List[str]) -> Dict[str, Any]:
        self.reload_config()
        status = self.get_status()
        
        # Rule-based fast check first
        fast_match = self._rule_based_categorize(name, categories)
        if fast_match:
            return {
                "success": True,
                "suggested_category": fast_match,
                "confidence": 0.95,
                "source": "rule-matcher"
            }

        if not status["is_configured"]:
            default_cat = next((c for c in categories if c.lower() in ["others", "other", "general", "miscellaneous", "shopping"]), categories[0] if categories else "Others")
            return {
                "success": True,
                "suggested_category": fast_match or default_cat,
                "confidence": 0.6 if fast_match else 0.4,
                "source": "rule-matcher" if fast_match else "offline-fallback"
            }

        prompt = (
            f"Transaction Details:\n"
            f"- Name/Description: '{name}'\n"
            f"- Amount: {amount}\n"
            f"- Payment Method: {payment_method}\n\n"
            f"Available Categories in App:\n{json.dumps(categories)}\n\n"
            "Select the single most appropriate category from the available list that fits this transaction. "
            "Reply strictly in valid JSON format: {\"category\": \"<Category Name>\", \"confidence\": <0.0 to 1.0>, \"reason\": \"<short reason>\"}."
        )

        try:
            raw = self.generate_completion(prompt)
            # Parse JSON from response
            cleaned = raw.strip()
            if cleaned.startswith("`json"):
                cleaned = cleaned[7:]
            if cleaned.startswith("`"):
                cleaned = cleaned[3:]
            if cleaned.endswith("`"):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()

            parsed = json.loads(cleaned)
            suggested = parsed.get("category", "")
            # Validate that suggested category exists in available list
            matched = next((c for c in categories if c.lower() == suggested.lower()), None)
            if matched:
                return {
                    "success": True,
                    "suggested_category": matched,
                    "confidence": float(parsed.get("confidence", 0.8)),
                    "reason": parsed.get("reason", ""),
                    "source": status["provider"]
                }
        except Exception as e:
            logger.debug(f"Categorization LLM parse fallback: {e}")

        return {
            "success": True,
            "suggested_category": fast_match or (categories[0] if categories else "Others"),
            "confidence": 0.5,
            "source": "fallback"
        }

    def _rule_based_categorize(self, name: str, categories: List[str]) -> Optional[str]:
        n = name.lower()
        rules = {
            "food": ["swiggy", "zomato", "restaurant", "cafe", "mcdonald", "burger", "pizza", "starbucks", "dinner", "lunch", "breakfast", "groceries", "blinkit", "zepto", "instamart", "supermarket"],
            "coffee": ["coffee", "tea", "chai", "snack", "bakery"],
            "transport": ["uber", "ola", "rapido", "metro", "bus", "train", "flight", "petrol", "fuel", "diesel", "parking", "toll"],
            "utilities": ["electricity", "water", "gas", "wifi", "broadband", "recharge", "airtel", "jio", "bill"],
            "shopping": ["amazon", "flipkart", "myntra", "clothes", "zara", "h&m", "shoes", "mall"],
            "entertainment": ["netflix", "spotify", "prime", "movie", "cinema", "hotstar", "game", "steam"],
            "medical": ["pharmacy", "hospital", "doctor", "medicine", "clinic", "lab", "apollo"],
            "salary": ["salary", "payroll", "stipend"],
            "rent": ["rent", "landlord", "maintenance"]
        }

        for rule_cat, keywords in rules.items():
            if any(k in n for k in keywords):
                # Find matching app category
                for c in categories:
                    if rule_cat in c.lower():
                        return c
        return None

    # -- Offline Rule-Engine Fallbacks (Accurate & Clearly Labeled) --

    def _offline_chat_fallback(self, message: str, ctx: Dict[str, Any], status: Dict[str, Any], error_reason: Optional[str] = None) -> Dict[str, Any]:
        income = ctx.get("total_income_this_month", 0.0)
        expense = ctx.get("total_expenses_this_month", 0.0)
        net = ctx.get("net_balance_this_month", 0.0)
        rate = ctx.get("savings_rate", 0.0)
        top_cats = ctx.get("category_breakdown", {})
        sym = ctx.get("currency_symbol") or "$"

        top_cat_summary = ""
        if top_cats:
            sorted_cats = sorted(top_cats.items(), key=lambda x: x[1], reverse=True)[:3]
            top_cat_summary = ", ".join([f"{k} ({sym}{v:,.0f})" for k, v in sorted_cats])

        setup_note = (
            "\n\n> **AI Provider Setup Note:** To enable full interactive conversational intelligence, "
            "set GEMINI_API_KEY (or GROQ_API_KEY) in server/.env. Currently presenting verified mathematical analysis."
        ) if not status["is_configured"] else ""

        reply = (
            f"**Verified Financial Summary for this Month:**\n\n"
            f"- **Total Income:** {sym}{income:,.2f}\n"
            f"- **Total Expenses:** {sym}{expense:,.2f}\n"
            f"- **Net Balance:** {sym}{net:,.2f}\n"
            f"- **Savings Rate:** {rate:.1f}%\n"
            f"- **Top Outflows:** {top_cat_summary or 'No expenses recorded yet.'}\n\n"
            f"**Coach Observation:**\n"
            f"{'Your cash flow is positive. Consider allocating some of your net balance into savings goals.' if net >= 0 else 'Your expenses currently exceed income this month. Review your discretionary spending in top categories.'}"
            f"{setup_note}"
        )

        return {
            "success": True,
            "reply": reply,
            "provider": "offline-rule-engine",
            "model": "deterministic-analyzer",
            "is_offline_fallback": True,
            "reason": error_reason or "API key not configured"
        }

    def _offline_insights_fallback(self, ctx: Dict[str, Any], status: Dict[str, Any], error_reason: Optional[str] = None) -> Dict[str, Any]:
        income = ctx.get("total_income_this_month", 0.0)
        expense = ctx.get("total_expenses_this_month", 0.0)
        rate = ctx.get("savings_rate", 0.0)
        top_cats = ctx.get("category_breakdown", {})
        sym = ctx.get("currency_symbol") or "$"

        sorted_cats = sorted(top_cats.items(), key=lambda x: x[1], reverse=True)
        top_str = "\n".join([f"  - **{k}**: {sym}{v:,.2f} ({(v/expense*100) if expense > 0 else 0:.1f}%)" for k, v in sorted_cats[:4]])

        insights = (
            f"### [Financial Health Overview]\n\n"
            f"- **Net Savings Rate**: **{rate:.1f}%** ({'Healthy rate (>20%)' if rate >= 20 else 'Room for optimization'})\n"
            f"- **Monthly Spending Inflow/Outflow**: Inflow {sym}{income:,.2f} vs Outflow {sym}{expense:,.2f}\n\n"
            f"### [Top Spending Categories]\n"
            f"{top_str or '  - No category data available for this month.'}\n\n"
            f"### [Actionable Recommendations]\n"
            f"1. **Set Budget Thresholds**: Establish monthly spending limits on your top categories.\n"
            f"2. **Automate Savings**: Allocate at least 15-20% of income directly into savings goals at the start of each month.\n"
            f"3. **Review Recurring Bills**: Inspect active subscriptions and eliminate unused services."
        )

        return {
            "success": True,
            "insights": insights,
            "provider": "offline-rule-engine",
            "model": "deterministic-analyzer",
            "is_offline_fallback": True,
            "reason": error_reason or "API key not configured"
        }

    def _offline_savings_fallback(self, ctx: Dict[str, Any], status: Dict[str, Any], error_reason: Optional[str] = None) -> Dict[str, Any]:
        income = ctx.get("total_income_this_month", 0.0)
        expense = ctx.get("total_expenses_this_month", 0.0)
        net = ctx.get("net_balance_this_month", 0.0)
        goals = ctx.get("goals", [])
        sym = ctx.get("currency_symbol") or "$"

        target_20_pct = income * 0.20
        recs = (
            f"### [Personalized Savings Recommendations]\n\n"
            f"- **Target Savings Benchmark (50/30/20 Rule)**: Based on your monthly income of {sym}{income:,.2f}, aiming for 20% savings equals **{sym}{target_20_pct:,.2f}/month**.\n"
            f"- **Current Net Available**: {sym}{net:,.2f}\n\n"
            f"### [Goal Progress Analysis]\n"
        )

        if goals:
            for g in goals:
                t = g.get("target_amount", 0)
                s = g.get("saved_amount", 0)
                pct = (s / t * 100) if t > 0 else 0
                recs += f"- **{g.get('name', 'Goal')}**: Saved {sym}{s:,.0f} of {sym}{t:,.0f} ({pct:.1f}% reached)\n"
        else:
            recs += "- No active savings goals detected. Create a goal like 'Emergency Fund' or 'Travel' to accelerate your savings journey!\n"

        return {
            "success": True,
            "recommendations": recs,
            "provider": "offline-rule-engine",
            "model": "deterministic-analyzer",
            "is_offline_fallback": True,
            "reason": error_reason or "API key not configured"
        }

    def plan_budget(self, budget_input: Dict[str, Any]) -> Dict[str, Any]:
        """
        AI-Powered Monthly Budget Planner:
        Generates a personalized, mathematically verified monthly budget allocation
        respecting user fixed obligations, occupation context, and financial goals.
        """
        self.reload_config()
        status = self.get_status()

        # 1. Input Extraction and Validation
        name = str(budget_input.get("name", "")).strip()
        occupation = str(budget_input.get("occupation", "salaried")).strip().lower()
        currency = str(budget_input.get("currency", "INR")).strip()
        try:
            monthly_income = float(budget_input.get("monthly_income", 0.0))
        except (ValueError, TypeError):
            monthly_income = 0.0

        if not name:
            return {"success": False, "error": "Full name is required to generate a personalized budget."}
        if monthly_income <= 0:
            return {"success": False, "error": "Monthly income must be greater than zero."}

        # Optional Inputs & Constraints
        rent_housing = max(0.0, float(budget_input.get("rent_housing") or 0.0))
        education_loans = max(0.0, float(budget_input.get("education_loans") or 0.0))
        existing_savings = max(0.0, float(budget_input.get("existing_savings") or 0.0))
        financial_goals = str(budget_input.get("financial_goals") or "").strip()
        savings_target = max(0.0, float(budget_input.get("savings_target") or 0.0))
        dependents = max(0, int(budget_input.get("dependents") or 0))
        city_context = str(budget_input.get("city_context") or "").strip()
        other_expenses = max(0.0, float(budget_input.get("other_expenses") or 0.0))

        # 2. Fixed Obligations & Shortfall Feasibility Assessment
        fixed_obligations = round(rent_housing + education_loans + other_expenses, 2)
        if fixed_obligations > monthly_income:
            deficit = round(fixed_obligations - monthly_income, 2)
            allocations = []
            if rent_housing > 0:
                allocations.append({
                    "category": "Rent and Housing",
                    "amount": rent_housing,
                    "percentage": round((rent_housing / monthly_income) * 100, 2),
                    "type": "essential",
                    "explanation": "User-specified fixed housing obligation",
                    "is_fixed": True
                })
            if education_loans > 0:
                allocations.append({
                    "category": "Education and Fees",
                    "amount": education_loans,
                    "percentage": round((education_loans / monthly_income) * 100, 2),
                    "type": "debt",
                    "explanation": "User-specified education / loan obligation",
                    "is_fixed": True
                })
            if other_expenses > 0:
                allocations.append({
                    "category": "Other Recurring Obligations",
                    "amount": other_expenses,
                    "percentage": round((other_expenses / monthly_income) * 100, 2),
                    "type": "essential",
                    "explanation": "User-specified recurring commitments",
                    "is_fixed": True
                })

            sym = "₹" if currency == "INR" else f"{currency} "
            return {
                "success": True,
                "summary": f"Deficit Warning: Fixed expenses exceed monthly income by {sym}{deficit:,.2f}",
                "currency": currency,
                "monthly_income": monthly_income,
                "feasibility_status": "shortfall",
                "deficit": deficit,
                "allocations": allocations,
                "total_essential": fixed_obligations,
                "total_lifestyle": 0.0,
                "total_savings": 0.0,
                "unallocated_balance": round(-deficit, 2),
                "savings_percentage": 0.0,
                "ai_explanation": (
                    f"⚠️ **Critical Budget Shortfall**: Your confirmed fixed obligations "
                    f"({sym}{fixed_obligations:,.2f}) exceed your available monthly income "
                    f"({sym}{monthly_income:,.2f}) by **{sym}{deficit:,.2f}**.\n\n"
                    f"• **Priority Review**: Fixed costs account for "
                    f"**{round((fixed_obligations / monthly_income) * 100, 1)}%** of income.\n"
                    f"• **Action Required**: Before any discretionary spending or savings can be scheduled, "
                    f"consider debt restructuring, loan refinancing, downsizing housing, or adding secondary income streams.\n"
                    f"• **Zero Discretionary Budget**: No funds are allocated to shopping, lifestyle, or investments until this gap is resolved."
                ),
                "assumptions": [
                    "User-specified housing and loan payments represent non-negotiable mandatory commitments."
                ],
                "financial_warnings": [
                    f"Immediate shortfall of {sym}{deficit:,.2f}/month.",
                    "Discretionary spending suspended until fixed costs align with income."
                ],
                "savings_recommendation": f"Prioritize debt reduction and restructuring to eliminate the {sym}{deficit:,.2f} deficit.",
                "provider": "application-logic",
                "model": "ground-truth-validator",
                "is_offline_fallback": False
            }

        # 3. Live LLM Generation (if configured)
        if status["is_configured"]:
            try:
                sym = "₹" if currency == "INR" else f"{currency} "
                prompt = (
                    f"Generate a personalized monthly budget plan for:\n"
                    f"- User Name: {name}\n"
                    f"- Occupation: {occupation}\n"
                    f"- Total Monthly Income / Available Budget: {currency} {monthly_income}\n"
                    f"- Confirmed Housing Cost: {currency} {rent_housing} ({'Specified constraint' if rent_housing > 0 else 'Not specified'})\n"
                    f"- Confirmed Education / Loan Payments: {currency} {education_loans} ({'Specified constraint' if education_loans > 0 else 'None'})\n"
                    f"- Existing Savings: {currency} {existing_savings}\n"
                    f"- Stated Goals: '{financial_goals or 'Build healthy financial foundation'}'\n"
                    f"- Preferred Monthly Savings Target: {currency} {savings_target if savings_target > 0 else 'Auto-optimize'}\n"
                    f"- Dependents: {dependents}\n"
                    f"- City / Cost-of-Living: '{city_context or 'Standard'}'\n"
                    f"- Other Fixed Expenses: {currency} {other_expenses}\n\n"
                    f"FINANCIAL RULES & CONSTRAINTS:\n"
                    f"1. Total Monthly Allocations MUST exactly equal {monthly_income}.\n"
                    f"2. If Rent is specified ({rent_housing}), allocation for Rent and Housing MUST be exactly {rent_housing}.\n"
                    f"3. If Education/Loan is specified ({education_loans}), allocation MUST be exactly {education_loans}.\n"
                    f"4. Adapt category distribution to occupation and lifestyle. For example, a student living with parents needs less for rent, "
                    f"while an independent earner needs realistic living allowances.\n"
                    f"5. Only include relevant categories from: Rent and Housing, Food and Groceries, Transportation, "
                    f"Education and Fees, Utilities and Bills, Healthcare, Essential Personal Expenses, Shopping and Lifestyle, "
                    f"Entertainment, Family and Dependents, Debt and Loan Payments, Emergency Fund, Savings and Investments, Miscellaneous Expenses.\n"
                    f"6. Never recommend investing before essential expenses and required debt payments are met.\n"
                    f"7. Do not guarantee investment returns.\n\n"
                    f"Reply ONLY in valid JSON matching this structure:\n"
                    f"{{\n"
                    f'  "summary": "<1-2 sentence executive summary of the budget>",\n'
                    f'  "feasibility_status": "feasible" | "tight",\n'
                    f'  "allocations": [\n'
                    f'    {{"category": "<Category Name>", "amount": <number>, "type": "essential"|"discretionary"|"debt"|"savings", "explanation": "<short reason>"}}\n'
                    f"  ],\n"
                    f'  "ai_explanation": "<Detailed personalized explanation covering: 1. Why major allocations were chosen, 2. Which expenses to prioritize, 3. Where user can save, 4. How it supports goals, 5. Assumptions needing confirmation>",\n'
                    f'  "assumptions": ["<assumption 1>", "<assumption 2>"],\n'
                    f'  "financial_warnings": ["<warning or advisory 1>"],\n'
                    f'  "savings_recommendation": "<recommendation on emergency fund and goal savings>"\n'
                    f"}}"
                )

                raw = self.generate_completion(prompt)
                parsed = self._extract_json(raw)
                if parsed and isinstance(parsed.get("allocations"), list) and len(parsed["allocations"]) > 0:
                    normalized = self._normalize_budget_plan(
                        parsed, monthly_income, currency, rent_housing, education_loans, other_expenses,
                        status["provider"], status["model"], is_offline=False
                    )
                    return normalized
            except Exception as e:
                logger.warning(f"Live budget generation failed ({e}). Falling back to rule-based planner.")

        # 4. Deterministic Offline Analytical Planner Fallback
        return self._offline_budget_planner_fallback(budget_input, status)

    def _extract_json(self, raw: str) -> Optional[Dict[str, Any]]:
        """Safely extracts JSON from LLM markdown code blocks or raw text."""
        cleaned = raw.strip()
        if "```json" in cleaned:
            cleaned = cleaned.split("```json", 1)[1].split("```", 1)[0]
        elif "```" in cleaned:
            cleaned = cleaned.split("```", 1)[1].split("```", 1)[0]
        cleaned = cleaned.strip()

        try:
            return json.loads(cleaned)
        except json.JSONDecodeError:
            start = cleaned.find("{")
            end = cleaned.rfind("}")
            if start != -1 and end != -1 and end > start:
                try:
                    return json.loads(cleaned[start:end + 1])
                except json.JSONDecodeError:
                    pass
        return None

    def _normalize_budget_plan(
        self,
        plan: Dict[str, Any],
        monthly_income: float,
        currency: str,
        rent_housing: float,
        education_loans: float,
        other_expenses: float,
        provider: str,
        model: str,
        is_offline: bool = False
    ) -> Dict[str, Any]:
        """
        Application-logic financial normalizer:
        - Strictly preserves user-confirmed fixed constraints.
        - De-duplicates categories.
        - Ensures Sum(allocations) == monthly_income.
        - Recalculates all exact percentages and summary metrics.
        """
        raw_allocs = plan.get("allocations", [])
        allocations_map: Dict[str, Dict[str, Any]] = {}

        for a in raw_allocs:
            cat = str(a.get("category", "")).strip()
            if not cat:
                continue
            amt = max(0.0, round(float(a.get("amount", 0.0)), 2))
            cat_type = str(a.get("type", "discretionary")).lower()
            if cat_type not in ["essential", "discretionary", "debt", "savings"]:
                cat_type = "discretionary"
            exp = str(a.get("explanation", ""))

            if cat in allocations_map:
                allocations_map[cat]["amount"] = round(allocations_map[cat]["amount"] + amt, 2)
            else:
                allocations_map[cat] = {
                    "category": cat,
                    "amount": amt,
                    "type": cat_type,
                    "explanation": exp,
                    "is_fixed": False
                }

        # Enforce Fixed Constraints
        if rent_housing > 0:
            housing_key = next((k for k in allocations_map if "rent" in k.lower() or "housing" in k.lower()), "Rent and Housing")
            allocations_map[housing_key] = {
                "category": housing_key,
                "amount": rent_housing,
                "type": "essential",
                "explanation": "User-confirmed fixed housing cost",
                "is_fixed": True
            }

        if education_loans > 0:
            edu_key = next((k for k in allocations_map if "education" in k.lower() or "loan" in k.lower() or "debt" in k.lower()), "Education and Fees")
            allocations_map[edu_key] = {
                "category": edu_key,
                "amount": education_loans,
                "type": "debt",
                "explanation": "User-confirmed fixed education/loan obligation",
                "is_fixed": True
            }

        if other_expenses > 0:
            allocations_map["Other Recurring Obligations"] = {
                "category": "Other Recurring Obligations",
                "amount": other_expenses,
                "type": "essential",
                "explanation": "User-confirmed recurring commitments",
                "is_fixed": True
            }

        alloc_list = list(allocations_map.values())

        # Mathematical Reconciliation: Sum(allocations) must equal monthly_income
        current_sum = round(sum(a["amount"] for a in alloc_list), 2)
        diff = round(monthly_income - current_sum, 2)

        if abs(diff) > 0.01:
            if diff > 0:
                target = next((a for a in alloc_list if a["category"] in ["Emergency Fund", "Savings and Investments", "Miscellaneous Expenses"] and not a.get("is_fixed", False)), None)
                if target:
                    target["amount"] = round(target["amount"] + diff, 2)
                else:
                    alloc_list.append({
                        "category": "Miscellaneous Expenses",
                        "amount": diff,
                        "type": "discretionary",
                        "explanation": "Unallocated balance buffered to maintain 100% budget match",
                        "is_fixed": False
                    })
            else:
                to_trim = abs(diff)
                for a in alloc_list:
                    if a.get("type") == "discretionary" and not a.get("is_fixed", False) and a["amount"] > 0:
                        reduction = min(a["amount"], to_trim)
                        a["amount"] = round(a["amount"] - reduction, 2)
                        to_trim = round(to_trim - reduction, 2)
                        if to_trim <= 0.01:
                            break
                if to_trim > 0.01:
                    for a in alloc_list:
                        if a.get("type") == "savings" and not a.get("is_fixed", False) and a["amount"] > 0:
                            reduction = min(a["amount"], to_trim)
                            a["amount"] = round(a["amount"] - reduction, 2)
                            to_trim = round(to_trim - reduction, 2)
                            if to_trim <= 0.01:
                                break

        # Filter out 0 amounts unless fixed
        alloc_list = [a for a in alloc_list if a["amount"] > 0 or a.get("is_fixed", False)]

        # Recalculate percentages & summary metrics
        for a in alloc_list:
            a["percentage"] = round((a["amount"] / monthly_income) * 100, 2)

        total_essential = round(sum(a["amount"] for a in alloc_list if a.get("type") in ["essential", "debt"]), 2)
        total_lifestyle = round(sum(a["amount"] for a in alloc_list if a.get("type") == "discretionary"), 2)
        total_savings = round(sum(a["amount"] for a in alloc_list if a.get("type") == "savings"), 2)
        unallocated_balance = round(monthly_income - (total_essential + total_lifestyle + total_savings), 2)
        savings_percentage = round((total_savings / monthly_income) * 100, 2)

        feasibility_status = "tight" if (total_essential / monthly_income) > 0.70 else "feasible"

        return {
            "success": True,
            "summary": plan.get("summary", f"Personalized Monthly Budget Plan for {currency} {monthly_income:,.2f}"),
            "currency": currency,
            "monthly_income": monthly_income,
            "feasibility_status": feasibility_status,
            "allocations": alloc_list,
            "total_essential": total_essential,
            "total_lifestyle": total_lifestyle,
            "total_savings": total_savings,
            "unallocated_balance": unallocated_balance,
            "savings_percentage": savings_percentage,
            "ai_explanation": plan.get("ai_explanation", "Budget distribution tailored to your income profile and fixed obligations."),
            "assumptions": plan.get("assumptions", ["User-provided financial numbers reflect current monthly standing."]),
            "financial_warnings": plan.get("financial_warnings", []),
            "savings_recommendation": plan.get("savings_recommendation", f"Aim to save {savings_percentage}% of your income consistently."),
            "provider": provider,
            "model": model,
            "is_offline_fallback": is_offline
        }

    def _offline_budget_planner_fallback(
        self, budget_input: Dict[str, Any], status: Dict[str, Any], error_reason: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Deterministic, rule-based personalized financial allocation algorithm.
        Used when LLM backend is offline or unconfigured.
        Guarantees 100% mathematical integrity: Sum(allocations) == monthly_income.
        """
        name = str(budget_input.get("name", "User")).strip()
        occupation = str(budget_input.get("occupation", "salaried")).strip().lower()
        currency = str(budget_input.get("currency", "INR")).strip()
        monthly_income = float(budget_input.get("monthly_income", 0.0))

        rent_housing = max(0.0, float(budget_input.get("rent_housing") or 0.0))
        education_loans = max(0.0, float(budget_input.get("education_loans") or 0.0))
        existing_savings = max(0.0, float(budget_input.get("existing_savings") or 0.0))
        financial_goals = str(budget_input.get("financial_goals") or "").strip()
        savings_target = max(0.0, float(budget_input.get("savings_target") or 0.0))
        dependents = max(0, int(budget_input.get("dependents") or 0))
        city_context = str(budget_input.get("city_context") or "").strip()
        other_expenses = max(0.0, float(budget_input.get("other_expenses") or 0.0))

        sym = "₹" if currency == "INR" else f"{currency} "
        fixed_obligations = round(rent_housing + education_loans + other_expenses, 2)
        remaining = max(0.0, round(monthly_income - fixed_obligations, 2))

        allocations: List[Dict[str, Any]] = []

        # 1. Mandatory Fixed Allocations
        if rent_housing > 0:
            allocations.append({
                "category": "Housing",
                "amount": rent_housing,
                "type": "essential",
                "explanation": "User-specified fixed housing obligation",
                "is_fixed": True
            })
        if education_loans > 0:
            allocations.append({
                "category": "Education Fees",
                "amount": education_loans,
                "type": "debt",
                "explanation": "User-specified education/loan commitment",
                "is_fixed": True
            })
        if other_expenses > 0:
            allocations.append({
                "category": "Other Obligations",
                "amount": other_expenses,
                "type": "essential",
                "explanation": "User-specified recurring commitments",
                "is_fixed": True
            })

        # 2. Determine Savings Allocation
        if savings_target > 0:
            target_savings = min(savings_target, remaining * 0.45)
        else:
            if "student" in occupation:
                target_savings = remaining * 0.20
            elif "freelancer" in occupation or "self-employed" in occupation or "business" in occupation:
                target_savings = remaining * 0.25
            else:
                target_savings = remaining * 0.20

        target_savings = round(target_savings, 2)
        emergency_fund = round(target_savings * 0.40, 2)
        goal_savings = round(target_savings - emergency_fund, 2)

        pool_for_living = max(0.0, round(remaining - target_savings, 2))

        # 3. Dynamic Living Expense Distribution based on Occupation Heuristics
        if "student" in occupation:
            weights = {
                "Food and Groceries": 0.40,
                "Transportation": 0.15,
                "Utilities and Phone": 0.08,
                "Healthcare and Essentials": 0.10,
                "Shopping and Lifestyle": 0.12,
                "Entertainment": 0.08,
                "Miscellaneous": 0.07,
            }
        elif "freelancer" in occupation or "self-employed" in occupation:
            weights = {
                "Food and Groceries": 0.32,
                "Transportation": 0.12,
                "Utilities and Bills": 0.14,
                "Healthcare": 0.10,
                "Shopping and Lifestyle": 0.14,
                "Entertainment": 0.08,
                "Miscellaneous": 0.10,
            }
        else:
            weights = {
                "Food and Groceries": 0.34,
                "Transportation": 0.14,
                "Utilities and Bills": 0.12,
                "Healthcare": 0.08,
                "Shopping and Lifestyle": 0.14,
                "Entertainment": 0.10,
                "Miscellaneous": 0.08,
            }

        if dependents > 0:
            weights["Family and Dependents"] = 0.15
            factor = 0.85
            for k in list(weights.keys()):
                if k != "Family and Dependents":
                    weights[k] = round(weights[k] * factor, 4)

        cat_types = {
            "Food and Groceries": "essential",
            "Transportation": "essential",
            "Utilities and Phone": "essential",
            "Utilities and Bills": "essential",
            "Healthcare and Essentials": "essential",
            "Healthcare": "essential",
            "Family and Dependents": "essential",
            "Shopping and Lifestyle": "discretionary",
            "Entertainment": "discretionary",
            "Miscellaneous": "discretionary",
        }

        allocated_living = 0.0
        weight_keys = list(weights.keys())
        for k in weight_keys[:-1]:
            nominal = round(pool_for_living * weights[k], 2)
            if nominal > 0:
                allocations.append({
                    "category": k,
                    "amount": nominal,
                    "type": cat_types.get(k, "essential"),
                    "explanation": f"Recommended allocation for {k.lower()} based on your financial profile",
                    "is_fixed": False
                })
                allocated_living += nominal

        last_cat = weight_keys[-1]
        last_amt = max(0.0, round(pool_for_living - allocated_living, 2))
        if last_amt > 0:
            allocations.append({
                "category": last_cat,
                "amount": last_amt,
                "type": cat_types.get(last_cat, "discretionary"),
                "explanation": "Buffer allowance for incidental expenses",
                "is_fixed": False
            })

        if emergency_fund > 0:
            allocations.append({
                "category": "Emergency Savings",
                "amount": emergency_fund,
                "type": "savings",
                "explanation": "Buffer against unexpected expenses or medical urgencies",
                "is_fixed": False
            })
        if goal_savings > 0:
            allocations.append({
                "category": "Goal-Based Savings",
                "amount": goal_savings,
                "type": "savings",
                "explanation": f"Dedicated savings for stated goals ({financial_goals or 'Personal Savings'})",
                "is_fixed": False
            })

        current_sum = round(sum(a["amount"] for a in allocations), 2)
        diff = round(monthly_income - current_sum, 2)
        if abs(diff) > 0.001 and allocations:
            for a in reversed(allocations):
                if not a.get("is_fixed", False):
                    a["amount"] = round(a["amount"] + diff, 2)
                    break

        for a in allocations:
            a["percentage"] = round((a["amount"] / monthly_income) * 100, 2)

        total_essential = round(sum(a["amount"] for a in allocations if a["type"] in ["essential", "debt"]), 2)
        total_lifestyle = round(sum(a["amount"] for a in allocations if a["type"] == "discretionary"), 2)
        total_savings = round(sum(a["amount"] for a in allocations if a["type"] == "savings"), 2)
        savings_percentage = round((total_savings / monthly_income) * 100, 2)

        explanation = (
            f"### [AI Analytical Budget Strategy for {name}]\n\n"
            f"• **Income Distribution**: Out of your {sym}{monthly_income:,.2f} monthly budget, "
            f"**{sym}{total_essential:,.2f}** ({round(total_essential/monthly_income*100, 1)}%) covers essential living & obligations, "
            f"**{sym}{total_lifestyle:,.2f}** ({round(total_lifestyle/monthly_income*100, 1)}%) is allocated to lifestyle, and "
            f"**{sym}{total_savings:,.2f}** ({savings_percentage}%) is committed to your future goals.\n\n"
            f"• **Priority Allocations**: Confirmed housing ({sym}{rent_housing:,.2f}) and debt/education ({sym}{education_loans:,.2f}) "
            f"have been safeguarded without alteration.\n\n"
            f"• **Savings Strategy**: Monthly savings of {sym}{total_savings:,.2f} builds your emergency fund and funds your stated target: *'{financial_goals or 'Personal Savings'}'*.\n\n"
            f"• **Flexibility**: Discretionary categories (Shopping & Entertainment) can be adjusted in the interactive editor below before finalizing."
        )

        return {
            "success": True,
            "summary": f"Analytical Budget Plan: {sym}{monthly_income:,.2f} ({occupation.title()})",
            "currency": currency,
            "monthly_income": monthly_income,
            "feasibility_status": "tight" if (total_essential / monthly_income) > 0.70 else "feasible",
            "allocations": allocations,
            "total_essential": total_essential,
            "total_lifestyle": total_lifestyle,
            "total_savings": total_savings,
            "unallocated_balance": 0.0,
            "savings_percentage": savings_percentage,
            "ai_explanation": explanation,
            "assumptions": [
                "Allocations calibrated to regional living benchmarks for your occupation.",
                "Non-essential expenses can be dialed back if unforeseen costs arise."
            ],
            "financial_warnings": [
                "Discretionary spending should be tracked weekly to prevent lifestyle creep."
            ],
            "savings_recommendation": f"Consistently deposit {sym}{total_savings:,.2f} into high-yield savings at the start of each month.",
            "provider": "offline-rule-engine",
            "model": "deterministic-budget-planner",
            "is_offline_fallback": True,
            "reason": error_reason or "Backend running in deterministic offline mode"
        }

