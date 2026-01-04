# App Icon Fix Instructions

## Problem
The app icon is being cut off on mobile screens because it doesn't have enough padding around it.

## Solution
You need to add transparent padding around your logo image.

## Option 1: Manual Edit (Recommended)
1. Open `assets/icons/logo.png` in an image editor (Photoshop, GIMP, Figma, etc.)
2. Increase the canvas size by 20-25% on all sides
3. Keep the logo centered
4. Fill the extra space with transparency
5. Save the file

**Example:**
- If your logo is 512x512px
- Increase canvas to 640x640px (25% larger)
- Center the original logo
- The extra 64px on each side will be transparent

## Option 2: Use Online Tool
1. Go to https://www.iloveimg.com/resize-image or similar
2. Upload your logo
3. Add padding/border with transparent background
4. Download and replace `assets/icons/logo.png`

## Option 3: Create Separate Icon File
Create a new file `assets/icons/app_icon.png` with proper padding and update pubspec.yaml:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"  # New padded icon
  adaptive_icon_background: "#FFFFFF" 
  adaptive_icon_foreground: "assets/icons/app_icon.png"
```

## After Fixing the Image

Run these commands:
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
flutter clean
flutter run
```

## Recommended Icon Sizes

**For best results, create your icon with these dimensions:**
- **Android Adaptive Icon**: 432x432px (with 108px safe zone padding on all sides)
- **iOS Icon**: 1024x1024px (with ~10% padding)
- **General**: Keep important content within the center 80% of the image

## Safe Zone Guide
```
┌─────────────────────────┐
│  Padding (transparent)  │
│  ┌─────────────────┐   │
│  │                 │   │
│  │   Your Logo     │   │
│  │   (centered)    │   │
│  │                 │   │
│  └─────────────────┘   │
│  Padding (transparent)  │
└─────────────────────────┘
```

The logo should occupy about 60-70% of the total canvas, with the rest being transparent padding.
