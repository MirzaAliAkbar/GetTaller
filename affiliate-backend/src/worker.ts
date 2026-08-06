// ── GetTaller Affiliate — Cloudflare Worker ──
// Handles referral validation, event logging, influencer + admin dashboards

// ── Password hashing using Web Crypto API (no Node.js deps) ──

async function hashPassword(password: string): Promise<string> {
  const encoder = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const keyMaterial = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveBits']);
  const key = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' }, keyMaterial, 256);
  const combined = new Uint8Array(48);
  combined.set(salt);
  combined.set(new Uint8Array(key), 16);
  return btoa(String.fromCharCode(...combined));
}

async function verifyPassword(password: string, stored: string): Promise<boolean> {
  try {
    const combined = Uint8Array.from(atob(stored), c => c.charCodeAt(0));
    if (combined.length !== 48) return false;
    const salt = combined.slice(0, 16);
    const origHash = combined.slice(16);
    const encoder = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey('raw', encoder.encode(password), 'PBKDF2', false, ['deriveBits']);
    const key = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' }, keyMaterial, 256);
    const newHash = new Uint8Array(key);
    return origHash.every((b, i) => b === newHash[i]);
  } catch { return false; }
}

interface Env {
  DB: D1Database;
  ADMIN_SECRET: string;
  SESSION_SECRET: string;
  ENVIRONMENT: string;
}

// ── Route handler types ──
type Handler = (request: Request, env: Env, ctx: ExecutionContext) => Promise<Response>;

// ── CORS headers ──
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Admin-Key, Authorization',
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function html(body: string, status = 200): Response {
  return new Response(body, {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' },
  });
}

function error(msg: string, status = 400): Response {
  return json({ error: msg }, status);
}

// ── Uppercase helper ──
function uc(s: string): string {
  return s.toUpperCase().trim();
}

// ── Session helpers ──
async function createSession(env: Env, userId: string, userType: string): Promise<string> {
  const token = crypto.randomUUID();
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(); // 7 days
  await env.DB.prepare(
    'INSERT INTO sessions (token, user_type, user_id, expires_at) VALUES (?, ?, ?, ?)'
  ).bind(token, userType, userId, expiresAt).run();
  return token;
}

async function getSession(env: Env, token: string): Promise<{ userId: string; userType: string } | null> {
  const row = await env.DB.prepare(
    'SELECT user_type, user_id FROM sessions WHERE token = ? AND expires_at > datetime(\'now\')'
  ).bind(token).first<{ user_type: string; user_id: string }>();
  if (!row) return null;
  return { userId: row.user_id, userType: row.user_type };
}

function getTokenFromRequest(request: Request): string | null {
  // Priority 1: Authorization header (used by adminApi and api())
  const auth = request.headers.get('Authorization') || '';
  if (auth.startsWith('Bearer ')) return auth.slice(7);
  // Priority 2: admin_session_token cookie (admin pages, set by adminSetToken)
  const cookie = request.headers.get('Cookie') || '';
  let match = cookie.match(/admin_session_token=([^;]+)/);
  if (match) return match[1];
  // Priority 3: session_token cookie (influencer pages, set by setToken or server Set-Cookie)
  match = cookie.match(/session_token=([^;]+)/);
  if (match) return match[1];
  return null;
}

// ── Milestone check: flip 5 → 20 when signups cross 5000 ──
async function checkMilestone(env: Env, code: string, influencerId: string): Promise<void> {
  const row = await env.DB.prepare(
    'SELECT share_percent FROM referral_codes WHERE code = ?'
  ).bind(code).first<{ share_percent: number }>();

  if (row && row.share_percent === 5) {
    const count = await env.DB.prepare(
      'SELECT COUNT(*) as cnt FROM signups WHERE code = ?'
    ).bind(code).first<{ cnt: number }>();

    if (count && count.cnt >= 5000) {
      await env.DB.prepare(
        'UPDATE referral_codes SET share_percent = 20 WHERE code = ?'
      ).bind(code).run();
    }
  }
}

// ── Retention Day: how many unique days this user has pinged ──
async function getRetentionDay(env: Env, installId: string): Promise<number> {
  const row = await env.DB.prepare(
    'SELECT COUNT(DISTINCT date) as days FROM daily_pings WHERE install_id = ?'
  ).bind(installId).first<{ days: number }>();
  return row?.days ?? 0;
}

// ══════════════════════════════════════════════════════════════════
// PUBLIC ROUTES
// ══════════════════════════════════════════════════════════════════

async function handleValidate(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const rawCode = url.searchParams.get('code') || '';
  const code = uc(rawCode);
  if (!code) return json({ valid: false, reason: 'missing_code' });

  const row = await env.DB.prepare(
    'SELECT code, influencer_id, share_percent, active FROM referral_codes WHERE code = ?'
  ).bind(code).first<{ code: string; influencer_id: string; share_percent: number; active: number }>();

  if (!row || !row.active) {
    return json({ valid: false, reason: 'invalid' });
  }

  return json({
    valid: true,
    sharePercent: row.share_percent,
    influencerId: row.influencer_id,
  });
}

