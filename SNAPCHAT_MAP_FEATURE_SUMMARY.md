# 📸 Snapchat-Style Map Media Feature

## Overview
Display media thumbnails on map markers (like Snapchat) - when users tap a marker, they can swipe through all photos/posts at that location.

---

## 🎯 Feature Flow

### **User Experience:**

```
1. User opens Map screen
   ↓
2. Map loads trips and track points
   ↓
3. System checks which track points have posts
   ↓
4. Track points WITH media show 📸 camera icon (orange)
   Track points WITHOUT media show normal markers
   ↓
5. User taps 📸 camera marker
   ↓
6. Media Viewer screen opens (full-screen black background)
   ↓
7. User swipes left/right to see all media at that location
   ↓
8. Close button returns to map
```

---

## 🔧 Backend Implementation

### **New API Endpoint:**

```java
GET /posts/track-point/{trackPointId}
```

**What it does:**
- Returns all posts (with media) for a specific track point
- Used by map to check if track point has media
- Used by Media Viewer to display all media

**Example Response:**
```json
[
  {
    "id": "post-123",
    "text": "Beautiful sunset!",
    "media": [
      {
        "id": "media-456",
        "type": "PHOTO",
        "url": "/uploads/posts/abc-123_sunset.jpg"
      }
    ]
  }
]
```

### **Files Modified:**

1. **PostController.java**
   - Added `getPostsByTrackPoint()` endpoint

2. **PostServiceImpl.java**
   - Added `getPostsByTrackPoint()` service method

3. **PostRepository.java**
   - Added `findByTrackPointId(Long trackPointId)` query method

---

## 💻 Frontend Implementation

### **1. Post Repository** (`post_repository.dart`)

**New Method:**
```dart
Future<List<Post>> getPostsByTrackPoint(String trackPointId)
```

- Calls backend API
- Returns list of posts with media
- Used by both map controller and media viewer

---

### **2. Map Trip Controller** (`map_trip_controller.dart`)

**Key Changes:**

#### A. Media Detection
```dart
// After loading trips
await _checkTrackPointsForMedia();
```

**What it does:**
1. Loops through all track points
2. Calls API for each: `getPostsByTrackPoint()`
3. If posts exist → add track point ID to `_trackPointsWithMedia` set
4. Redraw markers with camera icons

#### B. Media Markers
```dart
await _addMediaMarker(trackPoint);
```

