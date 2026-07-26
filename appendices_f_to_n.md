# APPENDIX B: NUTRITION MODULE — COMPLETE DAILY TARGETS

## B.1 Daily Nutrition Targets Per Age/Gender

| Age Range | Gender | Calories(kcal) | Protein(g) | Ca(mg) | Vit D(IU) |
|---|---|---|---|---|---|
| 5-8 | Any | 1400-1800 | 19-25 | 800 | 600 |
| 9-13 | Male | 1800-2200 | 34-40 | 1000 | 600 |
| 9-13 | Female | 1600-2000 | 34-40 | 1000 | 600 |
| 14-18 | Male | 2400-2800 | 52-59 | 1300 | 600 |
| 14-18 | Female | 2000-2200 | 46-52 | 1300 | 600 |
| 19-30 | Male | 2600-2800 | 56-63 | 1000 | 600 |
| 19-30 | Female | 2000-2200 | 46-52 | 1000 | 600 |
| 31-50 | Male | 2400-2600 | 56-63 | 1000 | 600 |
| 31-50 | Female | 1800-2000 | 46-52 | 1000 | 600 |

## B.2 Height-Boosting Nutrient Sources

| Nutrient | Best Food Sources | Role In Growth |
|---|---|---|
| Protein | Eggs, chicken, fish, tofu, lentils, Greek yogurt, milk | Building blocks for bone and muscle tissue |
| Calcium | Milk, cheese, yogurt, almonds, sardines, kale, broccoli, figs | Bone mineralization and density |
| Vitamin D | Sunlight (15min/d), fatty fish, egg yolks, fortified milk | Calcium absorption, bone growth |
| Zinc | Oysters, beef, pumpkin seeds, chickpeas, cashews, eggs | Cell growth and division, protein synthesis |
| Magnesium | Spinach, almonds, black beans, avocado, banana, dark chocolate | Bone structure, sleep quality, muscle function |
| Vitamin K2 | Natto, liver, cheese, egg yolks, sauerkraut, butter | Directs calcium to bones instead of arteries |
| Boron | Prunes, raisins, almonds, hazelnuts, chickpeas, apples | Activates vitamin D, supports bone metabolism |
| Collagen | Bone broth, chicken skin, gelatin, fish skin | Joint, tendon, and bone matrix health |
| Arginine | Nuts, seeds, chickpeas, lentils, turkey, pumpkin seeds | Stimulates growth hormone release during sleep |
| Ornithine | Meat, fish, dairy, eggs, watermelon | Growth hormone release support |

## B.3 Meal Analysis Engine Cloud Function Contract

```
Cloud Function: analyzeMeal
Method: onCall

Input:
{
  "description": "Grilled chicken salad with quinoa and avocado",
  "mealType": "lunch",
  "language": "en"
}

Output:
{
  "calories": 520,
  "proteinG": 38,
  "calciumMg": 120,
  "vitaminDIU": 15,
  "qualityScore": 82,
  "recommendations": ["Great protein content! Consider adding a calcium-rich component."],
  "macros": {"carbs": 45, "fat": 22, "fiber": 8}
}

Model: Gemini Pro with food-specific system prompt
System prompt: "You are HeightMax Nutrition AI, specializing in analyzing meals for nutritional content relevant to height growth..."
```

## B.4 Nutritional Quality Score Calculation

```
qualityScore = (proteinScore * 0.35) + (calciumScore * 0.25) + (vitaminDScore * 0.20) + (calorieAlignment * 0.10) + (varietyScore * 0.10)

proteinScore = min(proteinG / targetProteinG, 1.0) * 100
calciumScore = min(calciumMg / targetCalciumMg, 1.0) * 100
vitaminDScore = min(vitaminDIU / targetVitaminDIU, 1.0) * 100
calorieAlignment = 100 - abs(calories - targetCalories) / targetCalories * 50
varietyScore = mealType == 'breakfast' ? 70 : mealType == 'lunch' ? 80 : mealType == 'dinner' ? 85 : 60

Interpretation:
0-40: "Poor — needs improvement"
40-60: "Fair — could be better"
60-80: "Good — on the right track"
80-100: "Excellent — optimal for growth"
```

---

# APPENDIX C: GROWTH CHART PERCENTILE REFERENCE DATA

## C.1 WHO Growth Reference (Male, Height cm, Ages 5-19)

