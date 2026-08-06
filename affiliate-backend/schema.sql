-- GetTaller Affiliate Program — D1 Database Schema
-- Run: npx wrangler d1 execute gettaller-affiliate --file=schema.sql

-- ── Referral Codes (one doc per influencer) ──
CREATE TABLE IF NOT EXISTS referral_codes (
  code           TEXT PRIMARY KEY,          -- UPPERCASED: "SARAH20"
  influencer_id  TEXT UNIQUE NOT NULL,       -- slug: "sarah_fit"
  display_name   TEXT NOT NULL,              -- "Sarah Fit"
  password_hash  TEXT NOT NULL,              -- bcrypt for dashboard login
  share_percent  INTEGER NOT NULL DEFAULT 5, -- 5 or 20 (auto-flips at 5K)
  active         INTEGER NOT NULL DEFAULT 1, -- 0 = deactivated instantly
  total_installs INTEGER NOT NULL DEFAULT 0, -- lifetime counter
  created_at     TEXT NOT NULL DEFAULT (datetime('now')),
  last_payout_at TEXT                        -- ISO 8601, last reconciliation
);

-- ── Signup Attribution ──
CREATE TABLE IF NOT EXISTS signups (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  install_id     TEXT NOT NULL,              -- anonymous UUID from device
  code           TEXT NOT NULL,              -- uppercased code
  influencer_id  TEXT NOT NULL,
  country        TEXT,                       -- from CF geolocation
  platform       TEXT,                       -- "android" / "ios"
  app_version    TEXT,
  created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- First-code-wins: once attributed, permanent
CREATE UNIQUE INDEX IF NOT EXISTS idx_signups_install ON signups(install_id);

-- Speed up per-influencer queries
CREATE INDEX IF NOT EXISTS idx_signups_influencer ON signups(influencer_id, created_at);
CREATE INDEX IF NOT EXISTS idx_signups_code ON signups(code, created_at);

-- ── Ad Revenue Events (from onPaidEvent) ──
CREATE TABLE IF NOT EXISTS ad_events (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  install_id     TEXT NOT NULL,
  code           TEXT,
  influencer_id  TEXT NOT NULL,
  ad_format      TEXT NOT NULL,              -- "banner"|"interstitial"|"rewarded"|"native"
  value_micros   INTEGER NOT NULL,           -- AdMob estimate (1e6 = $1)
  currency       TEXT NOT NULL DEFAULT 'USD',
  precision      INTEGER NOT NULL DEFAULT 0, -- 0=estimated, 1=published, 2=precise
  created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_adevents_influencer ON ad_events(influencer_id, created_at);
CREATE INDEX IF NOT EXISTS idx_adevents_code ON ad_events(code, created_at);

-- ── Daily Retention Pings (referred users only) ──
CREATE TABLE IF NOT EXISTS daily_pings (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  install_id     TEXT NOT NULL,
  code           TEXT NOT NULL,
  date           TEXT NOT NULL,              -- YYYY-MM-DD
  created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- One ping per install per day
CREATE UNIQUE INDEX IF NOT EXISTS idx_pings_install_date ON daily_pings(install_id, date);
CREATE INDEX IF NOT EXISTS idx_pings_code_date ON daily_pings(code, date);

-- ── Reconciled Payouts ──
CREATE TABLE IF NOT EXISTS payouts (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  influencer_id    TEXT NOT NULL,
  month            TEXT NOT NULL,            -- "2026-08"
  share_percent    INTEGER NOT NULL,
  total_signups    INTEGER NOT NULL DEFAULT 0,
  ad_revenue_micros INTEGER NOT NULL DEFAULT 0, -- reconciled from AdMob report
  payout_micros    INTEGER NOT NULL DEFAULT 0,  -- after share%
  paid             INTEGER NOT NULL DEFAULT 0,
  paid_at          TEXT,
  notes            TEXT,
  created_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_payouts_influencer ON payouts(influencer_id, month);

-- ── Subscription Events ──
CREATE TABLE IF NOT EXISTS subscription_events (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id        TEXT NOT NULL,
  influencer_id  TEXT,
  referral_code  TEXT,
  event_type     TEXT NOT NULL CHECK (event_type IN ('purchase', 'renewal', 'cancel', 'expire')),
  product_id     TEXT NOT NULL,
  amount_cents   INTEGER NOT NULL,
  currency       TEXT NOT NULL DEFAULT 'USD',
  platform       TEXT NOT NULL DEFAULT 'android',
  created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_sub_user ON subscription_events(user_id);
CREATE INDEX IF NOT EXISTS idx_sub_influencer ON subscription_events(influencer_id);
CREATE INDEX IF NOT EXISTS idx_sub_event ON subscription_events(event_type);
CREATE INDEX IF NOT EXISTS idx_sub_date ON subscription_events(created_at);

-- ── Admin Users ──
CREATE TABLE IF NOT EXISTS admin_users (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  username       TEXT UNIQUE NOT NULL,
  password_hash  TEXT NOT NULL,              -- bcrypt
  created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ── Sessions ──
CREATE TABLE IF NOT EXISTS sessions (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  token          TEXT UNIQUE NOT NULL,
  user_type      TEXT NOT NULL,              -- "influencer" | "admin"
  user_id        TEXT NOT NULL,              -- influencer_id or admin username
  expires_at     TEXT NOT NULL,
  created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(token);
