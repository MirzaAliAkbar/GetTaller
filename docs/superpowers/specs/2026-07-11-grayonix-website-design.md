# Grayonix Studios Website Design Spec

**Date:** 2026-07-11  
**Project:** studios.grayonix.com  
**Status:** Design Approved  

---

## Executive Summary

A minimalist, professional portfolio website for Grayonix Studios with vibrant blue/orange brand accents. Single-page home with individual app detail pages. Tech stack: Static HTML/CSS/JavaScript. Audience: end users + investors/partners.

---

## Site Goals

1. **Showcase Grayonix Studios** as an app development company
2. **Promote GetTaller app** (and future apps) with download links
3. **Build credibility** with investors/partners via professional presentation
4. **Enable contact** via email signup/link

---

## Site Architecture

### Pages

**Home Page** (`/index.html`)
- Navigation bar with logo, links to apps & contact
- Hero section with Grayonix branding & tagline
- About section explaining company mission
- Featured Apps section showcasing available apps (card grid)
- Contact section with email link
- Footer with copyright & social links

**App Detail Pages** (`/app/{app-name}/index.html`)
- App header with icon, title, description
- App features & benefits section
- Screenshots gallery
- Download CTA button (links to Play Store)
- Privacy Policy & Terms of Service links (to `/docs/`)
- Back to home link

### File Structure

```
studios.grayonix.com/
├── index.html              (home page)
├── css/
│   ├── style.css          (home page + shared styles)
│   └── app-page.css       (app detail page styles)
├── js/
│   └── main.js            (navigation, animations, interactivity)
├── app/
│   └── gettaller/
│       └── index.html     (GetTaller app detail page)
├── assets/
│   ├── logo.svg           (Grayonix Studios logo)
│   ├── gettaller-icon.png (app icon)
│   └── screenshots/       (app screenshots)
└── docs/ (symlink or reference to parent /docs/)
    ├── privacy-policy.html
    └── terms-of-service.html
```

---

## Design System

### Color Palette

| Purpose | Color | Hex | Usage |
|---------|-------|-----|-------|
| Primary Brand (Blue) | Grayonix Blue | From logo | Buttons, links, accents |
| Secondary Brand (Orange) | Grayonix Orange | From logo | Badges, highlights, secondary CTAs |
| Background | White | #FFFFFF | Page background |
| Text | Dark Gray | #1A1A1A | Body text, headlines |
| Borders | Light Gray | #E8E8E8 | Dividers, card borders |
| Secondary Text | Medium Gray | #666666 | Captions, helper text |

### Typography

| Element | Font | Size (Desktop) | Size (Mobile) | Weight |
|---------|------|--|--|--------|
| Hero Title | Inter/Poppins | 48px | 32px | Bold (700) |
| Section Headers | Inter/Poppins | 32px | 24px | Bold (700) |
| Subheaders | Inter/Poppins | 24px | 18px | Semibold (600) |
| Body Text | Inter/Roboto | 16px | 14px | Regular (400) |
| Small Text | Inter/Roboto | 14px | 12px | Regular (400) |
| Buttons | Inter/Poppins | 14px | 12px | Semibold (600) |

### Spacing & Layout

- **Grid System:** 8px base unit (all spacing in multiples of 8)
- **Max Content Width:** 1200px (desktop)
- **Padding:** 40px (desktop) / 20px (mobile)
- **Section Gap:** 80px (desktop) / 40px (mobile)
- **Card Gap:** 24px
- **Border Radius:** 8px (cards), 4px (buttons)

### Responsive Breakpoints

- **Mobile:** < 640px
- **Tablet:** 640px - 1024px
- **Desktop:** > 1024px

### Visual Style

- **Aesthetic:** Minimalist + Vibrant Accents
- **Layout:** Clean whitespace, card-based components
- **Interaction:** Smooth hover animations on buttons/links
- **Shadows:** Soft shadows on cards (0 2px 8px rgba(0,0,0,0.08))
- **Buttons:** Blue primary, Orange secondary, 44px min height for touch

---

## Page Layouts

