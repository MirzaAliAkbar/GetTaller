# GetTaller - Production Launch Checklist

## ✅ COMPLETED

- [x] Core app features built & tested
- [x] AdMob integration (4 ad types with production IDs)
- [x] Privacy Policy created & hosted
- [x] Terms of Service created & hosted
- [x] Firebase setup (Analytics, Crashlytics, Remote Config)
- [x] Local storage (Hive with encryption)
- [x] AI Coach API key security (Remote Config + fallback)
- [x] Android & iOS manifests updated
- [x] App icon & branding

---

## 🚀 NEXT: Build & Test (This Week)

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run on Your Device
```bash
# Android
flutter run --dart-define=OPENCODE_ZEN_API_KEY=sk-YOUR-NEW-KEY

# iOS
flutter run --dart-define=OPENCODE_ZEN_API_KEY=sk-YOUR-NEW-KEY
```

### 3. Test Everything
- [ ] Onboarding flow (all screens)
- [ ] Height prediction calculation
- [ ] Daily plan & exercises
- [ ] AI coach (test message)
- [ ] Ads display (banner, interstitial, rewarded, native)
- [ ] Analytics fire (check Firebase console)
- [ ] Notifications work
- [ ] App doesn't crash

### 4. Build Release APK
```bash
flutter build apk --release --dart-define=OPENCODE_ZEN_API_KEY=sk-YOUR-NEW-KEY
```

### 5. Build Release iOS
```bash
flutter build ios --release --dart-define=OPENCODE_ZEN_API_KEY=sk-YOUR-NEW-KEY
```

---

## 📸 Google Play Store Prep

### 1. Screenshots (5-6 required)
Take screenshots showing:
- [ ] Onboarding/welcome screen
- [ ] Height prediction result
- [ ] Daily plan with exercises
- [ ] AI coach feature
- [ ] Progress/growth chart
- [ ] App running on multiple sizes

### 2. App Store Listing Content
- [ ] Title: "GetTaller"
- [ ] Short description (80 chars): "Your 90-day height growth journey"
- [ ] Full description: Compelling copy about features
- [ ] Category: "Health & Fitness"
- [ ] Content rating: Age 17+ (health/fitness context)
- [ ] Privacy policy: https://mirzaaliakbar.github.io/GetTaller/privacy-policy.html
- [ ] Terms of service: https://mirzaaliakbar.github.io/GetTaller/terms-of-service.html

### 3. Create Google Play Developer Account
- [ ] Visit: https://play.google.com/apps/publish/
- [ ] Sign in with your Google account
- [ ] Pay $25 one-time fee
- [ ] Accept Developer Agreement
- [ ] Add payment method

### 4. Upload to Play Console
- [ ] Create app in Play Console
- [ ] Fill in all listing details
- [ ] Upload signed AAB (Android App Bundle)
- [ ] Set version: 1.0.0
- [ ] Select "Production" release

### 5. Submit for Review
- [ ] Review all content
- [ ] Accept consent declarations
- [ ] Submit for review
- [ ] Monitor for rejections (usually approved in 2-3 hours)

---

## 🍎 Apple App Store Prep

### 1. Create Apple Developer Account
- [ ] Visit: https://developer.apple.com/
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Accept Developer Agreement

### 2. Create App in App Store Connect
- [ ] Go to https://appstoreconnect.apple.com
- [ ] Create new app
- [ ] Set name: "GetTaller"
- [ ] Select "Health & Fitness" category
- [ ] Age rating: 17+

### 3. App Store Screenshots
- [ ] Upload 5-6 screenshots
- [ ] Test on various device sizes

### 4. Build & Submit
- [ ] Build release: `flutter build ios --release`
- [ ] Create TestFlight build
- [ ] Test on TestFlight with real users
- [ ] Submit to App Review
- [ ] Apple review takes 24-48 hours

---

## 🔧 Firebase Remote Config Setup

### Set Up API Key Distribution
1. Go to Firebase Console
2. Select GetTaller project
3. Remote Config → Create config
4. Add parameter:
   ```
   Key: deepseek_api_key
   Type: String
   Default value: sk-YOUR-NEW-KEY
   ```
5. Publish

This allows you to rotate API keys without rebuilding the app!

---

## 📋 Final Pre-Launch Checklist

- [ ] No test ad IDs remain in code
- [ ] No hardcoded API keys in source code
- [ ] All Firebase rules are production-ready
- [ ] Privacy policy & terms hosted and linked
- [ ] App version set to 1.0.0
- [ ] Screenshots are high quality
- [ ] Description is compelling
- [ ] All features tested on real device
- [ ] No crashes during 10-minute test
- [ ] Ads display correctly
- [ ] Analytics working
- [ ] Notifications working
- [ ] AI coach responding to queries

---

## 🚀 Launch Timeline

**Week 1:** Build, test, prepare store listings
**Week 2:** Submit to Google Play (internal testing first)
**Week 2-3:** Prepare App Store, create TestFlight builds
**Week 3:** Full rollout on Play Store, submit to App Store
**Week 4:** App Store approved, both platforms live!

---

## 📞 Support

- Privacy/Legal Questions: Check `privacy-policy.html` & `terms-of-service.html`
- Firebase Issues: Console → Project Settings
- Ad Issues: AdMob console for your account
- App Issues: Check device logs with `flutter logs`

---

**Good luck with your launch! 🚀**
