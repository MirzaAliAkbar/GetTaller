// ── GetTaller Affiliate Admin — Shared JS Library ──
// Extends /dashboard/app.js — import both scripts on admin pages

// Re-export format helpers for convenience
const fmtCurrency = formatCurrency;
const fmtNumber = formatNumber;
const fmtDate = formatDate;

// ── Admin API helpers ──
async function adminApi(path, opts = {}) {
  return api('/v1/admin' + path, opts);
}

// ── Get influencer stats table row ──
function createInfluencerRow(i) {
  const hasFraud = i.fraudFlags && i.fraudFlags.length > 0;
  return `<tr>
    <td><strong>${i.displayName}</strong></td>
    <td style="font-family:monospace;letter-spacing:1px;">${i.code}</td>
    <td>${fmtNumber(i.totalSignups)}</td>
    <td>${fmtCurrency(i.estimatedRevenue)}</td>
    <td>${fmtCurrency(i.estimatedEarnings)}</td>
    <td>${i.retentionD7}%</td>
    <td>
      <span class="badge ${i.active ? 'badge-active' : 'badge-inactive'}">
        ${i.active ? 'Active' : 'Inactive'}
      </span>
      ${hasFraud ? '<span class="fraud-flag fraud-critical">⚠</span>' : ''}
    </td>
    <td class="actions-cell">
      <a href="/admin/influencer.html?id=${i.code}" class="btn btn-secondary btn-sm">View</a>
      <button class="btn btn-sm ${i.active ? 'btn-danger' : 'btn-primary'}"
              onclick="toggleInfluencer('${i.code}', ${!i.active})">
        ${i.active ? 'Deactivate' : 'Activate'}
      </button>
    </td>
  </tr>`;
}

// ── Toggle influencer active status ──
async function toggleInfluencer(code, active) {
  if (!confirm(`${active ? 'Activate' : 'Deactivate'} code "${code}"?`)) return;
  try {
    await adminApi(`/codes/${code}`, {
      method: 'PATCH',
      body: { active: active ? 1 : 0 },
    });
    showToast(`Code ${code} ${active ? 'activated' : 'deactivated'}`);
    location.reload();
  } catch (e) {
    showToast(e.message, 'error');
  }
}

// ── Render admin stat bar ──
function renderAdminStats(container, data) {
  container.innerHTML = `
    <div class="stats-row admin-stats">
      <div class="stat-card">
        <div class="stat-label">Total Influencers</div>
        <div class="stat-value">${fmtNumber(data.totalInfluencers)}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Total Signups</div>
        <div class="stat-value">${fmtNumber(data.totalSignups)}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Revenue Generated (est.)</div>
        <div class="stat-value">${fmtCurrency(data.totalRevenue)}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Pending Payouts</div>
        <div class="stat-value">${fmtCurrency(data.pendingPayouts)}</div>
      </div>
    </div>`;
}

// ── Render influencer table with filtering ──
function renderInfluencerTable(container, influencers) {
  if (!influencers || !influencers.length) {
    container.innerHTML = '<div class="empty-state"><div class="icon">👥</div>No influencers yet. Add one to get started.</div>';
    return;
  }

  container.innerHTML = `
    <div class="filter-bar">
      <input type="text" id="filterInput" placeholder="Search by name or code..." oninput="filterTable()">
      <select id="statusFilter" onchange="filterTable()" style="width:auto;">
        <option value="all">All status</option>
        <option value="active">Active</option>
        <option value="inactive">Inactive</option>
        <option value="fraud">Fraud alerts</option>
      </select>
      <span class="filter-count" id="filterCount">${influencers.length} influencers</span>
    </div>
    <div style="overflow-x:auto;">
      <table class="admin-table" id="influencerTable">
        <tr><th>Name</th><th>Code</th><th>Signups</th><th>Revenue (est)</th><th>Earnings (est)</th><th>D7 Ret.</th><th>Status</th><th></th></tr>
        <tbody id="tableBody">
          ${influencers.map(createInfluencerRow).join('')}
        </tbody>
      </table>
    </div>
  `;

  window._allInfluencers = influencers;
}

function filterTable() {
  const q = document.getElementById('filterInput').value.toLowerCase();
  const status = document.getElementById('statusFilter').value;
  const filtered = window._allInfluencers.filter(i => {
    const matchName = i.displayName.toLowerCase().includes(q) || i.code.toLowerCase().includes(q);
    const matchStatus = status === 'all' ||
      (status === 'active' && i.active) ||
      (status === 'inactive' && !i.active) ||
      (status === 'fraud' && i.fraudFlags && i.fraudFlags.length > 0);
    return matchName && matchStatus;
  });
  document.getElementById('tableBody').innerHTML = filtered.map(createInfluencerRow).join('');
  document.getElementById('filterCount').textContent = `${filtered.length} of ${window._allInfluencers.length} influencers`;
}

// ── Handle admin nav ──
function handleAdminLogout() {
  fetch('/v1/admin/logout', { method: 'POST', headers: { 'Authorization': 'Bearer ' + getToken() } }).catch(()=>{});
  clearToken();
  window.location.href = '/admin/login.html';
}
