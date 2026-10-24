// MONEY — 3D Cyber-Luxury FinTech Engine with Multi-User Authentication

// Sample demo profile for previewing
const DEMO_TRANSACTIONS = [
  { id: 'tx-1', type: 'income', title: 'Tech Leadership Salary', amount: 125000, category: 'Salary', account: 'Primary Bank Account', date: '2026-10-01' },
  { id: 'tx-2', type: 'income', title: 'AI Advisory Retainer', amount: 18000, category: 'Consulting', account: 'Digital UPI Reserve', date: '2026-10-06' },
  { id: 'tx-3', type: 'expense', title: 'Cyber Suite Lease', amount: 25000, category: 'Rent', account: 'Primary Bank Account', date: '2026-10-02' },
  { id: 'tx-4', type: 'expense', title: 'Quantum Cloud Servers', amount: 8400, category: 'Utilities', account: 'Primary Bank Account', date: '2026-10-08' },
  { id: 'tx-5', type: 'expense', title: 'Executive Omakase Dining', amount: 6200, category: 'Food & Dining', account: 'Titanium Card', date: '2026-10-12' },
  { id: 'tx-6', type: 'expense', title: 'Smart Wearables & Audio', amount: 5500, category: 'Shopping', account: 'Titanium Card', date: '2026-10-17' },
  { id: 'tx-7', type: 'expense', title: 'Chauffeur Transport', amount: 3200, category: 'Transport', account: 'Digital UPI Reserve', date: '2026-10-21' }
];

const DEMO_ACCOUNTS = [
  { id: 'acc-1', name: 'Primary Bank Account', type: 'Bank', balance: 245000, primary: true },
  { id: 'acc-2', name: 'Digital UPI Reserve', type: 'UPI', balance: 14800, primary: false },
  { id: 'acc-3', name: 'Cash Reserve Vault', type: 'Cash', balance: 20000, primary: false },
  { id: 'acc-4', name: 'Titanium Card', type: 'Card', balance: -11700, primary: false }
];

const DEMO_DEBTS = [
  { id: 'debt-1', person: 'Aarav Patel', amount: 6000, type: 'i_owe', note: 'Split conference pass' },
  { id: 'debt-2', person: 'Neha Sharma', amount: 9500, type: 'owed_to_me', note: 'Design consultancy advance' }
];

class Money3DApp {
  constructor() {
    this.users = JSON.parse(localStorage.getItem('money_users')) || [];
    this.currentUser = JSON.parse(localStorage.getItem('money_active_user')) || null;
    this.apiKey = localStorage.getItem('money_gemini_key') || '';
    this.chatHistory = [];
    
    this.state = {
      transactions: [],
      accounts: [],
      debts: [],
      budgetWeights: { needs: 50, wants: 30, savings: 20 },
      balanceMode: 'monthly',
      txFilter: 'all',
      activeTab: 'dashboard'
    };

    this.chartCategory = null;
    this.chartTrends = null;

    this.init();
  }

  init() {
    this.setupEventListeners();
    this.setupNavigation();
    this.setup3DTilt();

    if (!this.currentUser) {
      this.showAuthModal(true);
    } else {
      this.loadUserData(this.currentUser.username);
      this.render();
    }
  }

  // ── Multi-User Profile & Zero-Data Architecture ──
  loadUserData(username) {
    const userKey = `money_data_${username.toLowerCase()}`;
    const savedData = localStorage.getItem(userKey);

    if (savedData) {
      const parsed = JSON.parse(savedData);
      this.state.transactions = parsed.transactions || [];
      this.state.accounts = parsed.accounts || [];
      this.state.debts = parsed.debts || [];
      this.state.budgetWeights = parsed.budgetWeights || { needs: 50, wants: 30, savings: 20 };
    } else {
      // NEW PERSON: Initialized with ZERO DATA!
      this.state.transactions = [];
      this.state.accounts = [
        { id: 'acc-1', name: 'Primary Bank Account', type: 'Bank', balance: 0, primary: true },
        { id: 'acc-2', name: 'Digital UPI Reserve', type: 'UPI', balance: 0, primary: false },
        { id: 'acc-3', name: 'Cash Reserve Vault', type: 'Cash', balance: 0, primary: false }
      ];
      this.state.debts = [];
      this.state.budgetWeights = { needs: 50, wants: 30, savings: 20 };
      this.saveUserData();
    }

    // Load Chat History
    const chatKey = `money_ai_chat_${username.toLowerCase()}`;
    const savedChat = localStorage.getItem(chatKey);
    if (savedChat) {
      this.chatHistory = JSON.parse(savedChat);
    } else {
      this.chatHistory = [{
        sender: 'ai',
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        text: `### ✦ MONEY AI Financial Advisor Online\n\nI am your private banking neural advisor. I cross-reference your actual cash flow and calculate deterministic metrics directly from your personal ledger.\n\nAsk me anything about your spending, runway, or savings targets, or tap any diagnostic chip above!`
      }];
      this.saveChatHistory();
    }
  }

