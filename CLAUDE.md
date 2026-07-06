# GetTaller App by Claude — Project Guidelines

## Installed Mobile App UI/UX Design Skill

This project uses the **Mobile App UI/UX Design** skill installed at `~/.claude/skills/mobile-app-ui-design/`. Apply its principles for all mobile interface work.

### Core Design Framework (always apply in order)

1. **Understand Context** — app type, user, primary action, industry conventions
2. **Structure (UX)** — user flow, thumb zone, F-pattern, reduce interaction cost
3. **Visual Design (UI)** — typography, color (60/30/10), spacing (8pt grid), shadows
4. **Emotion** — Peak-End Rule, emotional feedback loops
5. **Polish** — micro-interactions, states, accessibility

### Key Design Rules

| Rule | Specification |
|---|---|
| **60/30/10 Color** | 60% neutral, 30% complementary, 10% accent |
| **8-Point Grid** | All spacing divisible by 8 or 4 |
| **Thumb Zone** | Primary actions in bottom 1/3 of screen |
| **Typography** | 1 font family, max 4 sizes, 2 weights, opacity for hierarchy |
| **Shadows** | Soft, tinted to background — never pure gray/black |
| **Touch Targets** | Minimum 44×44pt |
| **Baseline** | 375px width (iPhone SE) |

### Industry Conventions Reference

See `~/.claude/skills/mobile-app-ui-design/references/industry-conventions.md` for domain-specific design patterns (Health/Wellness, Fitness, and more).

---

## Project: GetTaller App by Claude

Built on the **HeightMax** blueprint (`/home/ali/APP_BLUEPRINT.md`). A Flutter-based health/fitness app for height growth tracking, exercise guidance, nutrition analysis, and AI coaching.

### Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Backend:** Firebase Auth, Firestore, Cloud Functions, Remote Config
- **Subscriptions:** RevenueCat
- **Design Implementation:** Flutter widgets + custom painters

### Key App Structure
- **Onboarding:** 14-step linear funnel (splash → data collection → paywall)
- **Main App:** 3-tab bottom nav (Dashboard, Daily Plan, AI Coach)
- **Post-onboarding:** Exercise player, AR height measurement, meal AI analysis, education hub

When designing any screen, always reference the Mobile App UI/UX Design skill first.