async function handleSignup(request: Request, env: Env): Promise<Response> {
  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const rawCode = body.code || '';
  const code = uc(rawCode);
  const installId = body.installId;
  if (!code || !installId) return error('Missing code or installId');

  // Look up influencer
  const influencer = await env.DB.prepare(
    'SELECT influencer_id FROM referral_codes WHERE code = ? AND active = 1'
  ).bind(code).first<{ influencer_id: string }>();
  if (!influencer) return error('Invalid or inactive code');

  // First-code-wins: check if this install already attributed
  const existing = await env.DB.prepare(
    'SELECT id FROM signups WHERE install_id = ?'
  ).bind(installId).first();
  if (existing) return json({ ok: true, note: 'already_attributed' });

  // Insert signup
  await env.DB.prepare(
    `INSERT INTO signups (install_id, code, influencer_id, country, platform, app_version)
     VALUES (?, ?, ?, ?, ?, ?)`
  ).bind(
    installId, code, influencer.influencer_id,
    request.cf?.country || null,
    body.platform || null,
    body.appVersion || null
  ).run();

  // Bump total_installs
  await env.DB.prepare(
    'UPDATE referral_codes SET total_installs = total_installs + 1 WHERE code = ?'
  ).bind(code).run();

  // Check milestone (5K → 20%)
  await checkMilestone(env, code, influencer.influencer_id);

  return json({ ok: true });
}

async function handleAdEvents(request: Request, env: Env): Promise<Response> {
  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const events: any[] = body.events || [body]; // single or batch
  if (!events.length) return error('No events');

  for (const e of events) {
    const installId = e.installId || '';
    if (!installId) continue;
    try {
      await env.DB.prepare(
        `INSERT INTO ad_events (install_id, code, influencer_id, ad_format, value_micros, currency, precision)
         VALUES (?, ?, ?, ?, ?, ?, ?)`
      ).bind(
        installId,
        e.code || null,
        e.influencerId || null,
        e.adFormat || 'unknown',
        e.valueMicros || 0,
        e.currency || 'USD',
        e.precision ?? 0
      ).run();
    } catch (err: any) {
      console.error('Ad event insert error:', err?.message);
    }
  }

  return json({ ok: true });
}

async function handlePing(request: Request, env: Env): Promise<Response> {
  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const installId = body.installId;
  const code = uc(body.code || '');
  if (!installId || !code) return error('Missing installId or code');

  const today = new Date().toISOString().slice(0, 10);

  // Upsert daily ping (ignore duplicate due to unique constraint)
  try {
    await env.DB.prepare(
      'INSERT INTO daily_pings (install_id, code, date) VALUES (?, ?, ?)'
    ).bind(installId, code, today).run();
  } catch {
    // Already pinged today
  }

  const retentionDay = await getRetentionDay(env, installId);

  return json({ ok: true, retentionDay });
}

// ══════════════════════════════════════════════════════════════════
// SUBSCRIPTION EVENT ROUTES
// ══════════════════════════════════════════════════════════════════