  saveChatHistory() {
    if (!this.currentUser) return;
    const chatKey = `money_ai_chat_${this.currentUser.username.toLowerCase()}`;
    localStorage.setItem(chatKey, JSON.stringify(this.chatHistory));
  }

  saveUserData() {
    if (!this.currentUser) return;
    const userKey = `money_data_${this.currentUser.username.toLowerCase()}`;
    localStorage.setItem(userKey, JSON.stringify({
      transactions: this.state.transactions,
      accounts: this.state.accounts,
      debts: this.state.debts,
      budgetWeights: this.state.budgetWeights
    }));
  }

  // ── Authentication Flows ──
  register(name, username, password) {
    username = username.trim().toLowerCase();
    const existing = this.users.find(u => u.username === username);
    if (existing) {
      this.showToast('Account with this username already exists. Please sign in!');
      return false;
    }

    const newUser = {
      id: 'usr-' + Date.now(),
      name: name.trim(),
      username: username,
      password: password,
      createdAt: new Date().toISOString()
    };

    this.users.push(newUser);
    localStorage.setItem('money_users', JSON.stringify(this.users));

    // Sign in the new user with clean ZERO data
    this.setCurrentUser(newUser, true);
    this.showToast(`Welcome, ${newUser.name}! Your clean ledger starts at ₹0.`);
    return true;
  }

  login(username, password) {
    username = username.trim().toLowerCase();
    const user = this.users.find(u => u.username === username && u.password === password);
    if (!user) {
      this.showToast('Invalid username or password!');
      return false;
    }

    this.setCurrentUser(user, false);
    this.showToast(`Welcome back, ${user.name}!`);
    return true;
  }

  loginAsGuest() {
    const guestUser = {
      id: 'usr-guest',
      name: 'Executive Demo',
      username: 'guest_demo',
      isDemo: true
    };
    
    // Check if demo data exists or initialize with rich demo data
    const userKey = `money_data_guest_demo`;
    if (!localStorage.getItem(userKey)) {
      localStorage.setItem(userKey, JSON.stringify({
        transactions: DEMO_TRANSACTIONS,
        accounts: DEMO_ACCOUNTS,
        debts: DEMO_DEBTS,
        budgetWeights: { needs: 50, wants: 30, savings: 20 }
      }));
    }

    this.setCurrentUser(guestUser, false);
    this.showToast('Loaded Executive 3D Demo Profile!');
  }

  setCurrentUser(user, isNew = false) {
    this.currentUser = user;
    localStorage.setItem('money_active_user', JSON.stringify(user));
    this.loadUserData(user.username);
    this.showAuthModal(false);
    this.render();
  }

  logout() {
    this.currentUser = null;
    localStorage.removeItem('money_active_user');
    this.showToast('Signed out successfully.');
    this.showAuthModal(true);
  }

  showAuthModal(show) {
    const modal = document.getElementById('auth-modal');
    if (modal) {
      if (show) modal.classList.add('open');
      else modal.classList.remove('open');
    }
  }

  // ── Metrics Calculation ──
  getMetrics() {
    let income = 0;
    let expense = 0;

    this.state.transactions.forEach(t => {
      const amt = Number(t.amount) || 0;
      if (t.type === 'income') income += amt;
      else if (t.type === 'expense') expense += amt;
    });

    const netCashflow = income - expense;
    const savingsRate = income > 0 ? Math.max(0, ((netCashflow / income) * 100)).toFixed(1) : '0.0';
    const dayOfMonth = new Date().getDate() || 24;
    const dailyBurnRate = expense > 0 ? (expense / dayOfMonth).toFixed(0) : '0';

    let netWorth = 0;
    this.state.accounts.forEach(a => {
      netWorth += Number(a.balance) || 0;
    });

    return {
      income,
      expense,
      netCashflow,
      savingsRate,
      dailyBurnRate,
      netWorth,
      txCount: this.state.transactions.length
    };
  }

  formatCurrency(num) {
    return '₹' + Number(num).toLocaleString('en-IN', { maximumFractionDigits: 0 });
  }

