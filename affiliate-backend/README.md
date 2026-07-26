# GetTaller Affiliate Backend — Deploy Guide

Architecture: **Cloudflare Workers + D1** (SQLite-compatible). Zero server cost, fits on the $0 free tier.

## Prerequisites

- [Node.js](https://nodejs.org/) 18+ installed locally
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/): `npm install -g wrangler`
- Cloudflare account with Workers subscription (free)
- The `studios.grayonix.com` domain (or your own domain) — DNS managed by Cloudflare

---

## Step 1: Authenticate Wrangler

```bash
wrangler login
```

Opens a browser. Authorize the Cloudflare account that owns the domain.

---

## Step 2: Create the D1 Database

```bash
cd affiliate-backend
wrangler d1 create gettaller-affiliate
```

This returns a database ID — copy it. Open `wrangler.toml` and paste it as the value of `[[d1_databases]]` → `database_id`.

---

## Step 3: Initialize the Schema

```bash
wrangler d1 execute gettaller-affiliate --file=schema.sql
```

Verify tables were created:

```bash
wrangler d1 execute gettaller-affiliate --command=".tables"
```

Expected output: `ad_events admin_users daily_pings payouts referral_codes sessions signups`

---

## Step 4: Create Your Admin Account

Because the Worker uses a custom high-security PBKDF2 hash (not standard bcrypt), you **MUST** create your admin user using the secure seed endpoint.

1. **Set a SEED_KEY secret**:
```bash
wrangler secret put SEED_KEY
```
*(Enter a long random string when prompted)*

2. **Deploy the Worker** (see Step 6).

3. **Call the Seed Endpoint**:
```bash
curl -X POST https://YOUR_WORKER.workers.dev/v1/admin/seed \
  -H 'Content-Type: application/json' \
  -H 'X-Seed-Key: YOUR_SEED_KEY' \
  -d '{"username":"admin","password":"YOUR_SECURE_PASSWORD"}'
```

Alternatively, if you prefer manual D1 execution, you must generate the hash using the worker's logic first.

---

## Step 5: Configure Secrets

```bash
# Session secret — a random 64-character string
wrangler secret put SESSION_SECRET

# A secret key for the /v1/admin/seed endpoint (only if you use it)
wrangler secret put SEED_KEY
```

Generate secure random values:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
# Copy the output, use for SESSION_SECRET
```

---

## Step 6: Deploy the Worker

```bash
cd affiliate-backend
npm run deploy
```

This runs `wrangler deploy` and publishes the worker to your workers.dev subdomain (or custom domain if configured in `wrangler.toml`).

Test that the worker is live:

```bash
# Health check
curl https://gettaller-affiliate.YOUR_SUBDOMAIN.workers.dev/v1/validate?code=TEST
# Should return: {"valid":false}
```

---

## Step 7: Create Your First Influencer

Login to the admin dashboard at `https://studios.grayonix.com/admin/login.html`

Or via API:

```bash
# Login as admin
curl -X POST https://gettaller-affiliate.YOUR_SUBDOMAIN.workers.dev/v1/admin/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"YOUR_ADMIN_PASSWORD"}'

# Use the returned token
TOKEN="the-session-token-from-response"

# Create an influencer
curl -X POST https://gettaller-affiliate.YOUR_SUBDOMAIN.workers.dev/v1/admin/codes \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer TOKEN' \
  -d '{"code":"TEST10","influencerId":"test_user","displayName":"Test User","sharePercent":5,"password":"influencer123"}'
```

---

## Step 9: Deploy Dashboard Pages

The `dashboard/` and `admin/` directories are static HTML/CSS/JS. Deploy them to Cloudflare Pages:

```bash
# Option A: Deploy as a Pages project
npx wrangler pages deploy ./dashboard --project-name=gettaller-dashboard
npx wrangler pages deploy ./admin --project-name=gettaller-admin

# Option B: Serve from the Worker itself (modify worker.ts to serve static assets)
# This is NOT implemented yet — use Option A or serve via a separate Pages deployment.
```

> **Note:** The HTML pages call relative API paths (`/v1/influencer/login` etc.) which must resolve to the Worker. If the Worker is on a different domain, set `window.API_BASE` before loading the app:
> ```html
> <script>window.API_BASE = 'https://gettaller-affiliate.YOUR_SUBDOMAIN.workers.dev';</script>
> ```

---

## Step 10: Domain Setup (Optional)

To serve everything from `studios.grayonix.com`:

1. In Cloudflare Dashboard → Workers & Pages → your Worker → Triggers → Custom Domain: add `studios.grayonix.com`
2. In Cloudflare Pages → your project → Custom domains: add `studios.grayonix.com/dashboard` and `studios.grayonix.com/admin` (or use a different URL structure)
3. Update DNS records at your registrar to point at Cloudflare nameservers.

---

## Testing the Full Flow