async function handleSubscriptionEvent(request: Request, env: Env): Promise<Response> {
  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const userId = body.userId || body.installId || '';
  const eventType = body.eventType || 'purchase'; // purchase, renewal, cancel, expire
  const productId = body.productId || '';
  const amountCents = body.amountCents || 0;
  const currency = body.currency || 'USD';
  const platform = body.platform || 'android';
  const referralCode = body.referralCode ? uc(body.referralCode) : null;

  if (!userId || !productId) return error('Missing userId or productId');

  // Look up influencer from referral code
  let influencerId: string | null = null;
  if (referralCode) {
    const inf = await env.DB.prepare(
      'SELECT influencer_id FROM referral_codes WHERE code = ?'
    ).bind(referralCode).first<{ influencer_id: string }>();
    influencerId = inf?.influencer_id ?? null;
  }

  // Insert subscription event
  await env.DB.prepare(
    `INSERT INTO subscription_events (user_id, influencer_id, referral_code, event_type, product_id, amount_cents, currency, platform)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(userId, influencerId, referralCode, eventType, productId, amountCents, currency, platform).run();

  return json({ ok: true });
}

// ══════════════════════════════════════════════════════════════════
// INFLUENCER DASHBOARD ROUTES
// ══════════════════════════════════════════════════════════════════

async function handleInfluencerLogin(request: Request, env: Env): Promise<Response> {
  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const code = uc(body.code || '');
  const password = body.password || '';
  if (!code || !password) return error('Missing code or password');

  const row = await env.DB.prepare(
    'SELECT code, influencer_id, display_name, password_hash, active FROM referral_codes WHERE code = ?'
  ).bind(code).first<{ code: string; influencer_id: string; display_name: string; password_hash: string; active: number }>();

  if (!row || !row.active) return error('Invalid credentials', 401);

  const match = await verifyPassword(password, row.password_hash);
  if (!match) return error('Invalid credentials', 401);

  const token = await createSession(env, row.influencer_id, 'influencer');

  const headers = new Headers(corsHeaders);
  headers.set('Set-Cookie', `session_token=${token};path=/;max-age=${7*24*60*60};SameSite=Lax;Secure`);
  headers.set('Content-Type', 'application/json');

  return new Response(JSON.stringify({
    ok: true,
    token,
    influencer: {
      id: row.influencer_id,
      displayName: row.display_name,
      code: row.code,
    },
  }), { status: 200, headers });
}

async function handleInfluencerStats(request: Request, env: Env, influencerId: string): Promise<Response> {
  // ── Total signups ──
  const signupRow = await env.DB.prepare(
    'SELECT COUNT(*) as total FROM signups WHERE influencer_id = ?'
  ).bind(influencerId).first<{ total: number }>();
  const totalSignups = signupRow?.total ?? 0;

  // ── Revenue estimate ──
  const revenueRow = await env.DB.prepare(
    `SELECT SUM(value_micros) as total, COUNT(*) as count
     FROM ad_events WHERE influencer_id = ?`
  ).bind(influencerId).first<{ total: number; count: number }>();
  const totalRevenueMicros = revenueRow?.total ?? 0;
  const totalRevenue = totalRevenueMicros / 1_000_000;
  const adEventCount = revenueRow?.count ?? 0;

  // ── Influencer profile ──
  const profile = await env.DB.prepare(
    'SELECT display_name, code, share_percent, total_installs, created_at, last_payout_at, active FROM referral_codes WHERE influencer_id = ?'
  ).bind(influencerId).first<{ display_name: string; code: string; share_percent: number; total_installs: number; created_at: string; last_payout_at: string | null; active: number }>();

  // ── Earnings (revenue * share%) ──
  const sharePercent = profile?.share_percent ?? 5;
  const earningsEstimate = totalRevenue * (sharePercent / 100);

  // ── Revenue per user ──
  const rpu = totalSignups > 0 ? totalRevenue / totalSignups : 0;

  // ── Signups over time (last 30 days) ──
  const signupsByDay = await env.DB.prepare(
    `SELECT DATE(created_at) as day, COUNT(*) as count
     FROM signups WHERE influencer_id = ?
     AND created_at >= datetime('now', '-30 days')
     GROUP BY day ORDER BY day`
  ).bind(influencerId).all<{ day: string; count: number }>();

  // ── Revenue over time (last 90 days, aggregated daily) ──
  const revenueByDay = await env.DB.prepare(
    `SELECT DATE(created_at) as day,
            SUM(value_micros) as micros,
            COUNT(*) as count
     FROM ad_events WHERE influencer_id = ?
     AND created_at >= datetime('now', '-90 days')
     GROUP BY day ORDER BY day`
  ).bind(influencerId).all<{ day: string; micros: number; count: number }>();

  // ── Revenue by ad format ──
  const revenueByFormat = await env.DB.prepare(
    `SELECT ad_format, SUM(value_micros) as micros, COUNT(*) as count
     FROM ad_events WHERE influencer_id = ?
     GROUP BY ad_format`
  ).bind(influencerId).all<{ ad_format: string; micros: number; count: number }>();

  // ── Premium subscription metrics ──
  const premiumRow = await env.DB.prepare(
    `SELECT COUNT(DISTINCT user_id) as premium_users,
            SUM(amount_cents) as total_revenue_cents,
            COUNT(*) as total_events
     FROM subscription_events
     WHERE influencer_id = ? AND event_type IN ('purchase', 'renewal')`
  ).bind(influencerId).first<{ premium_users: number; total_revenue_cents: number; total_events: number }>();

  // Recent subscription events
  const recentSubscriptions = await env.DB.prepare(
    `SELECT created_at, event_type, amount_cents, currency
     FROM subscription_events
     WHERE influencer_id = ?
     ORDER BY created_at DESC LIMIT 10`
  ).bind(influencerId).all<{ created_at: string; event_type: string; amount_cents: number; currency: string }>();

  // ── Retention curve ──
  // How many users signed up >= 1/7/30/90 days ago AND have at least that many ping dates
  // Simplified: get all signups, count distinct ping dates per user
  const retentionRaw = await env.DB.prepare(
    `SELECT s.install_id,
            s.created_at as signup_date,
            (SELECT COUNT(DISTINCT date) FROM daily_pings dp WHERE dp.install_id = s.install_id) as active_days,
            (SELECT date FROM daily_pings dp WHERE dp.install_id = s.install_id ORDER BY dp.date DESC LIMIT 1) as last_active
     FROM signups s
     WHERE s.influencer_id = ?
     ORDER BY s.created_at DESC
     LIMIT 500`
  ).bind(influencerId).all<{ install_id: string; signup_date: string; active_days: number; last_active: string | null }>();

  // Compute retention: percentage still active at D1, D7, D30, D90
  const now = new Date();
  let d1Total = 0, d1Active = 0;
  let d7Total = 0, d7Active = 0;
  let d30Total = 0, d30Active = 0;
  let d90Total = 0, d90Active = 0;

  for (const r of retentionRaw.results || []) {
    const signupDate = new Date(r.signup_date);
    const daysSince = Math.floor((now.getTime() - signupDate.getTime()) / 86400000);

    if (daysSince >= 1) { d1Total++; if (r.active_days >= 1) d1Active++; }
    if (daysSince >= 7) { d7Total++; if (r.active_days >= 7) d7Active++; }
    if (daysSince >= 30) { d30Total++; if (r.active_days >= 30) d30Active++; }
    if (daysSince >= 90) { d90Total++; if (r.active_days >= 90) d90Active++; }
  }

  const retention = {
    d1: d1Total > 0 ? Math.round((d1Active / d1Total) * 100) : 0,
    d7: d7Total > 0 ? Math.round((d7Active / d7Total) * 100) : 0,
    d30: d30Total > 0 ? Math.round((d30Active / d30Total) * 100) : 0,
    d90: d90Total > 0 ? Math.round((d90Active / d90Total) * 100) : 0,
  };

  // ── Last 30 days of ad revenue for chart ──
  const revenue30d = await env.DB.prepare(
    `SELECT DATE(created_at) as day,
            SUM(value_micros) / 1000000.0 as revenue,
            COUNT(*) as count
     FROM ad_events WHERE influencer_id = ?
     AND created_at >= datetime('now', '-30 days')
     GROUP BY day ORDER BY day`
  ).bind(influencerId).all<{ day: string; revenue: number; count: number }>();

  // ── Recent signups ──
  const recentSignups = await env.DB.prepare(
    `SELECT created_at, country, platform
     FROM signups WHERE influencer_id = ?
     ORDER BY created_at DESC LIMIT 20`
  ).bind(influencerId).all<{ created_at: string; country: string; platform: string }>();

  return json({
    influencer: {
      displayName: profile?.display_name ?? 'Unknown',
      code: profile?.code ?? '',
      sharePercent,
      active: !!profile?.active,
      totalInstalls: profile?.total_installs ?? 0,
      memberSince: profile?.created_at ?? '',
      lastPayoutAt: profile?.last_payout_at ?? null,
    },
    stats: {
      totalSignups,
      totalRevenue: Math.round(totalRevenue * 100) / 100,
      totalRevenueMicros,
      adEventCount,
      earningsEstimate: Math.round(earningsEstimate * 100) / 100,
      revenuePerUser: Math.round(rpu * 100) / 100,
      premiumUsers: premiumRow?.premium_users ?? 0,
      subscriptionRevenue: (premiumRow?.total_revenue_cents ?? 0) / 100,
      premiumConversionRate: totalSignups > 0
        ? Math.round(((premiumRow?.premium_users ?? 0) / totalSignups) * 10000) / 100
        : 0,
    },
    charts: {
      signupsByDay: signupsByDay.results || [],
      revenue30d: revenue30d.results || [],
      revenueByFormat: revenueByFormat.results || [],
      revenueByDay: revenueByDay.results || [],
      recentSubscriptions: recentSubscriptions.results || [],
    },
    retention,
    recentSignups: recentSignups.results || [],
  });
}

async function handleInfluencerSettings(request: Request, env: Env, influencerId: string): Promise<Response> {
  const profile = await env.DB.prepare(
    'SELECT code, display_name, share_percent, total_installs, created_at, last_payout_at FROM referral_codes WHERE influencer_id = ?'
  ).bind(influencerId).first<{ code: string; display_name: string; share_percent: number; total_installs: number; created_at: string; last_payout_at: string | null }>();

  // Payout history
  const payouts = await env.DB.prepare(
    'SELECT month, total_signups, ad_revenue_micros, payout_micros, paid, paid_at, notes FROM payouts WHERE influencer_id = ? ORDER BY month DESC LIMIT 12'
  ).bind(influencerId).all<{ month: string; total_signups: number; ad_revenue_micros: number; payout_micros: number; paid: number; paid_at: string | null; notes: string | null }>();

  return json({
    profile: {
      displayName: profile?.display_name ?? 'Unknown',
      code: profile?.code ?? '',
      sharePercent: profile?.share_percent ?? 5,
      totalInstalls: profile?.total_installs ?? 0,
      memberSince: profile?.created_at ?? '',
      lastPayoutAt: profile?.last_payout_at ?? null,
    },
    payouts: payouts.results || [],
  });
}

async function handleInfluencerLogout(request: Request, env: Env): Promise<Response> {
  const token = getTokenFromRequest(request);
  if (token) {
    await env.DB.prepare('DELETE FROM sessions WHERE token = ?').bind(token).run();
  }
  return json({ ok: true });
}

// ══════════════════════════════════════════════════════════════════
// ADMIN ROUTES
// ══════════════════════════════════════════════════════════════════

async function handleAdminLogin(request: Request, env: Env): Promise<Response> {
  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const username = (body.username || '').trim();
  const password = body.password || '';
  if (!username || !password) return error('Missing username or password');

  const row = await env.DB.prepare(
    'SELECT username, password_hash FROM admin_users WHERE username = ?'
  ).bind(username).first<{ username: string; password_hash: string }>();

  if (!row) return error('Invalid credentials', 401);

  const match = await verifyPassword(password, row.password_hash);
  if (!match) return error('Invalid credentials', 401);

  const token = await createSession(env, username, 'admin');

  // Set session cookie server-side for reliability
  const headers = new Headers(corsHeaders);
  headers.set('Set-Cookie', `admin_session_token=${token};path=/;max-age=${7*24*60*60};SameSite=Lax;Secure`);
  headers.set('Content-Type', 'application/json');

  return new Response(JSON.stringify({ ok: true, token, username }), {
    status: 200,
    headers,
  });
}

async function handleAdminDashboard(request: Request, env: Env): Promise<Response> {
  // Total influencers
  const infRow = await env.DB.prepare(
    'SELECT COUNT(*) as total FROM referral_codes'
  ).first<{ total: number }>();

  // Total signups
  const sigRow = await env.DB.prepare(
    'SELECT COUNT(*) as total FROM signups'
  ).first<{ total: number }>();

  // Total ad revenue
  const revRow = await env.DB.prepare(
    'SELECT SUM(value_micros) as total FROM ad_events'
  ).first<{ total: number }>();

  // Total payouts pending
  const payoutRow = await env.DB.prepare(
    'SELECT COALESCE(SUM(payout_micros), 0) as total FROM payouts WHERE paid = 0'
  ).first<{ total: number }>();

  // Premium subscribers
  const premiumRow = await env.DB.prepare(
    `SELECT COUNT(DISTINCT user_id) as premium_users,
            SUM(amount_cents) as total_revenue_cents
     FROM subscription_events
     WHERE event_type IN ('purchase', 'renewal')`
  ).first<{ premium_users: number; total_revenue_cents: number }>();

  // Signups today
  const todayRow = await env.DB.prepare(
    "SELECT COUNT(*) as total FROM signups WHERE DATE(created_at) = DATE('now')"
  ).first<{ total: number }>();

  // Signups this month
  const monthRow = await env.DB.prepare(
    "SELECT COUNT(*) as total FROM signups WHERE strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now')"
  ).first<{ total: number }>();

  // Signups over time (last 30 days)
  const signups30d = await env.DB.prepare(
    `SELECT DATE(created_at) as day, COUNT(*) as count
     FROM signups WHERE created_at >= datetime('now', '-30 days')
     GROUP BY day ORDER BY day`
  ).all<{ day: string; count: number }>();

  return json({
    totals: {
      influencers: infRow?.total ?? 0,
      signups: sigRow?.total ?? 0,
      signupsToday: todayRow?.total ?? 0,
      signupsThisMonth: monthRow?.total ?? 0,
      revenueEstimate: (revRow?.total ?? 0) / 1_000_000,
      pendingPayouts: (payoutRow?.total ?? 0) / 1_000_000,
      premiumUsers: premiumRow?.premium_users ?? 0,
      subscriptionRevenue: (premiumRow?.total_revenue_cents ?? 0) / 100,
    },
    charts: {
      signupsOverTime: signups30d.results || [],
    },
  });
}

async function handleAdminInfluencers(request: Request, env: Env): Promise<Response> {
  const influencers = await env.DB.prepare(
    `SELECT rc.code, rc.influencer_id, rc.display_name, rc.share_percent,
            rc.active, rc.total_installs, rc.created_at,
            (SELECT COUNT(*) FROM signups s WHERE s.influencer_id = rc.influencer_id) as signups,
            (SELECT COALESCE(SUM(value_micros), 0) FROM ad_events ae WHERE ae.influencer_id = rc.influencer_id) as revenue_micros,
            (SELECT COUNT(DISTINCT user_id) FROM subscription_events se WHERE se.influencer_id = rc.influencer_id AND se.event_type IN ('purchase', 'renewal')) as premium_users,
            (SELECT COALESCE(SUM(amount_cents), 0) FROM subscription_events se WHERE se.influencer_id = rc.influencer_id AND se.event_type IN ('purchase', 'renewal')) as subscription_revenue_cents
     FROM referral_codes rc
     ORDER BY rc.created_at DESC`
  ).all<{
    code: string; influencer_id: string; display_name: string;
    share_percent: number; active: number; total_installs: number;
    created_at: string; signups: number; revenue_micros: number;
    premium_users: number; subscription_revenue_cents: number;
  }>();

  return json({
    influencers: (influencers.results || []).map(inf => ({
      code: inf.code,
      influencerId: inf.influencer_id,
      displayName: inf.display_name,
      sharePercent: inf.share_percent,
      active: !!inf.active,
      totalInstalls: inf.total_installs,
      signups: inf.signups,
      revenueEstimate: inf.revenue_micros / 1_000_000,
      earningsEstimate: (inf.revenue_micros / 1_000_000) * (inf.share_percent / 100),
      premiumUsers: inf.premium_users ?? 0,
      subscriptionRevenue: (inf.subscription_revenue_cents ?? 0) / 100,
      premiumConversionRate: inf.signups > 0
        ? Math.round(((inf.premium_users ?? 0) / inf.signups) * 10000) / 100
        : 0,
      createdAt: inf.created_at,
    })),
  });
}

async function handleAdminInfluencerDetail(request: Request, env: Env, influencerId: string): Promise<Response> {
  return handleInfluencerStats(request, env, influencerId);
}

async function handleAdminCreateCode(request: Request, env: Env): Promise<Response> {
  // Authenticate via admin session or ADMIN_SECRET
  const token = getTokenFromRequest(request);
  let isAdmin = false;
  if (token) {
    const session = await getSession(env, token);
    isAdmin = session?.userType === 'admin';
  }
  const adminKey = request.headers.get('X-Admin-Key');
  if (!isAdmin && adminKey !== env.ADMIN_SECRET) {
    return error('Unauthorized', 401);
  }

  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const code = uc(body.code || '');
  const influencerId = (body.influencerId || '').trim().toLowerCase().replace(/[^a-z0-9_-]/g, '');
  const displayName = (body.displayName || '').trim();
  const password = body.password || '';
  const sharePercent = body.sharePercent ?? 5;

  if (!code || !influencerId || !displayName || !password) {
    return error('Missing required fields: code, influencerId, displayName, password');
  }

  // Hash password
  const hash = await hashPassword(password);

  try {
    await env.DB.prepare(
      'INSERT INTO referral_codes (code, influencer_id, display_name, password_hash, share_percent) VALUES (?, ?, ?, ?, ?)'
    ).bind(code, influencerId, displayName, hash, sharePercent).run();
  } catch (e: any) {
    if (e.message?.includes('UNIQUE')) return error('Code or influencer ID already exists');
    throw e;
  }

  return json({ ok: true, code, influencerId, displayName });
}

async function handleAdminUpdateCode(request: Request, env: Env, code: string): Promise<Response> {
  const token = getTokenFromRequest(request);
  let isAdmin = false;
  if (token) {
    const session = await getSession(env, token);
    isAdmin = session?.userType === 'admin';
  }
  const adminKey = request.headers.get('X-Admin-Key');
  if (!isAdmin && adminKey !== env.ADMIN_SECRET) {
    return error('Unauthorized', 401);
  }

  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const updates: string[] = [];
  const params: any[] = [];

  if (body.active !== undefined) { updates.push('active = ?'); params.push(body.active ? 1 : 0); }
  if (body.sharePercent !== undefined) { updates.push('share_percent = ?'); params.push(body.sharePercent); }
  if (body.displayName) { updates.push('display_name = ?'); params.push(body.displayName); }
  if (body.password) {
    updates.push('password_hash = ?');
    params.push(await hashPassword(body.password));
  }

  if (!updates.length) return error('No fields to update');

  params.push(uc(code));
  await env.DB.prepare(
    `UPDATE referral_codes SET ${updates.join(', ')} WHERE code = ?`
  ).bind(...params).run();

  return json({ ok: true });
}

async function handleAdminPayouts(request: Request, env: Env): Promise<Response> {
  const payouts = await env.DB.prepare(
    `SELECT p.*, rc.display_name
     FROM payouts p
     LEFT JOIN referral_codes rc ON p.influencer_id = rc.influencer_id
     ORDER BY p.month DESC, p.created_at DESC`
  ).all<{
    id: number; influencer_id: string; month: string; share_percent: number;
    total_signups: number; ad_revenue_micros: number; payout_micros: number;
    paid: number; paid_at: string | null; notes: string | null; display_name: string | null;
  }>();

  // Compute pending for current month
  const currentMonth = new Date().toISOString().slice(0, 7);
  const pending = await env.DB.prepare(
    `SELECT rc.influencer_id, rc.display_name, rc.share_percent,
            (SELECT COUNT(*) FROM signups s WHERE s.influencer_id = rc.influencer_id
             AND strftime('%Y-%m', s.created_at) = ?) as month_signups,
            (SELECT COALESCE(SUM(value_micros), 0) FROM ad_events ae WHERE ae.influencer_id = rc.influencer_id
             AND strftime('%Y-%m', ae.created_at) = ?) as month_revenue_micros
     FROM referral_codes rc WHERE rc.active = 1`
  ).bind(currentMonth, currentMonth).all<{
    influencer_id: string; display_name: string; share_percent: number;
    month_signups: number; month_revenue_micros: number;
  }>();

  return json({
    payouts: (payouts.results || []).map(p => ({
      id: p.id,
      influencerId: p.influencer_id,
      displayName: p.display_name,
      month: p.month,
      sharePercent: p.share_percent,
      totalSignups: p.total_signups,
      revenueReconciled: p.ad_revenue_micros / 1_000_000,
      payoutAmount: p.payout_micros / 1_000_000,
      paid: !!p.paid,
      paidAt: p.paid_at,
      notes: p.notes,
    })),
    pendingThisMonth: (pending.results || []).map(p => ({
      influencerId: p.influencer_id,
      displayName: p.display_name,
      sharePercent: p.share_percent,
      signups: p.month_signups,
      revenueEstimate: p.month_revenue_micros / 1_000_000,
      earningsEstimate: (p.month_revenue_micros / 1_000_000) * (p.share_percent / 100),
    })),
  });
}

async function handleAdminReconcile(request: Request, env: Env): Promise<Response> {
  const token = getTokenFromRequest(request);
  let isAdmin = false;
  if (token) {
    const session = await getSession(env, token);
    isAdmin = session?.userType === 'admin';
  }
  const adminKey = request.headers.get('X-Admin-Key');
  if (!isAdmin && adminKey !== env.ADMIN_SECRET) {
    return error('Unauthorized', 401);
  }

  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  // Expects: { month: "2026-08", influencerId: "sarah_fit", revenueMicros: 15000000 }
  // Or batch: { month: "2026-08", reconciliations: [{influencerId, revenueMicros}, ...] }
  const month = body.month || new Date().toISOString().slice(0, 7);
  const reconciliations = body.reconciliations || [body];
  const results: any[] = [];

  for (const rec of reconciliations) {
    if (!rec.influencerId) continue;

    const profile = await env.DB.prepare(
      'SELECT share_percent FROM referral_codes WHERE influencer_id = ?'
    ).bind(rec.influencerId).first<{ share_percent: number }>();
    if (!profile) {
      results.push({ influencerId: rec.influencerId, error: 'not_found' });
      continue;
    }

    const revenueMicros = rec.revenueMicros || 0;
    const sharePercent = profile.share_percent;
    const payoutMicros = Math.round(revenueMicros * (sharePercent / 100));

    // Get signup count for the month
    const signupRow = await env.DB.prepare(
      `SELECT COUNT(*) as cnt FROM signups WHERE influencer_id = ?
       AND strftime('%Y-%m', created_at) = ?`
    ).bind(rec.influencerId, month).first<{ cnt: number }>();

    // Upsert payout record
    const existing = await env.DB.prepare(
      'SELECT id FROM payouts WHERE influencer_id = ? AND month = ?'
    ).bind(rec.influencerId, month).first<{ id: number }>();

    if (existing) {
      await env.DB.prepare(
        'UPDATE payouts SET ad_revenue_micros = ?, payout_micros = ?, total_signups = ? WHERE id = ?'
      ).bind(revenueMicros, payoutMicros, signupRow?.cnt ?? 0, existing.id).run();
    } else {
      await env.DB.prepare(
        'INSERT INTO payouts (influencer_id, month, share_percent, total_signups, ad_revenue_micros, payout_micros) VALUES (?, ?, ?, ?, ?, ?)'
      ).bind(rec.influencerId, month, sharePercent, signupRow?.cnt ?? 0, revenueMicros, payoutMicros).run();
    }

    results.push({
      influencerId: rec.influencerId,
      sharePercent,
      revenueReconciled: revenueMicros / 1_000_000,
      payoutAmount: payoutMicros / 1_000_000,
    });
  }

  return json({ ok: true, month, results });
}

async function handleAdminMarkPaid(request: Request, env: Env): Promise<Response> {
  const token = getTokenFromRequest(request);
  let isAdmin = false;
  if (token) {
    const session = await getSession(env, token);
    isAdmin = session?.userType === 'admin';
  }
  const adminKey = request.headers.get('X-Admin-Key');
  if (!isAdmin && adminKey !== env.ADMIN_SECRET) {
    return error('Unauthorized', 401);
  }

  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const payoutId = body.payoutId;
  if (!payoutId) return error('Missing payoutId');

  await env.DB.prepare(
    "UPDATE payouts SET paid = 1, paid_at = datetime('now') WHERE id = ?"
  ).bind(payoutId).run();

  // Update last_payout_at on the referral code
  await env.DB.prepare(
    `UPDATE referral_codes SET last_payout_at = datetime('now')
     WHERE influencer_id = (SELECT influencer_id FROM payouts WHERE id = ?)`
  ).bind(payoutId).run();

  return json({ ok: true });
}

async function handleAdminFraudCheck(request: Request, env: Env): Promise<Response> {
  // Detect anomalies: burst signups, zero retention, low D7
  const anomalies: any[] = [];

  // Burst signups (>50 in 1 hour)
  const bursts = await env.DB.prepare(
    `SELECT code, influencer_id, COUNT(*) as cnt,
            MIN(created_at) as start, MAX(created_at) as end
     FROM signups
     WHERE created_at >= datetime('now', '-7 days')
     GROUP BY code
     HAVING COUNT(*) > 50
       AND (julianday(MAX(created_at)) - julianday(MIN(created_at))) * 24 < 1
     ORDER BY cnt DESC`
  ).all<{ code: string; influencer_id: string; cnt: number; start: string; end: string }>();

  for (const b of bursts.results || []) {
    anomalies.push({ code: b.code, influencerId: b.influencer_id, type: 'burst', detail: `${b.cnt} signups in <1 hour` });
  }

  // Low D7 retention (<10%) for codes with significant signups
  const allCodes = await env.DB.prepare(
    'SELECT code, influencer_id FROM referral_codes WHERE total_installs > 20'
  ).all<{ code: string; influencer_id: string }>();

  for (const c of allCodes.results || []) {
    const retentionResult = await env.DB.prepare(
      `SELECT s.install_id,
              (SELECT COUNT(DISTINCT date) FROM daily_pings dp WHERE dp.install_id = s.install_id) as active_days
       FROM signups s WHERE s.influencer_id = ?
       AND s.created_at <= datetime('now', '-7 days')
       LIMIT 100`
    ).bind(c.influencer_id).all<{ install_id: string; active_days: number }>();

    const total = retentionResult.results?.length ?? 0;
    if (total > 10) {
      const active = retentionResult.results?.filter(r => (r.active_days ?? 0) >= 7).length ?? 0;
      const retentionRate = active / total;
      if (retentionRate < 0.1) {
        anomalies.push({
          code: c.code, influencerId: c.influencer_id,
          type: 'low_retention',
          detail: `${Math.round(retentionRate * 100)}% D7 retention (${active}/${total})`,
        });
      }
    }
  }

  return json({ anomalies });
}

async function handleAdminLogout(request: Request, env: Env): Promise<Response> {
  const token = getTokenFromRequest(request);
  if (token) {
    await env.DB.prepare('DELETE FROM sessions WHERE token = ?').bind(token).run();
  }
  return json({ ok: true });
}

// ══════════════════════════════════════════════════════════════════
// SEED: Create initial admin user (protected by ADMIN_SECRET)
// ══════════════════════════════════════════════════════════════════

async function handleSeed(request: Request, env: Env): Promise<Response> {
  const adminKey = request.headers.get('X-Admin-Key') || request.headers.get('X-Seed-Key');
  const secret = env.ADMIN_SECRET || env.SEED_KEY;
  if (!secret || adminKey !== secret) return error('Unauthorized', 401);

  let body: any;
  try { body = await request.json(); } catch { return error('Invalid JSON'); }

  const results: string[] = [];
  const username = body.username || body.adminUsername;
  const password = body.password || body.adminPassword;

  // Create admin user if not exists
  if (username && password) {
    const hash = await hashPassword(password);
    try {
      await env.DB.prepare('INSERT INTO admin_users (username, password_hash) VALUES (?, ?)')
        .bind(username, hash).run();
      results.push(`Admin user '${username}' created`);
    } catch (e: any) {
      results.push(`Failed to create admin user: ${e.message}`);
    }
  }

  return json({ ok: true, results });
}

// ══════════════════════════════════════════════════════════════════
// ROUTER
// ══════════════════════════════════════════════════════════════════

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    try {
      // ── Public routes ──
      if (path === '/v1/validate' && method === 'GET') return handleValidate(request, env);

      if (path === '/v1/events/signup' && method === 'POST') return handleSignup(request, env);
      if (path === '/v1/events/ad' && method === 'POST') return handleAdEvents(request, env);
      if (path === '/v1/events/ping' && method === 'POST') return handlePing(request, env);
      if (path === '/v1/events/subscription' && method === 'POST') return handleSubscriptionEvent(request, env);

      // ── Influencer routes ──
      if (path === '/v1/influencer/login' && method === 'POST') return handleInfluencerLogin(request, env);
      if (path === '/v1/influencer/logout' && method === 'POST') return handleInfluencerLogout(request, env);

      if (path === '/v1/influencer/stats' && method === 'GET') {
        const token = getTokenFromRequest(request);
        if (!token) return error('Unauthorized', 401);
        const session = await getSession(env, token);
        if (!session || session.userType !== 'influencer') return error('Unauthorized', 401);
        return handleInfluencerStats(request, env, session.userId);
      }

      if (path === '/v1/influencer/settings' && method === 'GET') {
        const token = getTokenFromRequest(request);
        if (!token) return error('Unauthorized', 401);
        const session = await getSession(env, token);
        if (!session || session.userType !== 'influencer') return error('Unauthorized', 401);
        return handleInfluencerSettings(request, env, session.userId);
      }

      // ── Admin routes ──
      if (path === '/v1/admin/login' && method === 'POST') return handleAdminLogin(request, env);
      if (path === '/v1/admin/logout' && method === 'POST') return handleAdminLogout(request, env);

      if (path === '/v1/admin/dashboard' && method === 'GET') {
        const token = getTokenFromRequest(request);
        if (!token) return error('Unauthorized', 401);
        const session = await getSession(env, token);
        if (!session || session.userType !== 'admin') return error('Unauthorized', 401);
        return handleAdminDashboard(request, env);
      }

      if (path === '/v1/admin/influencers' && method === 'GET') {
        const token = getTokenFromRequest(request);
        if (!token) return error('Unauthorized', 401);
        const session = await getSession(env, token);
        if (!session || session.userType !== 'admin') return error('Unauthorized', 401);
        return handleAdminInfluencers(request, env);
      }

      if (path.startsWith('/v1/admin/influencer/') && method === 'GET') {
        const token = getTokenFromRequest(request);
        if (!token) return error('Unauthorized', 401);
        const session = await getSession(env, token);
        if (!session || session.userType !== 'admin') return error('Unauthorized', 401);
        const influencerId = path.slice('/v1/admin/influencer/'.length);
        return handleAdminInfluencerDetail(request, env, influencerId);
      }

      if (path === '/v1/admin/codes' && method === 'POST') return handleAdminCreateCode(request, env);
      if (path.startsWith('/v1/admin/codes/') && method === 'PATCH') {
        const code = uc(path.slice('/v1/admin/codes/'.length));
        return handleAdminUpdateCode(request, env, code);
      }

      if (path === '/v1/admin/payouts' && method === 'GET') {
        const token = getTokenFromRequest(request);
        if (!token) return error('Unauthorized', 401);
        const session = await getSession(env, token);
        if (!session || session.userType !== 'admin') return error('Unauthorized', 401);
        return handleAdminPayouts(request, env);
      }

      if (path === '/v1/admin/payouts/reconcile' && method === 'POST') return handleAdminReconcile(request, env);
      if (path === '/v1/admin/payouts/mark-paid' && method === 'POST') return handleAdminMarkPaid(request, env);

      if (path === '/v1/admin/fraud' && method === 'GET') {
        const token = getTokenFromRequest(request);
        if (!token) return error('Unauthorized', 401);
        const session = await getSession(env, token);
        if (!session || session.userType !== 'admin') return error('Unauthorized', 401);
        return handleAdminFraudCheck(request, env);
      }

      // ── Seed (one-time, guarded) ──
      if (path === '/v1/admin/seed' && method === 'POST') return handleSeed(request, env);

      // ── Not found ──
      return error('Not found', 404);
    } catch (e: any) {
      console.error('Worker error:', e.message);
      return error(`Internal error: ${e.message}`, 500);
    }
  },
};