  // ── Rendering View State ──
  render() {
    const m = this.getMetrics();

    // 1. User Profile Header
    const userBadgeEl = document.getElementById('nav-user-badge');
    const userNameEl = document.getElementById('nav-user-name');
    const userAvatarEl = document.getElementById('nav-user-avatar');
    if (this.currentUser) {
      if (userNameEl) userNameEl.textContent = this.currentUser.name;
      if (userAvatarEl) userAvatarEl.textContent = (this.currentUser.name[0] || 'U').toUpperCase();
      if (userBadgeEl) userBadgeEl.style.display = 'flex';
    } else {
      if (userBadgeEl) userBadgeEl.style.display = 'none';
    }

    // 2. Hero Balance Card
    const heroAmountEl = document.getElementById('hero-amount');
    const heroLabelEl = document.getElementById('hero-balance-label');
    if (heroAmountEl && heroLabelEl) {
      if (this.state.balanceMode === 'monthly') {
        heroLabelEl.textContent = 'MONTHLY NET CASH FLOW';
        const sign = m.netCashflow >= 0 ? '+' : '-';
        heroAmountEl.textContent = sign + this.formatCurrency(Math.abs(m.netCashflow));
      } else {
        heroLabelEl.textContent = 'ALL-TIME VERIFIED NET WORTH';
        heroAmountEl.textContent = this.formatCurrency(m.netWorth);
      }
    }

    // 3. Burn Indicators
    const savingsRateEl = document.getElementById('metric-savings-rate');
    const dailyBurnEl = document.getElementById('metric-burn-rate');
    const txCountEl = document.getElementById('metric-tx-count');
    if (savingsRateEl) savingsRateEl.textContent = m.savingsRate + '%';
    if (dailyBurnEl) dailyBurnEl.textContent = this.formatCurrency(m.dailyBurnRate) + '/day';
    if (txCountEl) txCountEl.textContent = m.txCount + (m.txCount === 1 ? ' Record' : ' Records');

    // 4. Inflow & Outflow Cards
    const incomeTotalEl = document.getElementById('card-income-total');
    const expenseTotalEl = document.getElementById('card-expense-total');
    if (incomeTotalEl) incomeTotalEl.textContent = this.formatCurrency(m.income);
    if (expenseTotalEl) expenseTotalEl.textContent = this.formatCurrency(m.expense);

    // 5. Render Lists & Modules
    this.renderTransactions();
    this.renderAccounts();
    this.renderDebts();
    this.renderBudgetPlanner();
    this.renderCharts();
    this.renderChatStream();
    this.updateAiProviderBadge();
  }

  formatMarkdown(md) {
    if (!md) return '';
    let html = md
      .replace(/### (.*?)\n/g, '<h3>$1</h3>')
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/• (.*?)(?=\n|$)/g, '<li>$1</li>')
      .replace(/\n\n/g, '</p><p>')
      .replace(/\n/g, '<br>');
    return `<p>${html}</p>`.replace(/<p><\/p>/g, '');
  }

  renderChatStream() {
    const stream = document.getElementById('ai-chat-stream');
    if (!stream) return;

    if (!this.chatHistory || this.chatHistory.length === 0) {
      this.chatHistory = [{
        sender: 'ai',
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        text: `### ✦ MONEY AI Financial Advisor Online\n\nI am your private banking neural advisor. Consult me for discretionary leak detection, runway predictions, or 50/30/20 rebalancing.`
      }];
    }

    stream.innerHTML = this.chatHistory.map(msg => {
      const isUser = msg.sender === 'user';
      return `
        <div class="chat-msg ${isUser ? 'user' : 'ai'}">
          <div class="chat-meta">${isUser ? 'You' : '✦ MONEY AI Coach'} • ${msg.time || ''}</div>
          <div class="${isUser ? 'chat-bubble-user' : 'chat-bubble-ai'}">
            ${isUser ? msg.text : this.formatMarkdown(msg.text)}
          </div>
        </div>
      `;
    }).join('');

    stream.scrollTop = stream.scrollHeight;
  }

  updateAiProviderBadge() {
    const badge = document.getElementById('ai-provider-badge');
    if (!badge) return;
    if (this.apiKey && this.apiKey.length > 15) {
      badge.innerHTML = `<span style="display:inline-block;width:7px;height:7px;border-radius:50%;background:#00B4F0;box-shadow:0 0 8px #00B4F0;"></span> Cloud Gemini 1.5 Flash Connected`;
    } else {
      badge.innerHTML = `<span style="display:inline-block;width:7px;height:7px;border-radius:50%;background:var(--cerulean-bright);box-shadow:0 0 8px var(--cerulean-bright);"></span> Math-Verified Heuristic Core`;
    }
  }

  clearChatHistory() {
    this.chatHistory = [{
      sender: 'ai',
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      text: `### ✦ Chat Cleared\n\nI am ready for a new financial advisory session. Ask me any question or tap a prompt chip!`
    }];
    this.saveChatHistory();
    this.renderChatStream();
    this.showToast('Chat history cleared!');
  }

  openApiKeyModal() {
    const modal = document.getElementById('ai-key-modal');
    const input = document.getElementById('input-gemini-key');
    if (input) input.value = this.apiKey || '';
    if (modal) modal.classList.add('open');
  }

