# GetTaller Discord MVC — Setup Guide

## Server Name: GetTaller Inner Circle
## Server Theme: Dark purple + accent (#6C63FF)

---

## CHANNEL STRUCTURE

### Category 1: 📋 INFORMATION (read-only for @everyone)

| Channel | Purpose |
|---------|---------|
| `#rules` | Server rules + link to Privacy Policy / Medical Disclaimer |
| `#announcements` | Only @Admin can post — launch date, milestone updates |
| `#roles` | Self-serve role assignment via bot reactions |
| `#welcome` | Auto-generated welcome message with @EarlyAdopter role |

**Rules content:**
1. Be respectful — height is a sensitive topic for many
2. No medical advice — everything here is educational, consult a doctor
3. No spam or self-promotion
4. Bug reports go in #feedback-beta with template
5. Keep DMs appropriate — harassment = instant ban
6. What happens in Beta stays in Beta (embargo until launch)

### Category 2: 👋 COMMUNITY

| Channel | Purpose |
|---------|---------|
| `#introductions` | New members post: name, age, height goal, why they joined |
| `#general-chat` | Daily discussion, progress pics (clothed only), motivation |
| `#progress-journey` | Before/after measurements, streak brags, 90-day updates |
| `#nutrition-logs` | Share meals, recipes, calcium/protein hacks |
| `#workout-talk` | Exercise form checks, which exercises hit hardest, schedule sharing |
| `#off-topic` | Non-height stuff — games, music, whatever |

### Category 3: 🐛 FEEDBACK & DEVELOPMENT

| Channel | Purpose |
|---------|---------|
| `#feedback-beta` | Structured bug reports — must use template |
| `#suggestions` | Feature ideas — one per message, voted with reactions |
| `#changelog` | Auto-posted updates from GitHub when changes ship |
| `#dev-qa` | Ask dev questions — "Why does the calculator do X?" "Can we add Y?" |

**Bug report template:**
```
**Device:** [Phone model + OS version]
**App Version:** [1.0.0+16]
**What happened:** [Describe]
**Steps to reproduce:** [1. 2. 3.]
**Expected:** [What should happen]
**Screenshot:** [link]
```

### Category 4: 🚀 LAUNCH SQUAD (hidden until 1 week before launch)

| Channel | Purpose |
|---------|---------|
| `#launch-strategy` | Discuss the mass-download plan |
| `#review-copies` | Coordinate Google Play reviews |
| `#ambassador-kit` | Shareable graphics, copy-paste posts for X/Instagram |

### Category 5: 🎙️ VOICE (optional, text-first alternative below)

| Channel | Purpose |
|---------|---------|
| `#town-hall` | Text-based AMA thread (async, more engagement than voice for teens) |
| `General Voice` | Voice channel for co-working / workout sessions |

---

## ROLE STRUCTURE & PERMISSIONS

### Base Roles

| Role | Color | Criteria | Permissions |
|------|-------|----------|-------------|
| `@Newcomer` | Grey | Just joined | See #rules, #introductions, #general-chat only |
| `@Member` | Light Blue | Posted intro + 1 day old | Full access except #launch-squad |
| `@EarlyAdopter` | Purple (#6C63FF) | First 200 members | Exclusive role color, special badge |
| `@BetaTester` | Orange | Reported 1+ verified bug | Access to #beta-testers-only chat |
| `@Contributor` | Gold | 3+ suggestions implemented or exceptional feedback | Mentionable, special channel |
| `@LaunchAmbassador` | Red | Selected for launch-day coordination | Access to #launch-squad |
| `@Admin` | Cyan | You | Everything |

### Gamification Mechanics

- **EarlyAdopter (first 200):** Scarcity — "only X spots left" counter in welcome message
- **BetaTester promotion:** Every verified bug report = closer to BetaTester. Manual promotion by you.
- **Contributor is the holy grail:** When a user's suggestion gets built, they get Contributor + a shoutout in #changelog. This is your most powerful retention tool.
- **Weekly MVP award:** Each week, one member gets "@Member of the Week" temporary role + shoutout

---

## BOT SETUP

### Required Bots

1. **Carl-bot** (or MEE6) — Moderation, auto-roles, logging
   - Auto-assign @Newcomer on join
   - Delete invites from competitors
   - Log deleted messages

2. **Sesh** — Event scheduling
   - Weekly Q&A sessions
   - Workout challenges
   - Launch countdown

3. **GitHub Webhook** (built-in Discord integration)
   - Connect to your repo
   - `#changelog` gets commits + PRs automatically
   - Tag specific keywords to close suggestions

4. **Reaction Role Bot** (Carl-bot can do this)
   - `#roles` channel with emoji buttons
   - 🎮 → @PingForGameNights
   - 📢 → @PingForAnnouncements

### Bot Permission Checklist

- [ ] Carl-bot: Manage Roles, Read Messages, Send Messages, Manage Messages, Kick
- [ ] Sesh: Create Events, Read Messages, Send Messages
- [ ] GitHub: Read Messages, Send Messages (limited to #changelog)

---

## MODERATION RULES

- **Strike system:** 3 strikes = ban
  - Strike 1: Warning + DM from bot
  - Strike 2: 24-hour mute
  - Strike 3: Permanent ban
- **Zero tolerance:** Hate speech, harassment, doxxing = instant ban
- **Medical claims:** If someone says "this exercise made me grow 2 inches in a week", delete and remind them results take consistency. CYA.
