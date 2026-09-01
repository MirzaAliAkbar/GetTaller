# GetTaller 🚀

A Flutter app for height growth tracking, powered by AI. This project also includes a robust affiliate backend system built with Cloudflare Workers and D1.

[![Flutter](https://img.shields.io/badge/Flutter-2.10-blue)]() [![Dart](https://img.shields.io/badge/Dart-2.19-green)]() [![Cloudflare Workers](https://img.shields.io/badge/Cloudflare%20Workers-integrated-orange)]() [![D1](https://img.shields.io/badge/Cloudflare%20D1-database-blue)]()

## Table of Contents 📄

- [About GetTaller](#about-gettaller)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Affiliate Backend Architecture](#affiliate-backend-architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)
- [Important Links](#important-links)

## About GetTaller 📱

GetTaller is a mobile application designed to assist users on their 90-day height growth journey. It offers AI-guided training, personalized nutrition plans, and precise progress tracking. The app is 100% free, privacy-first, and monetized through non-personalized ads.

## Key Features ✨

*   **AI-Powered Growth Tracking:** Utilizes AI to provide personalized training and nutrition plans.
*   **Privacy-First Design:** No cloud storage for user health data; all information remains on the device.
*   **Anonymous Usage:** No account creation or login required, ensuring user privacy.
*   **Ad-Supported Model:** Offers core functionality for free, supported by privacy-respecting, non-personalized ads.
*   **Influencer Affiliate Program:** Enables influencers to earn by referring new users.
*   **Cloudflare Workers & D1 Backend:** A cost-effective and scalable backend infrastructure for the affiliate program.

## Tech Stack 💻

*   **Frontend:** Flutter, Dart
*   **Backend:** Cloudflare Workers, TypeScript, D1 (SQLite-compatible)
*   **Database:** D1 (SQLite)
*   **Web Hosting:** Cloudflare Pages
*   **CI/CD:** Not explicitly configured in the analyzed files.
*   **Other:** Node.js (for build scripts and utilities)

## Affiliate Backend Architecture 🏗️

The affiliate backend is a sophisticated system designed for scalability and cost-efficiency, leveraging Cloudflare's serverless offerings:

*   **Cloudflare Workers:** Handles API requests for validation, event logging, and data retrieval for both influencers and administrators.
*   **Cloudflare D1:** A managed SQLite database service used for storing user data, referral codes, ad events, payouts, and admin credentials.
*   **Cloudflare Pages:** Hosts the static frontend applications for the influencer and admin dashboards.

**Core Components:**

*   **/dashboard/**: Influencer portal for viewing stats, earnings, and payout history.
*   **/admin/**: Administrator portal for managing influencers, codes, payouts, and viewing overall statistics.
*   **/v1/*:** The Cloudflare Worker acting as the API gateway, handling all backend logic.

## Installation 🛠️

### Backend (Cloudflare Workers & D1)

1.  **Prerequisites:**
    *   Node.js 18+ installed locally.
    *   Wrangler CLI installed globally: `npm install -g wrangler`
    *   Cloudflare account with Workers subscription (free tier is sufficient).
    *   `studios.grayonix.com` domain (or your own domain) managed by Cloudflare.

2.  **Clone the repository:**
    ```bash
    git clone https://github.com/MirzaAliAkbar/GetTaller.git
    cd GetTaller/affiliate-backend
    ```

3.  **Authenticate Wrangler:**
    ```bash
    wrangler login
    ```
    Follow the prompts to authorize your Cloudflare account.

4.  **Create D1 Database:**
    ```bash
    wrangler d1 create gettaller-affiliate
    ```
    Copy the returned database ID and paste it into `affiliate-backend/wrangler.toml` under `[[d1_databases]]`.

5.  **Initialize Schema:**
    ```bash
    wrangler d1 execute gettaller-affiliate --file=schema.sql
    ```
    Verify tables with: `wrangler d1 execute gettaller-affiliate --command=".tables"`.

6.  **Configure Secrets:**
    *   Set `SESSION_SECRET` (a random 64-character string):
        ```bash
        wrangler secret put SESSION_SECRET
        ```
    *   If using the seed endpoint, set `SEED_KEY`:
        ```bash
        wrangler secret put SEED_KEY
        ```
    Generate random values using Node.js:
    ```bash
    node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
    ```

7.  **Deploy the Worker:**
    ```bash
    npm run deploy
    ```

8.  **Deploy Dashboard Pages:**
    Deploy the `dashboard/` and `admin/` directories to Cloudflare Pages as separate projects.
    ```bash
    npx wrangler pages deploy ./dashboard --project-name=gettaller-dashboard
    npx wrangler pages deploy ./admin --project-name=gettaller-admin
    ```

### Frontend (Flutter)

*   **Prerequisites:**
    *   Flutter SDK installed.
    *   Android Studio or Xcode (for emulators/devices).

*   **Clone the repository:**
    ```bash
    git clone https://github.com/MirzaAliAkbar/GetTaller.git
    cd GetTaller/flutter_app # Assuming 'flutter_app' is the directory name
    ```

*   **Install Dependencies:**
    ```bash
    flutter pub get
    ```

*   **Run the App:**
    ```bash
    flutter run
    ```

## Usage 🛠️

### Influencer Affiliate Program

1.  **Influencer Registration:** Influencers can apply via a link on the main `studios.grayonix.com` website (not explicitly present in the analyzed files but implied by the affiliate system).
2.  **Admin Approval:** The admin user creates referral codes and grants access to the influencer dashboard.
3.  **Referral:** Influencers share their unique referral code with their audience.
4.  **User Signup:** New GetTaller app users can enter the referral code during onboarding.
5.  **Tracking:** The system tracks signups attributed to each referral code.
6.  **Reporting:** Influencers can log in to their dashboard (`studios.grayonix.com/dashboard/`) to view their performance metrics (signups, estimated revenue, earnings).
7.  **Payouts:** Admins manage the payout process, reconciling monthly revenue and distributing earnings to influencers.

### Admin Dashboard

*   **Access:** Log in at `studios.grayonix.com/admin/login.html`.
*   **Functionality:**
    *   View overall affiliate program statistics.
    *   Manage influencer accounts (view details, activate/deactivate codes).
    *   Add new influencers.
    *   Process monthly payouts by reconciling AdMob revenue data.
    *   Monitor for potential fraud (e.g., burst signups, low retention).

### Core GetTaller App Usage

*   The Flutter app focuses on height growth tracking, providing AI-driven guidance without requiring user accounts or cloud data storage.

## Project Structure 📂

```
GetTaller/
├── affiliate-backend/
│   ├── admin/
│   │   ├── app.js             # Admin dashboard shared JS library
│   │   ├── index.html         # Admin dashboard main page
│   │   ├── login.html         # Admin login page
│   │   ├── payouts.html       # Payouts management page
│   │   ├── styles.css         # Admin-specific styles
│   │   └── ...                # Other admin-related HTML/JS files
│   ├── dashboard/
│   │   ├── app.js             # Influencer dashboard shared JS library
│   │   ├── index.html         # Influencer dashboard main page
│   │   ├── login.html         # Influencer login page
│   │   ├── settings.html      # Influencer settings page
│   │   └── styles.css         # Influencer dashboard styles
│   ├── src/                   # TypeScript source for Cloudflare Worker
│   │   └── worker.ts          # Main worker logic
│   ├── package.json           # Backend dependencies and scripts
│   ├── tsconfig.json          # TypeScript configuration
│   ├── schema.sql             # D1 database schema
│   └── wrangler.toml          # Wrangler CLI configuration
├── docs/
│   ├── index.html             # Legal documents landing page
│   ├── privacy-policy.html    # Privacy Policy
│   └── terms-of-service.html  # Terms of Service
├── flutter_app/              # Flutter mobile application (structure not fully detailed in analysis)
│   ├── lib/
│   │   ├── app.dart
│   │   └── main.dart
│   ├── ios/
│   ├── android/
│   └── web/
│       └── index.html         # Web build entry point
├── studios.grayonix.com/
│   ├── admin/
│   │   ├── app.js
│   │   ├── index.html
│   │   ├── login.html
│   │   ├── payouts.html
│   │   └── styles.css
│   ├── css/
│   │   ├── app-page.css
│   │   └── style.css
│   └── index.html             # Grayonix Studios main website
├── .gitignore
└── README.md
```

## API Reference 🌐

The Cloudflare Worker exposes several API endpoints for managing the affiliate system:

**Public Endpoints:**

*   `GET /v1/validate?code={referral_code}`: Validates a referral code.
*   `POST /v1/events/signup`: Logs a new user signup event.
*   `POST /v1/events/ad`: Logs ad revenue events.
*   `POST /v1/events/ping`: Logs a daily user ping for retention tracking.
*   `POST /v1/events/subscription`: Logs subscription events (purchase, renewal, etc.).

**Influencer Endpoints (Require Authentication):

*   `POST /v1/influencer/login`: Logs in an influencer using their code and password.
*   `POST /v1/influencer/logout`: Logs out the influencer.
*   `GET /v1/influencer/stats`: Retrieves statistics for the logged-in influencer.
*   `GET /v1/influencer/settings`: Retrieves influencer profile and payout history.

**Admin Endpoints (Require Authentication):

*   `POST /v1/admin/login`: Logs in an admin user.
*   `POST /v1/admin/logout`: Logs out the admin user.
*   `GET /v1/admin/dashboard`: Retrieves overall dashboard statistics.
*   `GET /v1/admin/influencers`: Retrieves a list of all influencers.
*   `GET /v1/admin/influencer/{influencerId}`: Retrieves details for a specific influencer.
*   `POST /v1/admin/codes`: Creates a new influencer referral code.
*   `PATCH /v1/admin/codes/{code}`: Updates an existing influencer code (e.g., active status, share percentage).
*   `GET /v1/admin/payouts`: Retrieves payout history and pending calculations.
*   `POST /v1/admin/payouts/reconcile`: Runs the monthly revenue reconciliation process.
*   `POST /v1/admin/payouts/mark-paid`: Marks a payout as paid.
*   `GET /v1/admin/fraud`: Retrieves potential fraud alerts.
*   `POST /v1/admin/seed`: Seeds the initial admin user (protected by `ADMIN_SECRET`).

## Contributing 🤝

Contributions are welcome! Please feel free to submit pull requests or open issues for bug reports or feature requests. For significant changes, please open an issue first to discuss what you would like to change.

## License 📜

This project is not specified to have a license. Please refer to the repository owner for licensing details.

## Important Links 🔗

*   **Live Demo (Grayonix Studios):** [studios.grayonix.com](https://studios.grayonix.com/)
*   **GitHub Repository:** [https://github.com/MirzaAliAkbar/GetTaller](https://github.com/MirzaAliAkbar/GetTaller)
*   **Developer Profile:** [Mirza Ali Akbar](https://github.com/MirzaAliAkbar)

## Footer 🛠️

**Repository:** GetTaller
**URL:** [https://github.com/MirzaAliAkbar/GetTaller](https://github.com/MirzaAliAkbar/GetTaller)
**Author:** Mirza Ali Akbar

Have questions or need support? Contact [support@gettaller.app](mailto:support@gettaller.app).

Star ⭐ | Fork 🍴 | Like ❤️


---