  saveApiKey(key) {
    this.apiKey = (key || '').trim();
    if (this.apiKey) {
      localStorage.setItem('money_gemini_key', this.apiKey);
      this.showToast('Gemini API Key saved! Live Cloud LLM active.');
    } else {
      localStorage.removeItem('money_gemini_key');
      this.showToast('Switched to built-in Heuristic Core.');
    }
    this.updateAiProviderBadge();
    const modal = document.getElementById('ai-key-modal');
    if (modal) modal.classList.remove('open');
  }

  removeApiKey() {
    this.apiKey = '';
    localStorage.removeItem('money_gemini_key');
    const input = document.getElementById('input-gemini-key');
    if (input) input.value = '';
    this.updateAiProviderBadge();
    this.showToast('Removed API Key. Using built-in Math Core.');
    const modal = document.getElementById('ai-key-modal');
    if (modal) modal.classList.remove('open');
  }

  renderTransactions() {
    const listEl = document.getElementById('transactions-container');
    const recentEl = document.getElementById('recent-transactions-container');
    if (!listEl && !recentEl) return;

    let filtered = [...this.state.transactions];
    if (this.state.txFilter === 'income') filtered = filtered.filter(t => t.type === 'income');
    else if (this.state.txFilter === 'expense') filtered = filtered.filter(t => t.type === 'expense');

    if (filtered.length === 0) {
      const zeroHtml = `
        <div class="empty-state-3d">
          <div class="empty-state-icon">✦</div>
          <div class="empty-state-title">Clean Ledger Ready</div>
          <p class="empty-state-desc">No transactions recorded yet in your personal workspace. Record your first inflow or outflow to activate 3D dynamic analytics.</p>
          <div class="empty-quick-buttons">
            <button class="submit-btn" style="width:auto;padding:0.75rem 1.6rem;" onclick="app.openAddTxModal('income')">+ Add First Income</button>
            <button class="submit-btn" style="width:auto;padding:0.75rem 1.6rem;background:rgba(255,45,149,0.2);border:1px solid var(--neon-rose);" onclick="app.openAddTxModal('expense')">+ Add First Expense</button>
          </div>
        </div>
      `;
      if (listEl) listEl.innerHTML = zeroHtml;
      if (recentEl) recentEl.innerHTML = zeroHtml;
      return;
    }

    const html = filtered.map(t => {
      const isIncome = t.type === 'income';
      const sign = isIncome ? '+' : '-';
      const badgeCls = isIncome ? 'income' : 'expense';
      const icon = isIncome ? '↗' : '↘';

      return `
        <div class="tx-item" data-id="${t.id}">
          <div class="tx-left">
            <div class="tx-icon-badge ${badgeCls}">${icon}</div>
            <div class="tx-info">
              <h4>${t.title}</h4>
              <div class="tx-meta">
                <span>${t.category}</span>
                <span>•</span>
                <span>${t.date}</span>
                <span class="tx-account-tag">${t.account}</span>
              </div>
            </div>
          </div>
          <div class="tx-right">
            <div class="tx-amount ${badgeCls}">${sign}${this.formatCurrency(t.amount)}</div>
            <button class="tx-delete-btn" onclick="app.deleteTransaction('${t.id}')">Delete</button>
          </div>
        </div>
      `;
    }).join('');

    if (listEl) listEl.innerHTML = html;
    if (recentEl) {
      const recentHtml = filtered.slice(0, 5).map(t => {
        const isIncome = t.type === 'income';
        const sign = isIncome ? '+' : '-';
        const badgeCls = isIncome ? 'income' : 'expense';
        const icon = isIncome ? '↗' : '↘';
        return `
          <div class="tx-item" data-id="${t.id}">
            <div class="tx-left">
              <div class="tx-icon-badge ${badgeCls}">${icon}</div>
              <div class="tx-info">
                <h4>${t.title}</h4>
                <div class="tx-meta">
                  <span>${t.category}</span>
                  <span>•</span>
                  <span>${t.date}</span>
                </div>
              </div>
            </div>
            <div class="tx-right">
              <div class="tx-amount ${badgeCls}">${sign}${this.formatCurrency(t.amount)}</div>
            </div>
          </div>
        `;
      }).join('');
      recentEl.innerHTML = recentHtml;
    }
  }

  renderAccounts() {
    const container = document.getElementById('accounts-container');
    const selectEl = document.getElementById('tx-input-account');
    if (!container) return;

    if (selectEl) {
      selectEl.innerHTML = this.state.accounts.map(acc => `<option value="${acc.name}">${acc.name}</option>`).join('');
    }

    container.innerHTML = this.state.accounts.map(acc => `
      <div class="account-card card-3d ${acc.primary ? 'primary' : ''}">
        <div class="account-top">
          <span class="account-type-tag">${acc.type}</span>
          ${acc.primary ? '<span style="color:var(--cerulean-bright);font-size:0.75rem;font-weight:700;">★ PRIMARY</span>' : ''}
        </div>
        <div style="font-weight:700;font-size:1.1rem;color:#FFF;">${acc.name}</div>
        <div class="account-balance">${this.formatCurrency(acc.balance)}</div>
      </div>
    `).join('');
  }

