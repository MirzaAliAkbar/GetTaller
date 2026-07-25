# GetTaller — Affiliate System (Technical & Operational Spec)

> Internal document. The creator-facing pitch lives in `INFLUENCER_AFFILIATE_PROGRAM.md`.
> This file describes **how the program actually works in our app and backend** — what
> we build, what we track, and how we see the numbers. Payment/commission terms are
> unchanged from the program doc and summarized in the Reference Card below.

---

## 1. Design Goals

1. **Add a new influencer without shipping an app update.** Codes are data, not code.
2. **No expensive attribution vendor to start.** Manual code entry, not deep-link/fingerprint.
3. **Attribute both ad revenue and (future) subscription revenue to the referring influencer.**
4. **See per-influencer analytics** without hand-scanning raw logs.
5. **Pay out on reconciled numbers, not live estimates.**

---

## 2. Current Stack (what exists today)

| Area | Status |
|------|--------|
| Firebase Core / Analytics / Crashlytics / Remote Config | ✅ in app |
| AdMob + mediation (AppLovin / Unity) via `lib/core/ads/ad_service.dart` | ✅ in app (mediation activation deferred until publish) |
| Firestore | ❌ not added yet — **required** for this system |
| Firebase Auth (or anonymous user id) | ❌ not added yet — **required** for stable per-user attribution |
| RevenueCat / in-app purchases | ❌ not added yet — only needed once subscriptions exist |
| Deep-link / attribution SDK (Branch, AppsFlyer) | ❌ intentionally skipped for v1 |

**v1 scope = manual referral code + Firestore + AdMob paid-event logging.** Subscription
attribution is stubbed until an IAP layer exists.

---

## 3. Referral Code Mechanic (no app update per influencer)

### 3.1 Code registry (Firestore)
Collection `referral_codes/{CODE}`:
```
{
  influencerId: "sarah_fit",
  sharePercent: 5,          // current tier; updated when they hit 5K milestone
  active: true,
  createdAt: <timestamp>,
  totalInstalls: 0          // lifetime, drives the 5% -> 20% milestone
}
```
Adding an influencer = create one document (admin script / console). **Zero app releases.**

### 3.2 Entry point in the app
- One optional onboarding field: **"Have a referral code?"** (e.g. `SARAH20`).
- App validates it against `referral_codes` at runtime (direct Firestore read or a
  `validateCode` Cloud Function). Invalid/inactive → soft error, onboarding continues.
- Codes are case-insensitive; store and compare uppercased.

### 3.3 Attribution write (on successful signup)
- Write `referredBy: CODE` + `influencerId` to the user profile doc `users/{userId}`.
- Append a ledger record `events_signups/{autoId}`:
  ```
  { userId, code, influencerId, timestamp, country, appVersion }
  ```