| Age (y) | 3rd %ile | 10th %ile | 50th %ile | 90th %ile | 97th %ile |
|---|---|---|---|---|---|
| 5 | 104.5 | 107.5 | 110.0 | 113.5 | 116.0 |
| 6 | 109.5 | 113.0 | 116.0 | 119.5 | 122.0 |
| 7 | 114.0 | 118.0 | 121.0 | 125.0 | 128.0 |
| 8 | 118.5 | 122.0 | 126.0 | 130.0 | 133.5 |
| 9 | 123.0 | 127.0 | 131.0 | 135.5 | 139.0 |
| 10 | 127.5 | 131.5 | 136.0 | 141.0 | 144.5 |
| 11 | 131.5 | 136.0 | 141.0 | 146.5 | 150.5 |
| 12 | 135.5 | 140.5 | 147.0 | 153.5 | 158.0 |
| 13 | 140.0 | 145.5 | 153.5 | 161.5 | 166.5 |
| 14 | 145.0 | 151.5 | 160.5 | 169.5 | 174.5 |
| 15 | 150.5 | 157.0 | 166.0 | 175.0 | 179.5 |
| 16 | 154.5 | 161.0 | 169.5 | 178.0 | 182.5 |
| 17 | 156.5 | 163.0 | 171.5 | 180.0 | 184.5 |
| 18 | 157.0 | 164.0 | 173.0 | 181.5 | 186.0 |
| 19 | 157.5 | 164.5 | 174.0 | 182.5 | 187.0 |

## C.2 WHO Growth Reference (Female, Height cm, Ages 5-19)

| Age (y) | 3rd %ile | 10th %ile | 50th %ile | 90th %ile | 97th %ile |
|---|---|---|---|---|---|
| 5 | 103.5 | 106.5 | 109.5 | 112.5 | 115.0 |
| 6 | 108.5 | 111.5 | 115.0 | 118.5 | 121.0 |
| 7 | 113.0 | 116.5 | 120.0 | 124.0 | 127.0 |
| 8 | 117.5 | 121.0 | 125.5 | 129.5 | 132.5 |
| 9 | 122.0 | 126.0 | 130.5 | 135.0 | 138.5 |
| 10 | 127.0 | 131.0 | 136.5 | 141.5 | 145.0 |
| 11 | 132.0 | 136.5 | 142.5 | 148.5 | 152.5 |
| 12 | 136.5 | 141.5 | 148.0 | 155.0 | 159.0 |
| 13 | 140.0 | 145.5 | 153.0 | 160.0 | 164.0 |
| 14 | 142.5 | 148.0 | 155.5 | 162.5 | 166.5 |
| 15 | 143.5 | 149.0 | 157.0 | 164.0 | 168.0 |
| 16 | 144.0 | 149.5 | 158.0 | 165.0 | 169.0 |
| 17 | 144.0 | 150.0 | 158.5 | 165.5 | 169.5 |
| 18 | 144.5 | 150.0 | 158.5 | 165.5 | 170.0 |
| 19 | 144.5 | 150.0 | 159.0 | 166.0 | 170.5 |

## C.3 Z-Score to Percentile Conversion Table

| Z-Score | %ile | Z-Score | %ile | Z-Score | %ile |
|---|---|---|---|---|---|
| -3.0 | 0.13% | -1.0 | 15.87% | 1.0 | 84.13% |
| -2.5 | 0.62% | -0.5 | 30.85% | 1.5 | 93.32% |
| -2.0 | 2.28% | 0.0 | 50.00% | 2.0 | 97.72% |
| -1.5 | 6.68% | 0.5 | 69.15% | 2.5 | 99.38% |
| -1.28 | 10.00% | 1.28 | 90.00% | 3.0 | 99.87% |

---

# APPENDIX D: FIREBASE SECURITY RULES

