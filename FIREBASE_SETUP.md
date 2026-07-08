# Firebase Setup Guide for GetTaller

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name: `gettaller-app`
4. Disable Google Analytics (optional - can enable later)
5. Click "Create project"

## Step 2: Register Android App

1. In Firebase Console, click the Android icon (Add app)
2. Enter Android package name: `com.grayonix.GetTaller`
3. Enter app nickname: `GetTaller`
4. Enter SHA-1 signing certificate (for Crashlytics):
   ```bash
   keytool -list -v -keystore ~/GetTaller-Claude/android/app/release-key.jks -alias gettaller -storepass gettaller123
   ```
5. Click "Register app"

## Step 3: Download google-services.json

1. After registering, click "Download google-services.json"
2. Move the file to: `android/app/google-services.json`

## Step 4: Verify Setup

The file should be at:
```
android/app/google-services.json
```

## Step 5: Build Release APK

```bash
flutter build apk --release --dart-define=DEEPSEEK_API_KEY=your_key_here
```

## Troubleshooting

### "No Firebase App '[DEFAULT]' has been created"
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean` then rebuild

### "google-services.json is missing"
- Download from Firebase Console
- Place in `android/app/` directory

### Build fails with Firebase errors
- Run `flutter pub get`
- Run `flutter clean`
- Rebuild
