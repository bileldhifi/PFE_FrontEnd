# Timeline Feature - Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Generate Code (REQUIRED!)
```bash
cd /Users/bilel.dhifi/Desktop/PFE/travel_diary_frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

**This will generate:**
- `timeline_item.freezed.dart`
- `timeline_item.g.dart`
- `timeline_response.freezed.dart`
- `timeline_response.g.dart`
- `trip_timeline_controller.freezed.dart`
- `trip_timeline_controller.g.dart`

### Step 2: Restart Backend
Make sure your Spring Boot backend is running:
```bash
cd /Users/bilel.dhifi/Desktop/PFE/exam
./mvnw spring-boot:run
```

### Step 3: Launch App
```bash
cd /Users/bilel.dhifi/Desktop/PFE/travel_diary_frontend
flutter run
```

---

## 📱 How to Use

1. Open the app
2. Navigate to **Trips** tab
3. Select any trip
4. Tap **Timeline** tab
5. Enjoy your beautiful journey timeline! 🎉

---

## 🎯 Features to Test

### ✅ Basic Features
- [ ] Timeline loads successfully
- [ ] Track points display in order
- [ ] Photos show in grids
- [ ] Captions are readable
- [ ] Stats display correctly

### ✅ Interactive Features
- [ ] Tap caption to expand/collapse
- [ ] Tap photo to open media viewer
- [ ] Pull down to refresh
- [ ] Scroll through timeline smoothly

### ✅ Responsive Design
- [ ] Works on phone (try rotating)
- [ ] Adapts to different screen sizes
- [ ] Photo grids adjust properly

### ✅ Visual Polish
- [ ] Timeline line connects dots
- [ ] Dots are color-coded
- [ ] Icons match activity
- [ ] Loading indicator shows
- [ ] Empty state displays if no data

---

## 🐛 Troubleshooting

### Problem: "The name '_$Timeline...' is defined in the libraries"
**Solution:** Run build_runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problem: "Timeline doesn't load / shows error"
**Solution:** Check backend is running and endpoint works:
```bash
curl http://localhost:8089/app-backend/trips/{YOUR_TRIP_ID}/timeline
```

### Problem: "Photos don't display"
**Solution:** Check:
1. Backend is serving media files
2. AppConstants.baseUrl is correct
3. Posts have media attached to track points

### Problem: "No timeline data"
**Solution:** 
1. Make sure trip has track points
2. Check track points have timestamps
3. Verify database has data

---

## 📊 API Endpoint

### GET `/trips/{tripId}/timeline`

**Response:**
```json
{
  "items": [
    {
      "trackPointId": 123,
      "timestamp": "2024-01-15T14:30:00Z",
      "latitude": 48.8566,
      "longitude": 2.3522,
      "locationName": null,
      "speedKmh": 2.5,
      "accuracyMeters": 5.0,
      "isSignificant": true,
      "distanceFromPreviousKm": 2.5,
      "timeFromPreviousSeconds": 3600,
      "posts": [...],
      "photoCount": 3
    }
  ],
  "stats": {
    "totalDistanceKm": 15.5,
    "totalDurationSeconds": 7200,
    "avgSpeedKmh": 3.2,
    "maxSpeedKmh": 25.0,
    "totalPhotos": 45,
    "totalTrackPoints": 30
  }
}
```

---

## 📚 Documentation

For complete details, see:
- `TRIP_TIMELINE_DESIGN.md` - Design specifications
- `TIMELINE_IMPLEMENTATION_SUMMARY.md` - Complete implementation details

---

## 🎨 Design Highlights

### Timeline Dot Colors
- 🔵 **Blue**: Regular point
- 🟣 **Purple**: Has media
- 🟠 **Orange**: Significant (glows!)

### Activity Icons
- 📍 Standing
- 🚶 Walking
- 🏃 Running
- 🚴 Cycling
- 🚗 Car
- ✈️ Plane

### Photo Grids
- **1 photo**: Full width
- **2-3 photos**: Grid layout
- **4+ photos**: Grid with "+N" overlay

---

## ✨ Enjoy Your Timeline!

The feature is complete and ready to use. Just run build_runner and launch the app!

**Questions?** Check the full documentation or inspect the code comments.

**Happy traveling! 🗺️✨**