### 1. Validate a code
```bash
curl "https://YOUR_WORKER.workers.dev/v1/validate?code=TEST10"
# → {"valid":true,"sharePercent":5,"influencerId":"test_user"}
```

### 2. Case-insensitive test
```bash
curl "https://YOUR_WORKER.workers.dev/v1/validate?code=test10"
# → {"valid":true,"sharePercent":5}  (same result — uppercased on server)
```

### 3. Log a signup
```bash
curl -X POST https://YOUR_WORKER.workers.dev/v1/events/signup \
  -H 'Content-Type: application/json' \
  -d '{"installId":"test-device-001","code":"TEST10","country":"US","platform":"android","appVersion":"2.0.0"}'
# → {"ok":true}
```

### 4. Log ad revenue
```bash
curl -X POST https://YOUR_WORKER.workers.dev/v1/events/ad \
  -H 'Content-Type: application/json' \
  -d '{"events":[{"installId":"test-device-001","code":"TEST10","adFormat":"banner","valueMicros":1500000,"currency":"USD","precision":0}]}'
# → {"ok":true}
```

### 5. Daily ping
```bash
curl -X POST https://YOUR_WORKER.workers.dev/v1/events/ping \
  -H 'Content-Type: application/json' \
  -d '{"installId":"test-device-001","code":"TEST10"}'
# → {"ok":true,"retentionDay":1}
```

### 6. Influencer login & dashboard
```bash
curl -X POST https://YOUR_WORKER.workers.dev/v1/influencer/login \
  -H 'Content-Type: application/json' \
  -d '{"code":"TEST10","password":"influencer123"}'
# → {"token":"...","influencer":{"displayName":"Test User","code":"TEST10","sharePercent":5}}
```

---

## Architecture Overview

```
studios.grayonix.com
├── /dashboard/          → Cloudflare Pages (influencer portal)
│   ├── login.html          Log in with code + password
│   ├── index.html          Stats, charts, retention
│   ├── settings.html       Profile, payout history
│   ├── styles.css          Shared design system
│   └── app.js              Shared JS library
├── /admin/              → Cloudflare Pages (admin portal)
│   ├── login.html          Admin login
│   ├── index.html          Overview, influencer table
│   ├── influencer.html     Deep dive: stats, fraud flags, signups
│   ├── payouts.html        Payout queue + reconciliation
│   ├── add-influencer.html Create new influencer
│   ├── styles.css          Admin-specific styles
│   └── app.js              Admin-specific JS
└── /v1/*                → Cloudflare Worker
    ├── /validate            Public: check a code
    ├── /events/*            Public: log signups, ads, pings
    ├── /influencer/*        Auth: login, stats, settings
    └── /admin/*             Auth: dashboard, codes, payouts, fraud
```

---

## Monthly Payout Workflow

1. **End of month**: Export AdMob actual revenue by referral code period.
2. **Login to admin** → Payouts page → "Start Reconciliation".
3. **Paste JSON**: `{"month":"2026-08","revenues":{"CODE1":150000000,"CODE2":85000000}}` (values in micros).
4. **Compute**: System applies share% and duration limits, creates payout records.
5. **Verify**: Check the computed amounts against your AdMob report.
6. **Pay out**: Send via PayPal/Wise/Stripe Connect, then click "Mark Paid".

---

## Fraud Detection

The `GET /v1/admin/fraud` endpoint scans for:

- **Burst signups**: >50 signups in 1 hour from a single code
- **Zero-retention users**: Signed up but never opened the app again
- **Low D7 cohort**: <10% retention at day 7 (suggests bot traffic)

Suspect influencers are flagged on the admin dashboard with severity levels.

---

## Cost Breakdown

| Service | Free Tier | Expected Usage | Cost |
|---------|-----------|---------------|------|
| Cloudflare Workers | 100k requests/day | < 10k/day | $0 |
| D1 (SQLite) | 5 GB storage, 5M reads/day | < 1 GB, < 50k reads | $0 |
| Cloudflare Pages | Unlimited static sites | 2 sites | $0 |
| **Total** | | | **$0/month** |

---

## Troubleshooting

### Worker returns 404 for API routes
- Check `wrangler.toml` routes configuration. The `routes` block must match your domain.
- Ensure the worker is deployed (`wrangler deploy`).
- Verify D1 binding name matches `AFFILIATE_DB` in both `wrangler.toml` and `src/worker.ts`.

### D1 query returns "no such table"
- Run `wrangler d1 execute gettaller-affiliate --file=schema.sql` again.
- Check the database name matches.

### Login fails with "invalid credentials"
- Verify the influencer account exists: `wrangler d1 execute gettaller-affiliate --command="SELECT * FROM referral_codes"`
- Password verification uses bcrypt. Ensure the stored hash matches bcrypt format (`$2a$...` or `$2b$...`).

### Dashboard pages can't reach the API
- CORS headers are set on all Worker responses. Check browser console for CORS errors.
- If using a custom domain on Pages but the Worker is on workers.dev, set `window.API_BASE`.