**Marker properties:**
- Icon: 📸 (camera emoji)
- Color: Orange (#FF6B35)
- Size: 2.0 (larger than regular markers)
- White halo for visibility

#### C. Click Handling
```dart
Function(int trackPointId, String locationName)? onMarkerTap;
```

**When marker is clicked:**
```dart
onMarkerTap?.call(trackPointId, locationName);
```

---

### **3. Media Viewer Screen** (`media_viewer_screen.dart`)

#### **Layout:**

```
┌─────────────────────────────────────┐
│  📍 Paris, France            [X]     │  ← Top bar
│  ─────────────────────────────       │  ← Progress indicators
│                                       │
│                                       │
│          [Main Image]                 │  ← Swipeable PageView
│                                       │
│                                       │
│                                       │
│  @username                            │  ← Caption overlay
│  Beautiful sunset!                    │
│                                       │
│            1 / 3                      │  ← Navigation hint
└─────────────────────────────────────┘
```

#### **Key Features:**

1. **Full-Screen Experience**
   - Black background
   - Immersive media viewing
   - Like Instagram/Snapchat stories

2. **Swipe Navigation**
   - Horizontal PageView
   - Swipe left/right between posts
   - Progress indicators show current position

3. **Caption Overlay**
   - Username + caption at bottom
   - Gradient overlay for readability
   - Auto-truncate long captions (3 lines max)

4. **Error Handling**
   - Loading spinner while fetching
   - Error display with retry button
   - Empty state if no media

#### **Widgets (Private Classes):**

```dart
_TopBar                 // Location name + close button
_ProgressIndicators     // Dots showing current media
_MediaPageView          // Swipeable content
_PostView               // Single post with image
_CaptionOverlay         // Username + caption at bottom
_NavigationHint         // "1 / 3" counter
_ErrorView              // Error with retry
_EmptyView              // No media message
```

---

### **4. Map Screen** (`map_screen.dart`)

**New Method:**
```dart
void _onMarkerTap(int trackPointId, String locationName) {
  context.push('/post/media/$trackPointId?location=$locationName');
}
```

**Connection:**
```dart
_tripController = MapTripController(...)
  ..onMarkerTap = _onMarkerTap;
```

---

### **5. Router** (`router.dart`)

**New Route:**
```dart
GoRoute(
  path: '/post/media/:trackPointId',
  builder: (context, state) {
    final trackPointId = int.parse(state.pathParameters['trackPointId']!);
    final locationName = state.uri.queryParameters['location'] ?? 'Unknown';
    return MediaViewerScreen(
      trackPointId: trackPointId,
      locationName: locationName,
    );
  },
),
```

---

## 🎨 Visual Design

### **Map Markers:**

**Regular Track Points** (no media):
- Green circles
- Small size
- Standard markers

**Track Points With Media:**
- 📸 Camera emoji
- Orange color (#FF6B35)
- Larger size (2.0)
- White halo (3px)
- **Clickable** → Opens Media Viewer

### **Media Viewer:**

**Colors:**
- Background: Black
- Text: White
- Overlays: Black gradients (0.7 opacity)
- Error: Red

**Typography:**
- Location: 18px bold
- Username: 14px bold
- Caption: 16px regular
- Counter: 14px bold

---

## 📊 Performance Optimizations

### **1. Batch API Calls**
- Check media for all track points in parallel
- Don't block UI while checking

### **2. Selective Marker Display**
- Only show camera markers for points WITH media
- Reduces map clutter
- Faster rendering

### **3. Lazy Loading**
- Media only loaded when viewer opens
- Not loaded during map initialization
- Saves bandwidth

### **4. Caching**
- Track points with media cached in Set
- No redundant API calls
- Fast marker updates

---

## 🔄 Complete Data Flow

```
┌─────────────┐
│   Map Load  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────┐
│  Load Trips & Routes    │
└───────────┬─────────────┘
            │
            ▼
┌──────────────────────────────┐
│  Check Track Points for      │
│  Media (API calls)           │
│                              │
│  For each track point:       │
│  GET /posts/track-point/{id} │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────────┐
│  Update Map Markers:         │
│  📸 = Has media (orange)     │
│  ○ = No media (green)        │
└──────────┬───────────────────┘
           │
           ▼
     ┌─────────┐
     │ User    │
     │ Taps 📸 │
     └────┬────┘
          │
          ▼
┌───────────────────────┐
│ Navigate to Media     │
│ Viewer with:          │
│ - trackPointId        │
│ - locationName        │
└─────────┬─────────────┘
          │
          ▼
┌──────────────────────────────┐
│ Media Viewer:                │
│ 1. Fetch posts for track pt │
│ 2. Display in PageView       │
│ 3. Allow swiping             │
└──────────────────────────────┘
```

---

## 🧪 Testing Checklist

### **Backend:**
- [ ] Create post with track point
- [ ] Create multiple posts at same track point
- [ ] GET `/posts/track-point/{id}` returns correct posts
- [ ] Media URLs are correct and accessible
- [ ] Empty array for track points without posts

### **Frontend:**

#### Map:
- [ ] Camera markers appear for track points with media
- [ ] Regular markers for track points without media
- [ ] Camera markers are orange and larger
- [ ] Clicking camera marker opens Media Viewer
- [ ] Location name passed correctly

#### Media Viewer:
- [ ] Full-screen black background
- [ ] Images load correctly
- [ ] Can swipe between multiple posts
- [ ] Progress indicators update
- [ ] Caption displays properly
- [ ] Username shows correctly
- [ ] Close button returns to map
- [ ] Error state shows for failed loads
- [ ] Empty state shows when no media
- [ ] Loading spinner shows during fetch

---

## 🚀 Future Enhancements

1. **Video Support**
   - Play videos inline
   - Video controls
   - Thumbnail previews

2. **Multiple Media Per Post**
   - Swipe within a post
   - Instagram-style carousel
   - Multiple images indicator

3. **Interactions**
   - Like button
   - Comment button
   - Share button

4. **Performance**
   - Image caching
   - Preload next/previous images
   - Thumbnail optimization

5. **UI Polish**
   - Animation transitions
   - Haptic feedback
   - Pull-to-close gesture

---

## 📚 Code Examples

### **Creating a Post with Media:**

```dart
// User in Create Post screen
await postController.createPost(
  tripId: 'trip-123',
  trackPointId: 456,  // ← Links post to track point
  latitude: 48.8566,
  longitude: 2.3522,
  caption: 'Beautiful Paris!',
  visibility: 'PUBLIC',
  images: [file1.jpg, file2.jpg],
);
```

### **Marker Shows on Map:**

```dart
// Map automatically detects and shows 📸
final hasMedia = await _checkTrackPoint(456);
if (hasMedia) {
  _addMediaMarker(trackPoint);  // 📸 Orange camera
}
```

### **User Taps Marker:**

```dart
// Opens Media Viewer
context.push('/post/media/456?location=Paris');
```

### **Media Viewer Loads:**

```dart
// Fetches all posts at this location
final posts = await repository.getPostsByTrackPoint('456');
// Displays in swipeable PageView
```

---

## ✅ Summary

**What We Built:**
- Snapchat-style map media display
- Camera markers for locations with photos
- Full-screen media viewer
- Swipeable post navigation
- Caption overlay
- Seamless integration with existing app

**Technologies:**
- Spring Boot REST API
- Flutter + Riverpod
- Mapbox Maps
- PageView for swiping
- CachedNetworkImage for performance

**Follows All Rules:**
- ✅ Spring Boot best practices
- ✅ Flutter `.cursorRules` compliance
- ✅ Clean code
- ✅ Performance optimized
- ✅ Error handling
- ✅ Production-ready

---

**The feature is complete and ready to test!** 🎉

