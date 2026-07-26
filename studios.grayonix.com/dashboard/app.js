// ── GetTaller Affiliate Dashboard — Shared JS Library ──

const API_BASE = window.API_BASE || '';

// ── Session management (cookie + localStorage backup) ──
function getToken() {
  // Try cookie first (set by login page or server Set-Cookie)
  const match = document.cookie.match(/session_token=([^;]+)/);
  if (match && match[1]) return match[1];
  // Fallback to localStorage (survives stricter browser settings)
  try { return localStorage.getItem('session_token'); } catch { return null; }
}

function setToken(token) {
  // Set cookie (path=/ so it's available on all pages)
  const d = new Date();
  d.setTime(d.getTime() + 7 * 24 * 60 * 60 * 1000);
  document.cookie = `session_token=${token};path=/;expires=${d.toUTCString()};SameSite=Lax`;
  // Also store in localStorage as backup
  try { localStorage.setItem('session_token', token); } catch {}
}

function clearToken() {
  document.cookie = 'session_token=;path=/;expires=Thu, 01 Jan 1970 00:00:00 GMT';
  try { localStorage.removeItem('session_token'); } catch {}
}

// ── API client ──
async function api(path, opts = {}) {
  const headers = { 'Content-Type': 'application/json', ...opts.headers };
  const token = getToken();
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, {
    headers,
    credentials: 'include',
    body: opts.body ? JSON.stringify(opts.body) : undefined,
    method: opts.method || (opts.body ? 'POST' : 'GET'),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(data.error || 'Request failed');
  return data;
}

// ── Toast notifications ──
function showToast(msg, type = 'success') {
  let toast = document.getElementById('toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast';
    toast.className = 'toast';
    document.body.appendChild(toast);
  }
  toast.textContent = msg;
  toast.className = `toast ${type}`;
  requestAnimationFrame(() => toast.classList.add('show'));
  setTimeout(() => toast.classList.remove('show'), 3500);
}

// ── Loading state ──
function showLoading(container) {
  container.innerHTML = '<div class="loading"><div class="spinner"></div> Loading...</div>';
}

// ── Format helpers ──
function formatCurrency(n) {
  return '$' + (n || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatNumber(n) {
  return (n || 0).toLocaleString();
}

function formatDate(iso) {
  if (!iso) return '—';
  const d = new Date(iso + (iso.includes('T') ? '' : 'T00:00:00Z'));
  return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

// ── Chart: Bar chart ──
function renderBarChart(container, data, labelKey, valueKey, color = 'var(--color-primary)') {
  if (!data || !data.length) {
    container.innerHTML = '<div class="empty-state"><div class="icon">📊</div>No data yet</div>';
    return;
  }

  const values = data.map(d => d[valueKey] || 0);
  const max = Math.max(...values, 1);

  let html = '<div class="chart-bar">';
  data.forEach((d, i) => {
    const pct = (d[valueKey] || 0) / max * 100;
    const label = d[labelKey];
    const shortLabel = label ? label.slice(label.length - 5) : '';
    html += `<div style="flex:1;display:flex;flex-direction:column;align-items:center;">
      <div class="chart-bar-column" style="height:${Math.max(pct, 2)}%;background:${color};">
        <div class="tooltip">${label}: ${d[valueKey]}</div>
      </div>
      ${i % 5 === 0 ? `<div class="chart-bar-label">${shortLabel}</div>` : ''}
    </div>`;
  });
  html += '</div>';
  container.innerHTML = html;
}

// ── Chart: Simple stat card ──
function createStatCard(label, value, sub = '') {
  return `<div class="stat-card">
    <div class="stat-label">${label}</div>
    <div class="stat-value">${value}</div>
    ${sub ? `<div class="stat-sub">${sub}</div>` : ''}
  </div>`;
}

// ── Logout ──
async function logout(e) {
  e?.preventDefault();
  try { await api('/v1/influencer/logout'); } catch {}
  clearToken();
  window.location.href = '/dashboard/login.html';
}

async function adminLogout(e) {
  e?.preventDefault();
  try { await api('/v1/admin/logout'); } catch {}
  clearToken();
  window.location.href = '/admin/login.html';
}

// ── Redirect if not logged in ──
async function requireAuth(redirectUrl) {
  const token = getToken();
  if (!token) { window.location.href = redirectUrl; return null; }
  try {
    const data = await api('/v1/influencer/stats');
    return data;
  } catch {
    clearToken();
    window.location.href = redirectUrl;
    return null;
  }
}

async function requireAdminAuth(redirectUrl) {
  const token = getToken();
  if (!token) { window.location.href = redirectUrl; return null; }
  try {
    const data = await api('/v1/admin/dashboard');
    return data;
  } catch {
    clearToken();
    window.location.href = redirectUrl;
    return null;
  }
}