- Attribution is **first-code-wins** and permanent for that user (matches the "revenue
  share duration per referred user" terms). Duration windows (3mo / 12mo) are enforced
  at rollup time by comparing event timestamp to the user's signup date.

### 3.4 Deferred to Phase 2: trackable / deep links
A link like `gettaller.app/ref/CREATORNAME` that auto-fills the code and survives a fresh
install (deferred deep linking) needs Branch.io or AppsFlyer — Firebase Dynamic Links was
shut down in 2025. **This is explicitly Phase 2** (see §10). It's the expensive/complex
part and it's not worth the build until manual-entry drop-off is proven to cost real money.

For v1 the creator just puts "use code X" in their bio/video — standard promo-code pattern.
A plain vanity redirect (link → App Store) can be served for free from our own domain via
Cloudflare, but note: **a plain redirect does not carry the code into the installed app** —
that still requires the Phase 2 attribution SDK. So in v1 the code is always typed by hand.

---

## 4. Revenue Attribution

### 4.1 Ad revenue (v1, live)
- AdMob's `onPaidEvent` (a.k.a. paid-event listener) fires an **estimated** revenue value
  per impression. Hook it in `ad_service.dart` for every ad format (banner, interstitial,
  rewarded, native).
- On each event, look up the user's `influencerId` and append `events_ad_revenue/{autoId}`:
  ```
  { userId, influencerId, adUnit, network, valueMicros, currency, timestamp }
  ```
- `valueMicros / 1e6` = revenue for that impression in `currency`.

> ⚠️ These are **estimates**. AdMob's real payable revenue is finalized at the account
> level ~24–48h later and can differ 10–20%. See §6.

### 4.2 Subscription revenue (later, when IAP exists)
- Set the referral code as a RevenueCat subscriber attribute at signup.
- RevenueCat webhook → Cloud Function → `events_subscriptions/{autoId}`:
  ```
  { userId, influencerId, type, amount, currency, timestamp }  // initial/renewal/cancel/refund
  ```
- Refund/chargeback events subtract from the influencer's attributed revenue (clawback).

---

## 5. Aggregation & Analytics (how we "see" it)

### 5.1 Rollup
Scheduled Cloud Function (hourly or nightly) folds raw events into per-influencer summaries
`influencer_stats/{influencerId}/daily/{YYYY-MM-DD}`:
```
{
  signups: 42,
  activeUsers: 380,            // cumulative, still active
  adRevenueEstimate: 18.40,
  subscriptionRevenue: 0.00,   // until IAP ships
  revenuePerUser: 0.30,        // our "eCPM per referred user" proxy
  payoutOwedEstimate: 0.92     // (adRev + subRev) * sharePercent, within duration window
}
```
Rollup also updates `referral_codes/{CODE}.totalInstalls` and flips `sharePercent`
5 → 20 when lifetime installs cross 5,000 (extends duration 3mo → 12mo per terms).

### 5.2 Dashboard — recommended: BigQuery + Looker Studio
- Firebase extension **"Stream Firestore to BigQuery"** exports events + rollups (free tier
  covers our volume).
- **Looker Studio** (free) connects to BigQuery for a pivotable dashboard: filter by
  influencer + date range; charts for signups, retention, revenue, payout.
- Shareable via link — can hand an influencer a view of only their own numbers.
- No app to build or host. This is the v1 dashboard.

Alternatives (defer): a custom password-protected admin page under `studios.grayonix.com`
(more control, per-influencer logins, but a real build/maintain surface), or a Sheets dump
for the first handful of influencers.

### 5.3 Metrics that actually matter
- **Signups over time** — did their post spike installs.
- **Retention (D7/D30/D90)** — raw signups mislead; a bot-ish audience shows installs, no retention.
- **Revenue attributed + payout owed** — the number that decides who we keep paying.
- **Revenue per user** — quality, not just volume; a niche creator can beat a big one here.

---

## 6. Estimated vs Reconciled (payout safety)

- Dashboard shows two figures wherever money moves: **Estimated (live)** and
  **Reconciled (finalized)**.
- Ad payouts are computed from AdMob's actual account-level report (~24–48h delayed),
  **not** the live `onPaidEvent` estimates. Estimates are for trend/dashboards only.
- Monthly payout run: reconcile → apply `sharePercent` and duration window → subtract
  refunds/fraud clawbacks → pay amounts ≥ $50 minimum (net-30).

---

## 7. Fraud / Clawback Handling

- Flag influencers whose signups have abnormally low D7 retention or bursty install
  patterns (bots / incentivized installs).
- Clawback = deduct fraudulent installs' attributed revenue at reconciliation, per terms.
- `referral_codes.active = false` disables a code instantly (no app update).

---

## 8. Build Checklist (v1)

- [ ] Add `cloud_firestore` + Auth (or anonymous uid) to the app.
- [ ] `referral_codes` collection + admin create script.
- [ ] Onboarding "Have a referral code?" field + runtime validation.
- [ ] Attribution writes: `users/{id}.referredBy`, `events_signups`.
- [ ] `onPaidEvent` listener in `ad_service.dart` → `events_ad_revenue`.
- [ ] Scheduled rollup Cloud Function → `influencer_stats`, milestone tier bump.
- [ ] Firestore → BigQuery export + Looker Studio dashboard.
- [ ] Monthly reconciliation + payout process doc.
- [ ] (Later) RevenueCat webhook → `events_subscriptions` when IAP ships.

---

## 9. Reference Card (terms — unchanged)

```
APP:        GetTaller — Height Growth Tracker & Coach
MODEL:      Free + Ads (AdMob); subscriptions TBD
COMMISSION: 5% start -> 20% at 5K lifetime installs
DURATION:   3 months per user (12 months after 5K milestone)
PAYOUT:     Monthly, net-30, $50 minimum (PayPal / Wise / Stripe Connect)
TRACKING:   Manual referral code (v1); links/deep-links deferred to Phase 2
ATTRIBUTION: First code wins, permanent per user
DASHBOARD:  BigQuery + Looker Studio (per-influencer)
```

---

## 10. Phase Plan

### Phase 1 (now) — manual code, $0 in fees
- Manual referral code typed at onboarding (§3).
- AdMob `onPaidEvent` revenue logging (§4.1).
- Firestore ledgers + nightly rollup (§5.1).
- **Dashboard:** Looker Studio on top of BigQuery export (§5.2), or a simple page
  hosted free on **Cloudflare Pages** reading the `influencer_stats` aggregates.
- Cost: **$0 in vendor fees.** Only cost is build/dev time. Cloudflare's free tier
  covers the vanity-redirect domain and any static dashboard hosting.

### Phase 2 (later) — link-based tracking & deep links
- Adopt **Branch.io** (free up to ~10K MAU) or AppsFlyer for deferred deep linking so a
  `gettaller.app/ref/NAME` link auto-applies the code through a fresh install.
- In-app deep-link routing to onboarding / education hub / specific exercises.
- Postback API for high-volume partners.
- Trigger to start Phase 2: manual-entry drop-off is measurably losing attributable
  installs, OR an influencer's volume justifies the integration effort.

> Note on Cloudflare: great for the **vanity redirect** and hosting a **static/edge
> dashboard** at $0 — but Cloudflare does **not** provide deferred deep linking (carrying
> the code into the app after an App Store install). That specific capability is what
> requires the Phase 2 MMP (Branch/AppsFlyer).
