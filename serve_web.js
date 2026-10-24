const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const ROOT_DIR = __dirname;

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.webp': 'image/webp',
  '.pdf': 'application/pdf',
  '.apk': 'application/vnd.android.package-archive',
};

// Send JSON Helper
function sendJson(res, statusCode, data) {
  const body = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  });
  res.end(body);
}

// Deterministic AI Reasoning Core (when offline or no API key)
function generateDeterministicFinancialAdvice(question, transactions = [], accounts = [], debts = []) {
  let income = 0;
  let expense = 0;
  const categoryTotals = {};

  transactions.forEach(t => {
    const amt = Number(t.amount) || 0;
    if (t.type === 'income') {
      income += amt;
    } else if (t.type === 'expense') {
      expense += amt;
      categoryTotals[t.category] = (categoryTotals[t.category] || 0) + amt;
    }
  });

  const netCashFlow = income - expense;
  const savingsRate = income > 0 ? ((netCashFlow / income) * 100).toFixed(1) : '0.0';
  const now = new Date();
  const dayOfMonth = now.getDate() || 24;
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  const remainingDays = Math.max(1, daysInMonth - dayOfMonth);
  const dailyBurn = expense > 0 ? (expense / dayOfMonth).toFixed(0) : 0;
  const projectedOutflow = Number(expense) + (Number(dailyBurn) * remainingDays);
  const projectedSavings = income - projectedOutflow;

  // Find top expense category
  let topCat = 'None';
  let topCatAmt = 0;
  for (const [cat, amt] of Object.entries(categoryTotals)) {
    if (amt > topCatAmt) {
      topCat = cat;
      topCatAmt = amt;
    }
  }

  // Discretionary calculation (wants vs needs)
  let discretionaryAmt = 0;
  let essentialAmt = 0;
  for (const [cat, amt] of Object.entries(categoryTotals)) {
    if (['Food & Dining', 'Shopping', 'Coffee & Snacks', 'Entertainment'].includes(cat)) {
      discretionaryAmt += amt;
    } else {
      essentialAmt += amt;
    }
  }

  // Debt summary
  let iOweTotal = 0;
  let owedToMeTotal = 0;
  debts.forEach(d => {
    if (d.type === 'i_owe') iOweTotal += Number(d.amount) || 0;
    else owedToMeTotal += Number(d.amount) || 0;
  });

  const q = (question || '').toLowerCase();

  if (transactions.length === 0) {
    return {
      answer: `### ✦ Clean Ledger Ready\n\nYour personal workspace is currently at a clean slate (**₹0 balance**, 0 transactions).\n\n**Action Steps:**\n- Record your primary **Monthly Income** (e.g. Salary or Consulting retainer).\n- Log routine expenses as they occur (Rent, Groceries, Dining).\n- Once recorded, I will generate dynamic burn velocity metrics and discretionary leak warnings automatically!`,
      is_fallback: true
    };
  }

  if (q.includes('discretionary') || q.includes('leak') || q.includes('cut') || q.includes('reduce')) {
    const potSavings = (discretionaryAmt * 0.25).toFixed(0);
    return {
      answer: `### 🔍 Discretionary Spending Leak Audit\n\n• **Total Discretionary Burn:** **₹${discretionaryAmt.toLocaleString('en-IN')}** (~${income > 0 ? ((discretionaryAmt / income) * 100).toFixed(1) : 0}% of total inflow).\n• **Top Variable Outflow:** **${topCat}** at **₹${topCatAmt.toLocaleString('en-IN')}**.\n• **Optimization Opportunity:** Trimming dining, coffee, and discretionary shopping by **25%** will recover approximately **₹${Number(potSavings).toLocaleString('en-IN')}** each month directly into your primary wealth vault.\n\n**Actionable Advice:** Set a weekly entertainment cap and route variable payments exclusively through your Digital UPI Reserve to control impulse spending.`,
      is_fallback: true
    };
  }

  if (q.includes('predict') || q.includes('end-of-month') || q.includes('runway') || q.includes('forecast')) {
    return {
      answer: `### ⏱ Month-End Cash Flow Projection\n\n• **Current Burn Velocity:** **₹${Number(dailyBurn).toLocaleString('en-IN')}/day** across the first ${dayOfMonth} days of the month.\n• **Estimated Remaining Outflow:** **₹${(Number(dailyBurn) * remainingDays).toLocaleString('en-IN')}** for the next ${remainingDays} days.\n• **Projected Month-End Outflow:** **₹${projectedOutflow.toLocaleString('en-IN')}**.\n• **Projected Month-End Surplus:** **${projectedSavings >= 0 ? '+' : '-'}₹${Math.abs(projectedSavings).toLocaleString('en-IN')}** (${savingsRate}% overall savings rate).\n\n**Status:** ${projectedSavings >= 0 ? '🟢 Liquidity healthy. You are on track for positive net capital accumulation.' : '🔴 Projected deficit. Consider delaying major discretionary purchases until next month.'}`,
      is_fallback: true
    };
  }

  if (q.includes('50/30/20') || q.includes('budget') || q.includes('framework')) {
    const idealNeeds = (income * 0.5);
    const idealWants = (income * 0.3);
    const idealSavings = (income * 0.2);
    const actualNeedsPct = income > 0 ? ((essentialAmt / income) * 100).toFixed(1) : 0;
    const actualWantsPct = income > 0 ? ((discretionaryAmt / income) * 100).toFixed(1) : 0;

    return {
      answer: `### ⚖️ 50/30/20 Budget Assessment\n\n• **Needs & Fixed Essentials (Max 50%):** Actual is **₹${essentialAmt.toLocaleString('en-IN')}** (${actualNeedsPct}%) vs Target ₹${idealNeeds.toLocaleString('en-IN')} — ${actualNeedsPct <= 50 ? '✅ WITHIN TARGET' : '⚠️ ELEVATED'}\n• **Wants & Lifestyle (Max 30%):** Actual is **₹${discretionaryAmt.toLocaleString('en-IN')}** (${actualWantsPct}%) vs Target ₹${idealWants.toLocaleString('en-IN')} — ${actualWantsPct <= 30 ? '✅ OPTIMAL' : '⚠️ OVER TARGET'}\n• **Wealth & Savings (Min 20%):** Actual is **₹${netCashFlow.toLocaleString('en-IN')}** (${savingsRate}%) vs Target ₹${idealSavings.toLocaleString('en-IN')} — ${Number(savingsRate) >= 20 ? '🌟 EXCELLENT' : '⚠️ BELOW THRESHOLD'}\n\n**Guidance:** Adjust your allocation sliders in the 50/30/20 Plan tab to lock in your surplus targets.`,
      is_fallback: true
    };
  }

  if (q.includes('debt') || q.includes('owe') || q.includes('loan')) {
    return {
      answer: `### 🛡️ Debt & Obligation Strategy\n\n• **Obligations You Owe:** **₹${iOweTotal.toLocaleString('en-IN')}** across ${debts.filter(d => d.type === 'i_owe').length} entries.\n• **Capital Owed to You:** **₹${owedToMeTotal.toLocaleString('en-IN')}**.\n• **Net Debt Position:** **${(owedToMeTotal - iOweTotal) >= 0 ? '+' : '-'}₹${Math.abs(owedToMeTotal - iOweTotal).toLocaleString('en-IN')}**.\n\n**Recommendation:** Maintain a clear debt payoff timeline. Clear high-priority debts from your primary bank vault before allocating surplus to discretionary lifestyle envelopes.`,
      is_fallback: true
    };
  }

  if (q.includes('save') || q.includes('invest') || q.includes('wealth')) {
    return {
      answer: `### 💎 Wealth & Capital Accumulation Blueprint\n\n• **Current Monthly Surplus:** **+₹${netCashFlow.toLocaleString('en-IN')}** (${savingsRate}% savings velocity).\n• **Recommended Emergency Buffer:** Maintain at least 3-6 months of fixed outflows (~₹${(essentialAmt * 3).toLocaleString('en-IN')}) in high-liquidity bank accounts.\n• **Surplus Deployment:** Direct 70% of monthly surplus into systematic index funds or fixed deposits, and reserve 30% for short-term liquidity.`,
      is_fallback: true
    };
  }

  // General comprehensive consultation
  return {
    answer: `### ✦ MONEY AI Financial Advisory\n\n• **Monitored Inflow:** **₹${income.toLocaleString('en-IN')}** | **Outflow:** **₹${expense.toLocaleString('en-IN')}**\n• **Net Cash Position:** **${netCashFlow >= 0 ? '+' : '-'}₹${Math.abs(netCashFlow).toLocaleString('en-IN')}** with a **${savingsRate}%** savings rate.\n• **Top Outflow Category:** **${topCat}** totaling **₹${topCatAmt.toLocaleString('en-IN')}**.\n• **Daily Outflow Pace:** **₹${Number(dailyBurn).toLocaleString('en-IN')}/day**.\n\n**Advice:** Regarding *"${question}"*, your current liquidity supports steady financial progress. Keep monitoring variable expenses to maintain your target savings velocity.`,
    is_fallback: true
  };
}