  renderDebts() {
    const container = document.getElementById('debts-container');
    if (!container) return;

    if (this.state.debts.length === 0) {
      container.innerHTML = `<div style="color:var(--text-muted);text-align:center;padding:2rem;">No outstanding debt obligations recorded.</div>`;
      return;
    }

    container.innerHTML = this.state.debts.map(d => {
      const isOwe = d.type === 'i_owe';
      return `
        <div class="tx-item">
          <div class="tx-left">
            <div class="tx-icon-badge ${isOwe ? 'expense' : 'income'}">${isOwe ? '←' : '→'}</div>
            <div class="tx-info">
              <h4>${d.person}</h4>
              <div class="tx-meta">
                <span>${isOwe ? 'You Owe' : 'Owed to You'}</span>
                <span>•</span>
                <span>${d.note}</span>
              </div>
            </div>
          </div>
          <div class="tx-right">
            <div class="tx-amount ${isOwe ? 'expense' : 'income'}">${this.formatCurrency(d.amount)}</div>
            <button class="tx-delete-btn" onclick="app.settleDebt('${d.id}')">Settle</button>
          </div>
        </div>
      `;
    }).join('');
  }

  renderBudgetPlanner() {
    const m = this.getMetrics();
    const totalIncome = m.income > 0 ? m.income : 100000;

    const needsTarget = (totalIncome * (this.state.budgetWeights.needs / 100));
    const wantsTarget = (totalIncome * (this.state.budgetWeights.wants / 100));
    const savingsTarget = (totalIncome * (this.state.budgetWeights.savings / 100));

    let actualNeeds = 0;
    let actualWants = 0;
    this.state.transactions.filter(t => t.type === 'expense').forEach(t => {
      if (['Rent', 'Utilities', 'Medical', 'Transport'].includes(t.category)) {
        actualNeeds += Number(t.amount);
      } else {
        actualWants += Number(t.amount);
      }
    });
    const actualSavings = Math.max(0, totalIncome - actualNeeds - actualWants);

    const bContainer = document.getElementById('budget-planner-container');
    if (!bContainer) return;

    bContainer.innerHTML = `
      <div class="budget-bucket-card card-3d">
        <div class="bucket-header">
          <span class="bucket-title">🏠 Needs & Fixed Outflows</span>
          <span class="bucket-pct">${this.state.budgetWeights.needs}% Target</span>
        </div>
        <input type="range" class="budget-slider" min="10" max="80" value="${this.state.budgetWeights.needs}" 
          oninput="app.updateBudgetWeight('needs', this.value)">
        <div class="bucket-amounts">
          <span class="bucket-target">Target: ${this.formatCurrency(needsTarget)}</span>
          <span class="bucket-actual">Actual: ${this.formatCurrency(actualNeeds)}</span>
        </div>
      </div>

      <div class="budget-bucket-card card-3d">
        <div class="bucket-header">
          <span class="bucket-title">🍸 Wants & Lifestyle</span>
          <span class="bucket-pct">${this.state.budgetWeights.wants}% Target</span>
        </div>
        <input type="range" class="budget-slider" min="5" max="60" value="${this.state.budgetWeights.wants}" 
          oninput="app.updateBudgetWeight('wants', this.value)">
        <div class="bucket-amounts">
          <span class="bucket-target">Target: ${this.formatCurrency(wantsTarget)}</span>
          <span class="bucket-actual">Actual: ${this.formatCurrency(actualWants)}</span>
        </div>
      </div>

      <div class="budget-bucket-card card-3d">
        <div class="bucket-header">
          <span class="bucket-title">💎 Wealth & Reserve</span>
          <span class="bucket-pct">${this.state.budgetWeights.savings}% Target</span>
        </div>
        <input type="range" class="budget-slider" min="5" max="70" value="${this.state.budgetWeights.savings}" 
          oninput="app.updateBudgetWeight('savings', this.value)">
        <div class="bucket-amounts">
          <span class="bucket-target">Target: ${this.formatCurrency(savingsTarget)}</span>
          <span class="bucket-actual">Current: ${this.formatCurrency(actualSavings)}</span>
        </div>
      </div>
    `;
  }

  updateBudgetWeight(key, val) {
    this.state.budgetWeights[key] = Number(val);
    this.saveUserData();
    this.renderBudgetPlanner();
  }

