# Deep Linking Setup Guide

This guide explains how to set up Android App Links for reel deep linking in the SkillConnect app.

## Prerequisites

- Android Studio installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Access to your Android keystore files

## Step 1: Generate SHA-256 Certificate Fingerprints

You need to generate SHA-256 fingerprints for both debug and release keystores.

### Debug Keystore (for development)

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

On Windows:
```cmd
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Release Keystore (for production)

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

You'll be prompted for the keystore password.

### Extract the SHA-256 Fingerprint

Look for the line that says `SHA256:` and copy the fingerprint. It will look like:
```
SHA256: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99
```

## Step 2: Update Digital Asset Links File

1. Open `public/.well-known/assetlinks.json`
2. Replace the placeholder fingerprints with your actual SHA-256 fingerprints:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.skillconnect",
    "sha256_cert_fingerprints": [
      "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99",
      "11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF"
    ]
  }
}]
```

## Step 3: Deploy to Firebase Hosting

Deploy the Digital Asset Links file and the fallback HTML page:

```bash
firebase deploy --only hosting
```

This will deploy:
- `public/.well-known/assetlinks.json` - For Android App Links verification
- `public/index.html` - Fallback page for users without the app

## Step 4: Deploy Cloud Functions

Deploy the updated `reelRedirect` function:

```bash
firebase deploy --only functions
```

## Step 5: Build and Install the App

Build the Android app with the updated AndroidManifest.xml:

```bash
flutter build apk --debug
```

Or for release:

```bash
flutter build apk --release
```

Install on your device:

```bash
flutter install
```

## Step 6: Verify App Links

### Method 1: Using ADB

Test the deep link using adb:

```bash
adb shell am start -a android.intent.action.VIEW -d "https://skill-connect-9d6b3.web.app/reels/abc123"
```

Replace `abc123` with an actual shortId from your Firestore.

### Method 2: Using Chrome

1. Open Chrome on your Android device
2. Navigate to: `https://skill-connect-9d6b3.web.app/reels/abc123`
3. The app should open automatically

### Method 3: Verify Digital Asset Links

Check if your assetlinks.json is accessible:

```
https://skill-connect-9d6b3.web.app/.well-known/assetlinks.json
```

Use Google's Digital Asset Links tester:
https://developers.google.com/digital-asset-links/tools/generator

## Troubleshooting

### App doesn't open automatically

1. **Check SHA-256 fingerprint**: Make sure the fingerprint in `assetlinks.json` matches your keystore
2. **Clear app data**: Go to Settings > Apps > SkillConnect > Storage > Clear Data
3. **Reinstall the app**: Uninstall and reinstall the app
4. **Check intent filter**: Verify the intent filter in `AndroidManifest.xml` is correct
5. **Wait for verification**: Android may take a few minutes to verify the App Links

### assetlinks.json returns 404

1. Make sure you deployed Firebase Hosting: `firebase deploy --only hosting`
2. Check that the file exists in the `public/.well-known/` directory
3. Verify the file is accessible at: `https://skill-connect-9d6b3.web.app/.well-known/assetlinks.json`

### Deep link opens browser instead of app

1. This is expected behavior for users without the app installed
2. The HTML page will attempt to open the app and show an install prompt if it fails
3. For users with the app, make sure App Links are verified (see above)

## Testing Checklist

- [ ] SHA-256 fingerprints generated for debug and release keystores
- [ ] `assetlinks.json` updated with correct fingerprints
- [ ] Firebase Hosting deployed
- [ ] Cloud Functions deployed
- [ ] App built and installed with updated AndroidManifest.xml
- [ ] Deep link tested with adb command
- [ ] Deep link tested from Chrome browser
- [ ] Deep link tested from WhatsApp/SMS
- [ ] Fallback HTML page displays correctly for users without app
- [ ] App opens to correct reel when deep link is clicked

## Production Deployment

Before releasing to production:

1. Generate release keystore SHA-256 fingerprint
2. Update `assetlinks.json` with release fingerprint
3. Deploy to Firebase Hosting
4. Build release APK/AAB
5. Test on a clean device (without debug app installed)
6. Upload to Google Play Store

## Additional Resources

- [Android App Links Documentation](https://developer.android.com/training/app-links)
- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Digital Asset Links](https://developers.google.com/digital-asset-links)