## D.1 Complete firestore.rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() { return request.auth != null; }
    function isOwner(userId) { return request.auth.uid == userId; }
    
    // User data: only owner access
    match /users/{userId} {
      allow read: if isAuthenticated() && isOwner(userId);
      allow create: if isAuthenticated() && isOwner(userId)
          && request.resource.data.keys().hasAll(['uid', 'createdAt']);
      allow update: if isAuthenticated() && isOwner(userId)
          && request.resource.data.uid == resource.data.uid;
      allow delete: if isAuthenticated() && isOwner(userId);
      
      // Measurements subcollection
      match /measurements/{measurementId} {
        allow read: if isAuthenticated() && isOwner(userId);
        allow create: if isAuthenticated() && isOwner(userId)
            && request.resource.data.keys().hasAll(['valueCm', 'measuredAt'])
            && request.resource.data.valueCm >= 50
            && request.resource.data.valueCm <= 250;
        allow delete: if isAuthenticated() && isOwner(userId);
        allow update: if false; // measurements are immutable
      }
      
      // Sleep Logs
      match /sleep_logs/{logId} {
        allow read: if isAuthenticated() && isOwner(userId);
        allow write: if isAuthenticated() && isOwner(userId);
      }
      
      // Meal Logs
      match /meal_logs/{logId} {
        allow read: if isAuthenticated() && isOwner(userId);
        allow write: if isAuthenticated() && isOwner(userId);
      }
      
      // Completed Days
      match /completed_days/{dayId} {
        allow read: if isAuthenticated() && isOwner(userId);
        allow write: if isAuthenticated() && isOwner(userId);
      }
    }
    
    // Public data: read-only for authenticated users
    match /exercise_translations/{locale} {
      allow read: if isAuthenticated();
      allow write: if false;
    }
    
    match /exercise_videos/{exerciseId} {
      allow read: if isAuthenticated();
      allow write: if false;
    }
  }
}
```

## D.2 Firestore Indexes

```
Collection: measurements  → fields: measuredAt (DESCENDING)
Collection: sleep_logs    → fields: date (DESCENDING)
Collection: meal_logs     → fields: date (DESCENDING)
Collection: completed_days → fields: date (DESCENDING)
```

---

# APPENDIX E: COMPLETE NOTIFICATION CONTENT TABLE

## E.1 Notification Content Per Type

| Type | Title (EN) | Body (EN) | Android Channel | Priority |
|---|---|---|---|---|
| incomplete_onboarding | "Complete Your Assessment" | "See your height potential — finish your assessment in 2 minutes!" | onboarding | HIGH |
| daily_workout | "Time for Your Workout! 🔥" | "Don't break your streak! Today's exercises await." | workout | HIGH |
| pre_sleep | "Wind Down Time 🌙" | "HGH peaks during deep sleep. Lights out soon!" | sleep | DEFAULT |
| streak_at_risk | "Streak at Risk! ⚠️" | "Your {streak}-day streak is at risk! A quick 10-min session keeps it alive." | streak | HIGH |
| streak_broken | "Streak Lost 💔" | "Your streak was broken. Don't worry — start fresh today!" | streak | HIGH |
| streak_milestone | "Milestone Unlocked! 🏆" | "Congrats on your {streak}-day streak! Keep up the amazing work!" | streak | DEFAULT |
| progress_milestone | "You're Growing! 📈" | "You've grown {cm} cm since last measurement!" | progress | HIGH |
| re_engagement_7d | "We Miss You! 💪" | "Your growth plan is waiting. Every day counts!" | re_engage | DEFAULT |
| re_engagement_14d | "Still Thinking About Growth?" | "Don't leave your potential behind." | re_engage | DEFAULT |
| re_engagement_30d | "Your Progress Matters" | "It's not too late. Height growth is a marathon." | re_engage | HIGH |
| weekly_summary | "Your Weekly Summary 📊" | "This week: {workouts} workouts, {sleep}h sleep, {meals} meals logged." | summary | DEFAULT |
| goal_proximity | "Almost There! 🎯" | "You're only {cm} cm from your goal! Keep pushing!" | goal | HIGH |
| new_content | "New Exercise Available" | "Check out our latest growth exercise!" | content | LOW |
| plan_update | "Plan Updated 📋" | "Your growth plan has been updated based on your latest progress." | plan | DEFAULT |

---

# APPENDIX F: COMPLETE A/B EXPERIMENT VARIANT SPECIFICATIONS

## F.1 Paywall Design Variants

VARIANT A — "Classic" (Control):
- 3 product cards stacked vertically (Weekly, Monthly, Yearly)
- "Most Popular" on monthly, "Best Value" on yearly
- Feature comparison table above pricing
- Purple primary CTAs
- "Free" vs "Premium" column comparison table
- Revenue: baseline

VARIANT B — "High Social Proof":
- "Join 50,000+ growing users" header
- Customer testimonials (2-3, with avatars)
- "96% satisfaction rate" badge
- "Risk-free" / "Cancel anytime" reassurance text
- Monthly highlighted as "most popular among users"
- Expected: +15% revenue

VARIANT C — "Urgency / Scarcity":
- Countdown timer: "Limited time offer" (24h)
- "50% OFF — First Month" badge
- Annual plan shown FIRST (best value)
- "Only X spots remaining" text
- Subtle red accent instead of gold
- Expected: +25% revenue (but lower long-term retention)

## F.2 Onboarding Flow Variants

VARIANT A — "Standard" (Control):
- Full 14-screen onboarding sequence
- Education cards shown on "accurate" path
- Paywall shown after result preview
- Completion rate: baseline

VARIANT B — "Fast":
- Reduced to 8 screens (gender, age, height, weight, sleep)
- No sports, parent height, puberty, or education cards
- Paywall shown immediately after basic result
- "We'll ask more as you go" inline text
- Expected: +30% completion, -20% subscription conversion

VARIANT C — "Premium First":
- Paywall appears after 3 screens (gender, age, height)
- "Unlock to continue" blocking approach
- Remaining screens unlocked after purchase
- Expected: +50% subscription conversion, -60% completion rate

## F.3 AI Coach Personality Variants

VARIANT A — "Professional" (Control):
- Formal tone, clinical language
- Uses proper anatomical terms
- Cites studies: "Research from PubMed shows..."
- "Based on current evidence..." style openings
- Engagement: baseline

VARIANT B — "Friendly":
- Conversational tone, "Hey there!" openings
- Uses emojis in responses
- Encouraging: "You're doing great!"
- "Here's a quick tip..." style
- Expected: +40% engagement

VARIANT C — "Scientific":
- Deep scientific explanations with molecular pathways
- "The IGF-1 signaling cascade activates..."
- Links to specific research papers
- "Growth velocity = d(height)/dt" style
- Expected: +25% engagement with adults, -20% with teens

## F.4 Growth Formula Variants

VARIANT A — "v1" (Current):
- Conservative linear model
- BMI adjustment: plus/minus 0.5-2.5cm
- Sleep adjustment: plus/minus 1-2cm
- Sports bonus: 0-3cm
- Genetic weight: 70% growth window x remaining years
- Average predicted gain: 3-8cm

VARIANT B — "v2_enhanced":
- Sigmoidal velocity model (non-linear growth)
- Sleep quality metric (not just hours)
- Hydration factor (derived from weight)
- Stress/cortisol proxy (from sleep quality)
- Bone age estimation (from height + markers)
- Nutrition quality score (from meal logs)
- Average predicted gain: 4-12cm

---

# APPENDIX G: ERROR HANDLING MATRIX

## G.1 Every Possible Error, Source, and Recovery

| Error Condition | Source | User Message | Recovery Action |
|---|---|---|---|
| Firebase init timeout (15s) | SplashScreen | "Could not connect to server." | Retry button |
| Firebase init fails | SplashScreen | "Service error." | Retry + support |
| Firebase Auth network error | AuthService | "Check your internet connection" | Auto-retry (3x) |
| Firestore read denied | FirestoreService | "You don't have access" | Re-authenticate |
| Firestore write fails offline | FirestoreService | "Saved offline — will sync" | Auto-sync on reconnect |
| Remote Config fetch timeout | RemoteConfigService | (silent — use defaults) | Next app launch |
| RevenueCat not configured | RevenueCatService | "Purchase unavailable" | Retry load |
| RevenueCat offering empty | PaywallScreen | "No offers available" | Refresh button |
| Purchase cancelled by user | PaywallScreen | (silent) | Stay on paywall |
| Purchase fails (network) | PaywallScreen | "Network error. Check connection." | Retry |
| Purchase fails (Google Play) | PaywallScreen | "Unable to process. Try again." | Retry or support |
| Restore no purchases | PaywallScreen | "No purchases found to restore" | Close dialog |
| Restore succeeds | PaywallScreen | "Purchases restored!" | Navigate to premium |
| Camera permission denied | ARHeightScreen | "Enable camera in settings" | Open settings button |
| AR not supported | ARHeightScreen | "AR not supported on this device" | Use manual entry |
| AR floor not detected | ARHeightScreen | "Point camera at floor" | Retry |
| AR measurement low confidence | ARHeightScreen | "Low confidence — try again" | Re-measure |
| YouTube video not found | WorkoutPlayer | "Video unavailable. Skip?" | Skip exercise |
| YouTube video restricted | WorkoutPlayer | "Playback restricted" | Skip exercise |
| AI Coach API timeout | AiCoachScreen | "Taking longer than expected..." | Wait |
| AI Coach daily limit | AiCoachScreen | "Daily message limit reached" | Upgrade or wait |
| Meal analysis timeout | NutritionTab | "Analysis taking longer..." | Wait or retry |
| Meal analysis parse error | NutritionTab | "Couldn't parse that meal" | Rephrase |
| Workout save offline | WorkoutPlayer | "Saved — will sync when online" | Automatic |
| Update data conflict | UpdateDataScreen | "Data conflict. Latest loaded." | Refresh and re-enter |
| Delete account needs re-auth | SettingsScreen | "Please re-authenticate to delete" | Re-authenticate |
| Delete account fails | SettingsScreen | "Delete failed. Contact support." | Contact support |
| Device rooted/jailbroken | PairIP | "App not authorized on this device" | None (blocked) |
| APK signature mismatch | PairIP | "App not authorized" | Reinstall from store |

---

# APPENDIX H: COMPLETE ANIMATION REFERENCE

## H.1 All Animation Properties

| Screen/Element | Animation Type | Duration | Curve | Trigger |
|---|---|---|---|---|
| Splash logo | FadeIn (opacity 0->1) | 800ms | easeInOut | On mount |
| Splash loading bar | Indeterminate spin | Infinite | linear | On mount |
| Welcome page slide | Horizontal slide | 350ms | iOS (easeIOC) | Swipe |
| Welcome dot display | Worm expand | 300ms | easeOutBack | On change |
| Welcome Get Started | FadeIn (opacity) | 500ms | easeInOut | Last page |
| Gender select card | Border color change | 200ms | easeInOut | On tap |
| Gender select icon | Scale (1.0->1.05->1.0) | 150ms | easeOutBack | On tap |
| Measurement card on focus | Border color change | 200ms | easeInOut | On focus |
| Measurement card on error | Border turns red | 150ms | easeInOut | On error |
| Sleep gauge | Circular fill | 400ms | easeOutCubic | Slider drag |
| Sleep gauge color | Cross-fade | 300ms | easeInOut | On change |
| Sleep shadow glow | Blur radius tween | 500ms | easeInOut | On change |
| Analyzing pulse | Scale (1.0<->1.15) | 3s | easeInOutSine | Repeat |
| Analyzing messages | Cross-fade | 300ms | easeOut | Timer |
| Height bars | Width growth | 600ms | easeOutCubic | On appear |
| Progress bar | Fill animation | 500ms | easeOut | On appear |
| Score gauge | Arc draw | 800ms | easeOutBack | On appear |
| Card entrance | TranslateY (20->0) | 400ms | easeOutCubic | Scroll in |
| Bottom nav icon | Color/fill tween | 200ms | easeInOut | Tab tap |
| Workout player | Slide up from bottom | 300ms | easeOutCubic | Navigator |
| Rest timer countdown | Int tween | Exact | linear | Set start |
| Rest timer appear | FadeIn (opacity) | 200ms | easeOut | Set start |
| Workout complete | Lottie checkmark | 1.5s | N/A (Lottie) | Trigger |
| Paywall appear | Slide up (modal) | 350ms | easeOutCubic | Navigator |
| Paywall card select | Border+scale(1.02) | 200ms | easeOutBack | Tap |
| Chart dot tap | Scale (1->1.5->1) | 300ms | easeOutBack | Tap |
| Chat bubble appear | Opacity + translateY | 200ms | easeOutCubic | New msg |
| AR button pulse | Scale (1->1.05->1) | 2s | easeInOutSine | Repeat |
| Back navigation | Slide (right) | Platform | Platform | System |

---

# APPENDIX I: CONFIGURATION FILES (RAW DATA)

## I.1 nutrition_targets.json Structure

```json
{
  "targets": {
    "5-8_any":     {"calories": 1600, "proteinG": 22, "calciumMg": 800, "vitaminDIU": 600, "waterL": 1.2},
    "9-13_male":   {"calories": 2000, "proteinG": 37, "calciumMg": 1000, "vitaminDIU": 600, "waterL": 1.8},
    "9-13_female": {"calories": 1800, "proteinG": 37, "calciumMg": 1000, "vitaminDIU": 600, "waterL": 1.6},
    "14-18_male":  {"calories": 2600, "proteinG": 56, "calciumMg": 1300, "vitaminDIU": 600, "waterL": 2.6},
    "14-18_female":{"calories": 2100, "proteinG": 49, "calciumMg": 1300, "vitaminDIU": 600, "waterL": 2.0},
    "19-30_male":  {"calories": 2700, "proteinG": 60, "calciumMg": 1000, "vitaminDIU": 600, "waterL": 3.0},
    "19-30_female":{"calories": 2100, "proteinG": 49, "calciumMg": 1000, "vitaminDIU": 600, "waterL": 2.2},
    "31-50_male":  {"calories": 2500, "proteinG": 60, "calciumMg": 1000, "vitaminDIU": 600, "waterL": 3.0},
    "31-50_female":{"calories": 1900, "proteinG": 49, "calciumMg": 1000, "vitaminDIU": 600, "waterL": 2.2}
  },
  "activityMultipliers": {
    "light": 1.2,
    "moderate": 1.4,
    "athlete": 1.6
  }
}
```

## I.2 notification_defaults.json Structure

```json
{
  "reminders": {
    "workoutTime": {"hour": 18, "minute": 0},
    "sleepTime": {"hour": 21, "minute": 30},
    "timezone": "user_local"
  },
  "streakSettings": {
    "atRiskAfterDaysMissed": 1,
    "brokenAfterDaysMissed": 3,
    "milestoneIntervalDays": 7
  },
  "reEngagement": {
    "firstDelayDays": 7,
    "secondDelayDays": 14,
    "thirdDelayDays": 30,
    "maxNotifications": 3
  },
  "weeklySummary": {
    "dayOfWeek": 7,
    "time": {"hour": 10, "minute": 0}
  }
}
```

---

# APPENDIX J: COMPLETE HAPTIC FEEDBACK MATRIX

| Interaction | Haptic Type | Android |
|---|---|---|
| Splash to navigate | lightImpact | Yes |
| Welcome "Get Started" tap | lightImpact | Yes |
| Gender card tap | selectionClick | Yes |
| Birth date selected | lightImpact | Yes |
| Measurement field focus | selectionClick | Yes |
| Sleep slider change end | selectionClick | Yes |
| Sports chip toggle | selectionClick | Yes |
| Activity level card tap | lightImpact | Yes |
| Puberty checkbox tap | selectionClick | Yes |
| Continue button tap | lightImpact | Yes |
| Bottom nav tab switch | selectionClick | Yes |
| Quick action card tap | lightImpact | Yes |
| Workout play/pause | mediumImpact | Yes |
| Workout skip next/prev | lightImpact | Yes |
| Workout exit confirm | heavyImpact | Yes |
| Rest timer complete | lightImpact | Yes |
| Workout complete | heavyImpact | Yes |
| Measurement addition | lightImpact | Yes |
| Measurement delete (swipe) | mediumImpact | Yes |
| AR scan start | heavyImpact | Yes |
| AR measurement complete | lightImpact | Yes |
| AR error | heavyImpact | Yes |
| Chat send message | lightImpact | Yes |
| Paywall purchase success | heavyImpact | Yes |
| Paywall purchase fail | error | Yes (API 30+) |
| Settings toggle switch | selectionClick | Yes |
| Rate app prompt accept | lightImpact | Yes |
| Error/shake feedback | error | Yes (API 30+) |
| Long press on button | heavyClick | Yes |

---

# APPENDIX K: HEIGHT CALCULATOR — COMPLETE TEST MATRIX

## K.1 Test Cases

| # | Gender | Age | Height | Weight | Father | Mother | Sleep | Activity | Sports | Puberty | Expected Predicted | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | M | 14 | 165 | 55 | 178 | 163 | 8.5 | moderate | basketball, swimming | growthSpurt | 182.3 | Optimal scenario |
| 2 | M | 17 | 172 | 62 | 175 | 160 | 6.5 | light | none | bodyHair, slower | 175.1 | Sleep deficit, low activity |
| 3 | F | 12 | 155 | 48 | 170 | 162 | 9.0 | athlete | gymnastics | growthSpurt | 169.7 | Ideal factors |
| 4 | M | 20 | 178 | 80 | 180 | 165 | 7.0 | moderate | soccer | all markers | 179.0 | Window closed |
| 5 | F | 8 | 128 | 25 | 0 | 158 | 10.0 | light | none | none | 163.2 | No father data |
| 6 | M | 16 | 170 | 60 | 185 | 170 | 8.0 | moderate | hanging, yoga | growthSpurt, bodyHair | 185.5 | Tall parents, good habits |
| 7 | F | 15 | 160 | 55 | 165 | 155 | 5.0 | light | none | growthSpurt, slower | 160.8 | Sleep deficit, late stage |
| 8 | M | 10 | 140 | 35 | 0 | 0 | 7.5 | light | swimming | none | 178.2 | No parent data |
| 9 | M | 25 | 175 | 75 | 175 | 162 | 7.0 | moderate | none | all markers | 175.0 | Adult, no growth left |
| 10 | F | 17 | 162 | 55 | 172 | 158 | 9.5 | athlete | volleyball, yoga | all markers | 164.5 | Near fusion |

## K.2 Validation Boundary Tests

| Field | Min Valid | Max Valid | Below Min | Above Max |
|---|---|---|---|---|
| Height (cm) | 50 | 250 | Error "below 50 cm" | Error "above 250 cm" |
| Weight (kg) | 15 | 350 | Error "below 15 kg" | Error "above 350 kg" |
| Age (years) | 5 | 80 | DatePicker blocks | DatePicker blocks |
| Father height (cm) | 120 | 250 | 119 -> Error | 251 -> Error |
| Mother height (cm) | 100 | 230 | 99 -> Error | 231 -> Error |
| Sleep (hours) | 0 | 14 | Slider prevents | Slider prevents |

---

# APPENDIX L: PERFORMANCE BUDGETS

| Metric | Budget | Measured (Pixel 5) |
|---|---|---|
| App cold start time | < 3s | ~2.1s |
| Time to interactive | < 5s | ~3.8s |
| Onboarding flow smoothness | 60fps | 55-60fps |
| Dashboard scroll jank | < 3 dropped frames | 1-2 dropped |
| Workout player startup | < 2s video load | ~1.5s |
| AI Coach response time | < 5s | ~2.3s avg |
| APK download size | < 20MB | 17.8MB |
| Memory peak (dashboard) | < 200MB | ~145MB |
| Memory peak (workout + video) | < 300MB | ~210MB |
| Firebase reads per screen | < 10 | ~5 |
| Firebase writes per action | 1-2 | 1 |
| Remote Config fetch | < 5s | ~2.1s |
| RevenueCat offering load | < 3s | ~1.5s |
| Asset image decode | < 100ms | ~45ms |

---

# APPENDIX M: ANDROID MANIFEST PERMISSIONS

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
```