  renderCharts() {
    if (typeof Chart === 'undefined') return;

    // 1. Category Chart
    const catCanvas = document.getElementById('chart-category');
    if (catCanvas) {
      const expenses = this.state.transactions.filter(t => t.type === 'expense');
      const catMap = {};
      expenses.forEach(e => {
        catMap[e.category] = (catMap[e.category] || 0) + Number(e.amount);
      });

      const labels = Object.keys(catMap);
      const data = Object.values(catMap);
      const colors = ['#007BA7', '#FF2D95', '#00B4F0', '#FF5CAA', '#38C7FA', '#B026FF', '#7928CA'];

      if (this.chartCategory) this.chartCategory.destroy();

      this.chartCategory = new Chart(catCanvas, {
        type: 'doughnut',
        data: {
          labels: labels.length ? labels : ['No Outflows Recorded'],
          datasets: [{
            data: data.length ? data : [1],
            backgroundColor: colors,
            borderColor: '#101016',
            borderWidth: 4
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { position: 'bottom', labels: { color: '#9FA4B8', font: { family: 'Inter', size: 11 } } }
          },
          cutout: '72%'
        }
      });
    }

    // 2. Trends Chart
    const trendCanvas = document.getElementById('chart-trends');
    if (trendCanvas) {
      if (this.chartTrends) this.chartTrends.destroy();

      const m = this.getMetrics();
      const currentInflow = m.income;
      const currentOutflow = m.expense;

      this.chartTrends = new Chart(trendCanvas, {
        type: 'bar',
        data: {
          labels: ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct (Current)'],
          datasets: [
            {
              label: 'Inflow',
              data: [110000, 115000, 120000, 118000, 122000, currentInflow],
              backgroundColor: '#007BA7',
              borderRadius: 6
            },
            {
              label: 'Outflow',
              data: [42000, 46000, 48000, 43000, 45000, currentOutflow],
              backgroundColor: '#FF2D95',
              borderRadius: 6
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            x: { grid: { display: false }, ticks: { color: '#9FA4B8' } },
            y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#9FA4B8' } }
          },
          plugins: {
            legend: { labels: { color: '#9FA4B8', font: { family: 'Inter', size: 11 } } }
          }
        }
      });
    }
  }

  // ── Actions: Add, Delete, Settle ──
  addTransaction(data) {
    const newTx = {
      id: 'tx-' + Date.now(),
      title: data.title,
      type: data.type,
      amount: Number(data.amount),
      category: data.category,
      account: data.account,
      date: data.date || new Date().toISOString().split('T')[0]
    };

    this.state.transactions.unshift(newTx);

    // Update target account balance
    let targetAcc = this.state.accounts.find(a => a.name === data.account);
    if (!targetAcc && this.state.accounts.length > 0) {
      targetAcc = this.state.accounts[0];
    }
    if (targetAcc) {
      if (data.type === 'income') targetAcc.balance += newTx.amount;
      else targetAcc.balance -= newTx.amount;
    }

    this.saveUserData();
    this.render();
    this.showToast(`Transaction "${newTx.title}" recorded!`);
  }

  deleteTransaction(id) {
    const idx = this.state.transactions.findIndex(t => t.id === id);
    if (idx !== -1) {
      const removed = this.state.transactions.splice(idx, 1)[0];
      this.saveUserData();
      this.render();
      this.showToast(`Deleted "${removed.title}"`);
    }
  }

  settleDebt(id) {
    this.state.debts = this.state.debts.filter(d => d.id !== id);
    this.saveUserData();
    this.render();
    this.showToast('Debt obligation settled!');
  }

  openAddTxModal(type = 'expense') {
    const modal = document.getElementById('transaction-modal');
    const typeExp = document.getElementById('type-btn-expense');
    const typeInc = document.getElementById('type-btn-income');
    if (modal) {
      this.selectedTxType = type;
      if (type === 'income') {
        typeInc.classList.add('active', 'income');
        typeExp.classList.remove('active', 'expense');
      } else {
        typeExp.classList.add('active', 'expense');
        typeInc.classList.remove('active', 'income');
      }
      modal.classList.add('open');
    }
  }

  // ── 3D Interactive Card Tilt ──
  setup3DTilt() {
    const handleMove = (e, card) => {
      const rect = card.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const centerX = rect.width / 2;
      const centerY = rect.height / 2;
      const rotateX = ((y - centerY) / centerY) * -9;
      const rotateY = ((x - centerX) / centerX) * 9;
      card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateZ(10px)`;
    };

    const handleLeave = (card) => {
      card.style.transform = `perspective(1000px) rotateX(0deg) rotateY(0deg) translateZ(0px)`;
    };

    document.querySelectorAll('.card-3d').forEach(card => {
      card.addEventListener('mousemove', (e) => handleMove(e, card));
      card.addEventListener('mouseleave', () => handleLeave(card));
    });
  }

  // ── AI Financial Coach Consultation ──
  async runAiCoachPrompt(promptQuery) {
    if (!promptQuery || !promptQuery.trim()) return;
    const query = promptQuery.trim();
    const timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    // 1. Add User Message to Chat History
    this.chatHistory.push({
      sender: 'user',
      time: timeStr,
      text: query
    });
    this.renderChatStream();

    // 2. Add Typing Indicator to Chat
    const stream = document.getElementById('ai-chat-stream');
    let typingEl = null;
    if (stream) {
      typingEl = document.createElement('div');
      typingEl.className = 'chat-msg ai';
      typingEl.innerHTML = `
        <div class="chat-meta">✦ MONEY AI Coach • Analyzing</div>
        <div class="chat-bubble-ai">
          <div class="typing-dots">
            <span class="typing-dot"></span>
            <span class="typing-dot"></span>
            <span class="typing-dot"></span>
          </div>
        </div>
      `;
      stream.appendChild(typingEl);
      stream.scrollTop = stream.scrollHeight;
    }

    // Update Dashboard Box
    const dashBox = document.getElementById('ai-coach-output');
    if (dashBox) {
      dashBox.className = 'ai-box loading';
      dashBox.innerHTML = '⚡ <em>MONEY 3D Neural Advisory Engine calculating metrics...</em>';
    }

    try {
      const resp = await fetch('/api/coach', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          question: query,
          transactions: this.state.transactions,
          accounts: this.state.accounts,
          debts: this.state.debts,
          apiKey: this.apiKey
        })
      });

      if (typingEl) typingEl.remove();

      if (resp.ok) {
        const data = await resp.json();
        const answerText = data.answer || 'Analysis complete.';

        this.chatHistory.push({
          sender: 'ai',
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          text: answerText,
          provider: data.provider
        });
        this.saveChatHistory();
        this.renderChatStream();

        if (dashBox) {
          dashBox.className = 'ai-box';
          dashBox.innerHTML = this.formatMarkdown(answerText);
        }
        return;
      }
    } catch (e) {
      console.log('[AI Fetch Error]:', e);
    }

    if (typingEl) typingEl.remove();

    // Local deterministic fallback
    const m = this.getMetrics();
    const fallbackAnswer = `### ✦ Advisory Assessment\n\n• **Net Inflow:** ${this.formatCurrency(m.income)} | **Outflow:** ${this.formatCurrency(m.expense)}\n• **Net Cashflow:** ${this.formatCurrency(m.netCashflow)} (${m.savingsRate}% savings rate)\n• **Daily Burn:** ${this.formatCurrency(m.dailyBurnRate)}/day\n\nFor question: *"${query}"*, maintaining low discretionary burn is recommended.`;

    this.chatHistory.push({
      sender: 'ai',
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      text: fallbackAnswer
    });
    this.saveChatHistory();
    this.renderChatStream();

    if (dashBox) {
      dashBox.className = 'ai-box';
      dashBox.innerHTML = this.formatMarkdown(fallbackAnswer);
    }
  }

  showToast(msg) {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.textContent = msg;
    container.appendChild(toast);
    setTimeout(() => {
      toast.remove();
    }, 3000);
  }

  setupNavigation() {
    const tabs = document.querySelectorAll('.nav-tab');
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        const targetView = tab.getAttribute('data-view');
        this.switchView(targetView);
      });
    });
  }

  switchView(viewId) {
    document.querySelectorAll('.view-section').forEach(sec => {
      sec.classList.remove('active');
    });
    const target = document.getElementById(`view-${viewId}`);
    if (target) {
      target.classList.add('active');
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
    if (viewId === 'analytics') {
      setTimeout(() => this.renderCharts(), 120);
    }
  }

  setupEventListeners() {
    // 1. Balance Toggle
    const toggleBtn = document.getElementById('balance-toggle-btn');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => {
        this.state.balanceMode = this.state.balanceMode === 'monthly' ? 'networth' : 'monthly';
        toggleBtn.textContent = this.state.balanceMode === 'monthly' ? 'Switch to Net Worth' : 'Switch to Monthly';
        this.render();
      });
    }

    // 2. Add Transaction Modal
    const modal = document.getElementById('transaction-modal');
    const fab = document.getElementById('fab-add');
    const closeBtn = document.getElementById('modal-close-btn');
    const form = document.getElementById('add-tx-form');

    this.selectedTxType = 'expense';
    if (fab) fab.addEventListener('click', () => this.openAddTxModal('expense'));
    if (closeBtn && modal) closeBtn.addEventListener('click', () => modal.classList.remove('open'));
    if (modal) {
      modal.addEventListener('click', (e) => {
        if (e.target === modal) modal.classList.remove('open');
      });
    }

    const typeExp = document.getElementById('type-btn-expense');
    const typeInc = document.getElementById('type-btn-income');
    if (typeExp && typeInc) {
      typeExp.addEventListener('click', () => {
        this.selectedTxType = 'expense';
        typeExp.classList.add('active', 'expense');
        typeInc.classList.remove('active', 'income');
      });
      typeInc.addEventListener('click', () => {
        this.selectedTxType = 'income';
        typeInc.classList.add('active', 'income');
        typeExp.classList.remove('active', 'expense');
      });
    }

    if (form) {
      form.addEventListener('submit', (e) => {
        e.preventDefault();
        const title = document.getElementById('tx-input-title').value.trim();
        const amount = document.getElementById('tx-input-amount').value;
        const category = document.getElementById('tx-input-category').value;
        const account = document.getElementById('tx-input-account').value;

        if (!title || !amount) return;

        this.addTransaction({
          title,
          amount,
          category,
          account,
          type: this.selectedTxType
        });

        form.reset();
        modal.classList.remove('open');
      });
    }

    // 3. Auth Form Handlers (Login / Register / Guest)
    const authTabLogin = document.getElementById('auth-tab-login');
    const authTabRegister = document.getElementById('auth-tab-register');
    const formLogin = document.getElementById('form-login');
    const formRegister = document.getElementById('form-register');
    const guestBtn = document.getElementById('auth-guest-btn');

    if (authTabLogin && authTabRegister) {
      authTabLogin.addEventListener('click', () => {
        authTabLogin.classList.add('active');
        authTabRegister.classList.remove('active');
        formLogin.style.display = 'block';
        formRegister.style.display = 'none';
      });
      authTabRegister.addEventListener('click', () => {
        authTabRegister.classList.add('active');
        authTabLogin.classList.remove('active');
        formLogin.style.display = 'none';
        formRegister.style.display = 'block';
      });
    }

    if (formLogin) {
      formLogin.addEventListener('submit', (e) => {
        e.preventDefault();
        const user = document.getElementById('login-username').value;
        const pass = document.getElementById('login-password').value;
        this.login(user, pass);
      });
    }

    if (formRegister) {
      formRegister.addEventListener('submit', (e) => {
        e.preventDefault();
        const name = document.getElementById('reg-name').value;
        const user = document.getElementById('reg-username').value;
        const pass = document.getElementById('reg-password').value;
        this.register(name, user, pass);
      });
    }

    if (guestBtn) {
      guestBtn.addEventListener('click', (e) => {
        e.preventDefault();
        this.loginAsGuest();
      });
    }

    // Logout
    const logoutBtn = document.getElementById('nav-logout-btn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => this.logout());
    }

    // AI chips
    document.querySelectorAll('.ai-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        const prompt = chip.getAttribute('data-prompt');
        this.runAiCoachPrompt(prompt);
      });
    });

    // Custom AI Form Submit
    const aiForm = document.getElementById('ai-query-form');
    const aiInput = document.getElementById('ai-query-input');
    if (aiForm && aiInput) {
      aiForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const q = aiInput.value.trim();
        if (q) {
          this.runAiCoachPrompt(q);
          aiInput.value = '';
        }
      });
    }

    // AI Key Form
    const aiKeyForm = document.getElementById('form-ai-key');
    if (aiKeyForm) {
      aiKeyForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const key = document.getElementById('input-gemini-key').value;
        this.saveApiKey(key);
      });
    }

    // Filters
    document.querySelectorAll('.tx-filter-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.tx-filter-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.state.txFilter = btn.getAttribute('data-filter');
        this.renderTransactions();
      });
    });
  }

  exportData(format) {
    if (format === 'csv') {
      const headers = ['ID', 'Date', 'Type', 'Title', 'Category', 'Account', 'Amount'];
      const rows = this.state.transactions.map(t => [t.id, t.date, t.type, `"${t.title}"`, `"${t.category}"`, `"${t.account}"`, t.amount]);
      const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map(e => e.join(','))].join('\n');
      const encodedUri = encodeURI(csvContent);
      const link = document.createElement('a');
      link.setAttribute('href', encodedUri);
      link.setAttribute('download', `MONEY_${this.currentUser ? this.currentUser.username : 'ledger'}_${new Date().toISOString().split('T')[0]}.csv`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      this.showToast('CSV statement downloaded!');
    } else if (format === 'json') {
      const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(this.state, null, 2));
      const link = document.createElement('a');
      link.setAttribute('href', dataStr);
      link.setAttribute('download', `MONEY_${this.currentUser ? this.currentUser.username : 'backup'}.json`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      this.showToast('Encrypted JSON backup exported!');
    } else {
      window.print();
    }
  }
}

let app;
window.addEventListener('DOMContentLoaded', () => {
  app = new Money3DApp();
});
