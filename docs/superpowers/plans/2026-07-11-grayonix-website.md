# Grayonix Studios Website Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a static HTML/CSS/JavaScript portfolio website for Grayonix Studios with a home page and GetTaller app showcase page, responsive across all devices.

**Architecture:** Mobile-first responsive design using semantic HTML5, vanilla CSS (no frameworks), and vanilla JavaScript for interactions. Single-page home with linked app detail pages. No build process required — static files deployed directly.

**Tech Stack:** HTML5, CSS3 (Grid/Flexbox), Vanilla JavaScript (ES6+), no frameworks or dependencies.

## Global Constraints

- All files in `/home/ali/GetTaller-Claude/studios.grayonix.com/` folder ONLY
- Primary brand colors: Blue (from logo) + Orange (from logo)
- Neutral: #FFFFFF (white), #1A1A1A (text), #E8E8E8 (borders)
- Fonts: Inter/Poppins (headlines), Inter/Roboto (body) — use system fallbacks or Google Fonts
- 8px grid system (all spacing multiples of 8)
- Mobile-first responsive: < 640px (mobile), 640-1024px (tablet), > 1024px (desktop)
- Lighthouse score target: 90+
- WCAG 2.1 Level AA accessibility compliance
- GetTaller Play Store link: https://play.google.com/store/apps/details?id=com.grayonix.GetTaller
- Contact email: contact@grayonix.com

---

## Tasks

### Task 1: Create Base HTML Structure & Navigation
**Files:** `index.html`, `css/style.css` (empty), `js/main.js` (empty)
**Produces:** Home page structure with semantic HTML, navigation bar markup

### Task 2: Create Shared CSS Styles & Color System
**Files:** `css/style.css`, `css/app-page.css` (empty)
**Produces:** Complete CSS for home page with design system, colors, typography, responsive layout

### Task 3: Add Navigation Interactivity & Smooth Scrolling
**Files:** `js/main.js`, update `css/style.css`
**Produces:** Hamburger menu, smooth scroll, active nav highlighting

### Task 4: Create GetTaller App Detail Page HTML
**Files:** `app/gettaller/index.html`
**Produces:** App detail page structure with header, features, screenshots, download, footer

### Task 5: Style App Detail Page with CSS
**Files:** `css/app-page.css`
**Produces:** Complete styling for app page with responsive layout

### Task 6: Add Missing Assets
**Files:** `assets/logo.svg`, `assets/gettaller-icon.png`, `assets/screenshots/screen*.png`
**Produces:** All required image assets in correct directories

### Task 7: Create Symlink to Docs
**Files:** Symlink `docs/` to `../../docs/`
**Produces:** Accessible privacy/terms links on app detail page

### Task 8: Final Testing & Optimization
**Files:** All HTML/CSS/JS files
**Produces:** Fully functional, optimized website ready for deployment

---

**Plan Status:** Ready to execute
