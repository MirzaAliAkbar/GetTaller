# GetTaller — Feedback Pipeline

## How Feedback Flows (Discord → GitHub → App)

```
USER POSTS in #feedback-beta or #suggestions
         │
         ▼
YOU (or @Admin) REVIEWS daily
         │
         ├── Bug → Create GitHub Issue via webhook
         │         ├── Label: `bug`, `priority:high/med/low`
         │         └── Assign to yourself
         │
         ├── Suggestion → Create GitHub Issue via webhook
         │         ├── Label: `enhancement`
         │         └── Add to project board "Community Requests"
         │
         └── Quick fix (< 5 min) → Fix immediately
                   └── Post in #changelog: "Fixed [bug] — thanks @user!"
```

---

## GITHUB ISSUE TEMPLATES

### Bug Report (`.github/ISSUE_TEMPLATE/bug_report.md`)

```yaml
name: Bug Report
description: Found a bug in the beta?
title: "[Bug]: "
labels: [bug]
body:
  - type: input
    id: device
    attributes:
      label: Device
      placeholder: "Google Pixel 7, Android 14"
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: App Version
      placeholder: "1.0.0+16"
    validations:
      required: true
  - type: textarea
    id: description
    attributes:
      label: What happened?
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      placeholder: "1. Go to... 2. Tap... 3. See error"
    validations:
      required: true
  - type: dropdown
    id: priority
    attributes:
      label: Priority
      options:
        - App crashes
        - Feature broken
        - Minor issue
        - Polish/UI
    validations:
      required: true
  - type: input
    id: discord
    attributes:
      label: Discord Username
      description: So I can credit you when it's fixed
```

### Feature Suggestion (`.github/ISSUE_TEMPLATE/feature_request.md`)

```yaml
name: Feature Suggestion
description: Idea for GetTaller
title: "[Suggestion]: "
labels: [enhancement]
body:
  - type: textarea
    id: problem
    attributes:
      label: What problem does this solve?
      placeholder: "I wish I could..."
    validations:
      required: true
  - type: textarea
    id: solution
    attributes:
      label: Your idea
    validations:
      required: true
  - type: dropdown
    id: scope
    attributes:
      label: Effort estimate
      options:
        - Quick win (< 1hr)
        - Moderate (1 day)
        - Major feature (1+ week)
    validations:
      required: true
  - type: input
    id: discord
    attributes:
      label: Discord Username
```

---

## AUTOMATION SETUP (GitHub Actions)

### File: `.github/workflows/discord-sync.yml`

```yaml
name: Discord Community Sync

on:
  issues:
    types: [opened, closed, labeled]
  pull_request:
    types: [opened, closed, merged]

jobs:
  notify-discord:
    runs-on: ubuntu-latest
    steps:
      - name: Send to Discord
        uses: tsickert/discord-webhook@v6.0.0
        with:
          webhook-url: ${{ secrets.DISCORD_WEBHOOK_URL }}
          content: |
            **Issue #{issue.number}** — {issue.title}
            Status: {issue.state}
            Link: {issue.html_url}
```

> **Note:** Replace the Discord webhook URL with your server's webhook from Server Settings → Integrations → Webhooks

---

## COMMUNITY BOARD (GitHub Projects)

Create a Project Board called "🗳️ Community Roadmap" with columns:

| Column | Cards |
|--------|-------|
| **📬 New Suggestions** | Incoming from Discord, not reviewed yet |
| **🔍 Under Review** | You're looking into feasibility |
| **✅ Planned** | Will build, rough timeline assigned |
| **🛠️ In Progress** | Currently being coded |
| **🚀 Shipped** | Deployed, closed, announced in #changelog |

### Workflow

1. Suggestion posted in Discord → you create GitHub Issue with `enhancement`
2. Issue auto-appears in "New Suggestions" column
3. You move it to "Under Review" while evaluating
4. If approved → "Planned" with priority label
5. When coding starts → "In Progress"
6. When merged → "Shipped" → auto-post to #changelog

---

## WEEKLY FEEDBACK RHYTHM

### Every Monday
- Post in #announcements: "This Week in GetTaller" — summary of what shipped, what's being worked on, top community suggestions
- Pin the changelog

### Every Friday
- "Feature Vote" — post 3 suggestions from the backlog, members react to prioritize
- Winner gets fast-tracked into next sprint

### Ad-hoc
- When a user's suggestion ships: `@mention` them in #changelog with "Shipped thanks to @user!"
- When a bug is fixed: reply in #feedback-beta to the original report with "Fixed in vX.X — thanks!"

---

## EXPECTATION MANAGEMENT

**Crucial rule:** Do NOT promise timeline. Say "added to the roadmap" or "under consideration" instead of "shipping next week." Under-promise, over-deliver.

When saying no to a suggestion:
```
"Love the idea but it doesn't fit the current scope. Saved it for
a future update though — if it gets enough community votes, I'll
revisit."
```
