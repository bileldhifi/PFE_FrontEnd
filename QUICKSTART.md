# 🚀 Super Simple Quick Start

## Just Run This One Command!

```bash
chmod +x clean_and_run.sh && ./clean_and_run.sh
```

That's it! The script will:
1. ✨ Clean all old files
2. 📦 Install dependencies  
3. 🔨 Generate code
4. 📱 Install iOS pods
5. 🚀 Run the app

---

## Alternative: Manual Steps

If you prefer to run commands manually:

```bash
# 1. Clean everything
rm -rf build/ ios/Pods/ ios/Podfile.lock .dart_tool/

# 2. Get dependencies
flutter pub get

# 3. Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

---

## 📱 Choose Your Device

The app will auto-select a device, or you can choose:

```bash
flutter run -d ios        # iOS Simulator
flutter run -d android    # Android Emulator  
flutter run -d chrome     # Web Browser
```

---

## ✨ What You'll See

- **Beautiful Login Screen** - Start here
- **Feed** - Travel posts with infinite scroll
- **My Trips** - Your trip collection
- **Trip Details** - Timeline & Gallery views
- **Profile** - User stats and settings
- **World Map** - Placeholder UI (no Google Maps needed!)

All with **fake data** ready to explore! 🎉

---

## 🔥 Hot Reload (While Running)

- Press `r` - Quick reload
- Press `R` - Full restart
- Press `q` - Quit

---

## 🆘 Having Issues?

**Just run the clean script again:**
```bash
./clean_and_run.sh
```

This fixes 99% of issues by starting fresh!

---

**That's it! Enjoy exploring the app! 🎨✨**