// Call Google Gemini API (if API Key provided)
async function callGeminiLive(apiKey, prompt, context) {
  return new Promise((resolve, reject) => {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    
    const payload = {
      contents: [{
        parts: [{
          text: `You are MONEY AI Financial Coach, an elite private banking advisor.
Answer the user's question clearly, concisely, and actionably using markdown headers and bullet points.
Cite their verified numbers where appropriate.

VERIFIED FINANCIAL METRICS:
${JSON.stringify(context, null, 2)}

USER QUESTION:
${prompt}`
        }]
      }],
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 1024
      }
    };

    const data = JSON.stringify(payload);
    const req = https.request(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      },
      timeout: 12000
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            const parsed = JSON.parse(body);
            const text = parsed.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) return resolve(text);
          }
          reject(new Error(`Gemini API error (Status ${res.statusCode}): ${body.substring(0, 150)}`));
        } catch (err) {
          reject(err);
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Gemini API timeout after 12s'));
    });
    req.write(data);
    req.end();
  });
}

// HTTP Server
const server = http.createServer(async (req, res) => {
  // Handle CORS Preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    });
    return res.end();
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  let reqPath = decodeURI(parsedUrl.pathname);

  // ── API: Health Check ──
  if (reqPath === '/api/health') {
    return sendJson(res, 200, {
      status: 'online',
      service: 'MONEY AI Financial Coach Microservice',
      version: '2.0.0',
      node_version: process.version,
      port: PORT
    });
  }

  // ── API: AI Coach & Chat Endpoints ──
  if ((reqPath === '/api/coach' || reqPath === '/api/ai/chat' || reqPath === '/api/ai/insights') && req.method === 'POST') {
    let bodyText = '';
    req.on('data', chunk => {
      bodyText += chunk;
      if (bodyText.length > 2 * 1024 * 1024) {
        req.destroy(); // Protect against large payloads
      }
    });

    req.on('end', async () => {
      try {
        const body = bodyText ? JSON.parse(bodyText) : {};
        const question = body.question || body.message || 'Summarize my financial health';
        const transactions = body.transactions || [];
        const accounts = body.accounts || [];
        const debts = body.debts || [];
        const apiKey = body.apiKey || process.env.GEMINI_API_KEY;

        // If Gemini API Key is available, try live cloud generation
        if (apiKey && apiKey.length > 15 && !apiKey.startsWith('your_')) {
          try {
            const contextData = { transactions, accounts, debts };
            const geminiAnswer = await callGeminiLive(apiKey, question, contextData);
            return sendJson(res, 200, {
              success: true,
              answer: geminiAnswer,
              provider: 'gemini',
              model: 'gemini-1.5-flash',
              is_offline_fallback: false
            });
          } catch (geminiError) {
            console.log('[Gemini Cloud Fallback]:', geminiError.message);
          }
        }

        // Deterministic intelligent financial analysis
        const result = generateDeterministicFinancialAdvice(question, transactions, accounts, debts);
        return sendJson(res, 200, {
          success: true,
          answer: result.answer,
          provider: 'neural_heuristic_core',
          model: 'MONEY-Math-v2',
          is_offline_fallback: true
        });
      } catch (err) {
        return sendJson(res, 500, {
          error: 'Failed to process AI advisory request',
          details: err.message
        });
      }
    });
    return;
  }

  // ── Static Files Serving ──
  if (reqPath === '/' || reqPath === '') {
    if (fs.existsSync(path.join(ROOT_DIR, 'My-Money', 'build', 'web', 'index.html'))) {
      reqPath = '/index.html';
    } else {
      reqPath = '/APP_GUIDE.html';
    }
  }

  let filePath = path.join(ROOT_DIR, 'My-Money', 'build', 'web', reqPath);
  if (!fs.existsSync(filePath)) {
    filePath = path.join(ROOT_DIR, reqPath);
  }
  if (!fs.existsSync(filePath)) {
    filePath = path.join(ROOT_DIR, 'My-Money', reqPath);
  }

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': contentType,
      'Access-Control-Allow-Origin': '*'
    });
    fs.createReadStream(filePath).pipe(res);
  } else {
    const fallbackPath = path.join(ROOT_DIR, 'My-Money', 'build', 'web', 'index.html');
    if (fs.existsSync(fallbackPath)) {
      res.writeHead(200, {
        'Content-Type': 'text/html; charset=utf-8',
        'Access-Control-Allow-Origin': '*'
      });
      fs.createReadStream(fallbackPath).pipe(res);
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('404 Not Found');
    }
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`MONEY Server & AI Microservice active at http://localhost:${PORT}`);
  console.log(`AI Endpoints: POST /api/coach | POST /api/ai/chat | GET /api/health`);
});
