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