---

# APPENDIX N: DEPENDENCY VERSIONS (resolved)

```
firebase_core:                2.24.2
firebase_auth:                4.16.0
cloud_firestore:             4.14.0
firebase_remote_config:      4.3.0
firebase_crashlytics:        3.4.0
firebase_analytics:          10.7.0
firebase_app_check:          0.2.0
firebase_messaging:          14.7.0
purchases_flutter:           6.21.0
flutter_riverpod:            2.4.9
riverpod_annotation:         2.3.5
go_router:                  13.0.1
youtube_player_flutter:      8.1.0
flutter_inappwebview:        6.0.0
cached_network_image:        3.3.1
lottie:                      2.7.0
shimmer:                     3.0.0
fl_chart:                    0.66.2
flutter_svg:                 2.0.9
intl:                        0.19.0
json_annotation:             4.8.1
freezed_annotation:          2.4.1
dartz:                       0.10.1
connectivity_plus:           5.0.2
package_info_plus:           5.0.1
device_info_plus:            9.1.1
permission_handler:          11.1.0
flutter_local_notifications: 16.1.0
share_plus:                  7.2.1
url_launcher:                6.2.2
in_app_review:               2.0.8
app_links:                   3.5.1
ar_flutter_plugin:           0.7.3
camera:                      0.10.5
```

---

**END OF APPENDICES A–N**
**HeightMax v2.7.3 (com.uza.apple) — 10,000+ Lines Total**