### Home Page (`/index.html`)

**Navigation Bar (Sticky)**
- Grayonix logo (left)
- Nav links: Home | Apps | Contact (center/right)
- Responsive hamburger menu on mobile
- Background: white with subtle shadow

**Hero Section**
- Full-width, centered content
- Headline: "Grayonix Studios"
- Subheading: "Building AI-Powered Apps for Growth"
- CTA Button: "Explore Our Apps" (Blue)
- Background: White with subtle blue/orange accent (top corner or gradient)
- Height: 60vh (viewport height)

**About Section**
- Headline: "Who We Are"
- Body: 2-3 sentences about company mission (free, accessible, AI-powered)
- Max width: 800px, centered
- Padding: 80px top/bottom

**Featured Apps Section**
- Headline: "Our Apps"
- Grid layout: 3 columns (desktop), 1 column (mobile)
- App cards show:
  - App icon (128x128px)
  - App name
  - Short description (1-2 lines)
  - "View App" button (Orange) → links to `/app/{app-name}/`
- Card styling: white background, 8px border-radius, soft shadow, hover lift animation

**Contact Section**
- Headline: "Get In Touch"
- Email link: `<a href="mailto:contact@grayonix.com">contact@grayonix.com</a>`
- Optional: "Interested in partnerships? Reach out!"
- Styling: Orange accent underline on email link

**Footer**
- Copyright: "© 2026 Grayonix Studios. All rights reserved."
- Social links (if applicable)
- Subtle background color (light gray #F5F5F5)

---

### App Detail Page (`/app/gettaller/index.html`)

**Header**
- Back button (← Back to Apps)
- App icon (128x128px)
- App name ("GetTaller")
- Tagline ("Height Optimization in 90 Days")
- Brief description (2-3 sentences)

**Features Section**
- Headline: "What You'll Get"
- 3-4 feature cards with icons + descriptions
- Blue accents on icons

**Screenshots Section**
- Carousel or grid of 3-5 app screenshots
- Responsive to mobile/desktop

**Download Section**
- Large Blue CTA: "Download on Google Play"
- Link: https://play.google.com/store/apps/details?id=com.grayonix.GetTaller
- Optional: Rating/review count (if available)

**Footer Links**
- Privacy Policy (link to `/docs/privacy-policy.html`)
- Terms of Service (link to `/docs/terms-of-service.html`)
- Back to Home (link to `/`)

---

## Content & Copy

### Taglines & Messaging

**Company Tagline:**
"AI-powered health apps for personal growth and optimization."

**Hero CTA:**
"Explore Our Apps"

**About Section:**
"Grayonix Studios builds free, accessible mobile apps powered by AI. We focus on health, growth, and optimization — helping users reach their potential."

**GetTaller Description:**
"Unlock your height potential with our AI-guided 90-day program. Free, evidence-based training for maximum growth."

---

## Technical Specifications

### Browser Support
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

### Performance
- Lighthouse score: 90+
- Load time: < 2 seconds
- Mobile-first responsive design
- Optimized images (PNG/WebP)

### Accessibility
- WCAG 2.1 Level AA compliance
- Semantic HTML
- Alt text on all images
- Focus states on interactive elements
- Color contrast ratio ≥ 4.5:1

### SEO
- Meta tags (title, description, keywords)
- Open Graph tags for social sharing
- Sitemap
- Mobile-friendly

---

## Implementation Notes

- **Hosting:** GitHub Pages (free static hosting)
- **Version Control:** Git repository on GitHub
- **Build Tool:** None required (static HTML/CSS/JS)
- **Future Scalability:** Can upgrade to React/Next.js when needed (5+ apps)

---

## Success Criteria

✅ Website loads in < 2 seconds  
✅ Mobile-responsive on all devices  
✅ GetTaller app showcased with clear download link  
✅ Professional appearance for investors/partners  
✅ Email contact link functional  
✅ Privacy/Terms links accessible  
✅ All brand colors (blue, orange) prominently featured  

---

**Next Step:** Implementation plan with file-by-file breakdown and development timeline.
