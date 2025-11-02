# Trip Timeline Feature - Design Document

## Overview
A beautiful, responsive timeline view showing the user's journey through track points with associated media, location details, and travel statistics.

---

## Design Inspiration

### Style: Modern Travel App Timeline
- **Visual Style**: Clean, card-based with a prominent vertical timeline
- **Colors**: Primary brand colors with contextual indicators
- **Spacing**: Generous padding for readability
- **Animations**: Smooth transitions and subtle animations

### Key Design Elements
```
┌────────────────────────────────────┐
│  Trip Detail Screen                │
│  ┌──────────────────────────────┐  │
│  │  [Timeline] [Map] [Gallery]  │  │
│  └──────────────────────────────┘  │
│                                    │
│   🔵──────── Timeline Line         │
│   │                                │
│   ●  📍 Paris, France              │
│   │  ┌────────────────────────┐   │
│   │  │  🖼️ Photo Grid          │   │
│   │  │  📝 Caption            │   │
│   │  │  ⏱️ 14:30 • 🚶 2.5 km/h │   │
│   │  └────────────────────────┘   │
│   │                                │
│   ●  📍 Eiffel Tower               │
│   │  ┌────────────────────────┐   │
│   │  │  🖼️ Photo Grid          │   │
│   │  │  📝 Caption            │   │
│   │  │  ⏱️ 15:45 • 🚶 3.1 km/h │   │
│   │  └────────────────────────┘   │
│   │                                │
│   ●  📍 Louvre Museum              │
│      ┌────────────────────────┐   │
│      │  No photos              │   │
│      │  ⏱️ 17:20 • 🚗 25 km/h  │   │
│      └────────────────────────┘   │
│                                    │
└────────────────────────────────────┘
```

---

## Data Structure

### Timeline Item Model
```dart
class TimelineItem {
  // Track Point Data
  final int trackPointId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? locationName;
  final double? speedKmh;
  final double? accuracyMeters;
  final bool isSignificant;
  
  // Calculated Data
  final double? distanceFromPrevious;  // in km
  final Duration? timeFromPrevious;
  
  // Associated Media
  final List<Post> posts;
  final int photoCount;
  
  // UI State
  final bool hasMedia;
  final IconData icon;  // Based on speed/activity
  final Color color;     // Based on significance
}
```

### Backend Endpoint
```
GET /trips/{tripId}/timeline

Response:
{
  "items": [
    {
      "trackPointId": 123,
      "timestamp": "2024-01-15T14:30:00Z",
      "latitude": 48.8566,
      "longitude": 2.3522,
      "locationName": "Paris, France",
      "speedKmh": 2.5,
      "accuracyMeters": 5.0,
      "isSignificant": true,
      "distanceFromPrevious": 2.5,
      "timeFromPrevious": 3600,
      "posts": [
        {
          "id": "uuid",
          "caption": "Amazing view!",
          "media": [...],
          "createdAt": "2024-01-15T14:35:00Z"
        }
      ],
      "photoCount": 3
    },
    ...
  ],
  "stats": {
    "totalDistance": 15.5,
    "totalDuration": 7200,
    "avgSpeed": 3.2,
    "maxSpeed": 25.0,
    "totalPhotos": 45
  }
}
```

---

## UI Components

### 1. Timeline Item Card

#### Design Specs
```dart
_TimelineItemCard {
  // Layout
  - Row with timeline indicator (60px) + content (flexible)
  - Timeline vertical line (2px, primary color with 30% opacity)
  - Timeline dot (24px circle, filled primary color)
  - Content card with 16px padding, rounded corners (12px)
  
  // Colors
  - Normal point: Blue
  - Significant point: Orange with glow
  - With media: Purple accent
  - No media: Grey
  
  // Spacing
  - Bottom margin: 16px between cards
  - Horizontal padding: 16px screen edges
  - Internal padding: 12-16px
  
  // Responsive
  - Mobile (< 600px): Single column, compact spacing
  - Tablet (600-1200px): Larger cards, more spacing
  - Desktop (> 1200px): Maximum width 800px, centered
}
```

#### Components
1. **Header**
   - 📍 Location icon + Location name (bold)
   - ⏱️ Time (small, grey)
   - 🏁 Distance from previous (if available)

2. **Photo Grid** (if posts available)
   - 1 photo: Full width, 16:9 aspect ratio
   - 2 photos: 2 columns
   - 3+ photos: 2x2 grid with "+N" overlay
   - Rounded corners (8px)
   - Tap to open media viewer

3. **Caption** (if post has caption)
   - White text on semi-transparent dark background
   - Max 3 lines with "Read more" expansion
   - Gradient fade at bottom

4. **Stats Bar**
   - Row of chips showing:
     - 🚶 Speed (with icon based on value)
     - 📏 Distance traveled
     - 🎯 Accuracy
     - ⏱️ Time duration
   - Small chips with icons, rounded, subtle background

5. **Actions** (on long press or swipe)
   - View on map
   - Share location
   - Add photo
   - Edit

---

### 2. Timeline Connector

```dart
_TimelineConnector {
  // Visual
  - Vertical line: 2px solid
  - Color: Primary color with 30% opacity
  - Dashed for long distances (>5km)
  - Animated gradient for active travel
  
  // Position
  - Centered on timeline dot
  - Connects all points seamlessly
  - First point: No top line
  - Last point: Fade out bottom line
}
```

---

### 3. Special Markers

#### Start Marker
```dart
_StartMarker {
  - Large green circle (32px)
  - 🚀 Rocket icon
  - "Trip Started" label
  - Shows date/time
  - Animated pulse effect
}
```

#### End Marker
```dart
_EndMarker {
  - Large red circle (32px)
  - 🏁 Flag icon
  - "Trip Ended" label
  - Shows date/time
  - Summary card below
}
```

#### Significant Point
```dart
_SignificantMarker {
  - Orange circle (28px)
  - ⭐ Star icon
  - Glow effect
  - Larger card
  - Prominent display
}
```

---

### 4. Empty States

#### No Track Points
```dart
_EmptyTimeline {
  - Center icon: 🗺️ Map outline
  - Title: "No Journey Data"
  - Message: "Track points will appear as you travel"
  - Action button: "Start Tracking"
}
```

#### No Media
```dart
_NoMediaIndicator {
  - Small grey icon: 📷
  - Text: "No photos at this location"
  - Subtle, doesn't dominate the card
}
```

---

## Responsive Design

### Mobile (< 600px)
```dart
ResponsiveTimeline {
  timelineWidth: 40px,
  dotSize: 20px,
  cardPadding: 12px,
  photoGridColumns: 2,
  maxImageHeight: 200px,
  fontSize: {
    title: 16px,
    body: 14px,
    small: 12px,
  }
}
```

### Tablet (600-1200px)
```dart
ResponsiveTimeline {
  timelineWidth: 60px,
  dotSize: 24px,
  cardPadding: 16px,
  photoGridColumns: 3,
  maxImageHeight: 300px,
  fontSize: {
    title: 18px,
    body: 16px,
    small: 14px,
  }
}
```

### Desktop (> 1200px)
```dart
ResponsiveTimeline {
  timelineWidth: 80px,
  dotSize: 28px,
  cardPadding: 20px,
  photoGridColumns: 4,
  maxImageHeight: 400px,
  maxContentWidth: 900px,  // Centered
  fontSize: {
    title: 20px,
    body: 16px,
    small: 14px,
  }
}
```

---

## Interactions

### 1. Card Tap
- Expand/collapse full caption
- Show all metadata
- Animate expansion smoothly

### 2. Photo Tap
- Open media viewer (existing Snapchat-style viewer)
- Show all posts at this location
- Swipeable between photos

### 3. Location Tap
- Navigate to map tab
- Center on this location
- Highlight the point

### 4. Long Press
- Show context menu:
  - View on map
  - Share
  - Add photo
  - Edit

### 5. Pull to Refresh
- Reload timeline data
- Smooth animation
- Show loading indicator

---

## Performance Optimizations

### 1. Lazy Loading
```dart
ListView.builder(
  itemCount: timelineItems.length,
  itemBuilder: (context, index) {
    return _TimelineItemCard(item: timelineItems[index]);
  },
)
```

### 2. Image Caching
```dart
CachedNetworkImage(
  imageUrl: mediaUrl,
  cacheKey: "timeline_${trackPointId}_${mediaId}",
  memCacheWidth: 800,  // Resize for performance
)
```

### 3. Pagination
```dart
// Load 20 items at a time
// Load more when scrolled to bottom
if (scrollController.position.pixels == 
    scrollController.position.maxScrollExtent) {
  loadMoreTimelineItems();
}
```

---

## Flutter Best Practices

### 1. State Management ✅
```dart
@riverpod
class TimelineController extends _$TimelineController {
  @override
  Future<TimelineState> build(String tripId) async {
    return _fetchTimeline(tripId);
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTimeline(tripId));
  }
}
```

### 2. Responsive Helper ✅
```dart
class _ResponsiveTimeline {
  final BuildContext context;
  
  late final double screenWidth;
  late final double timelineWidth;
  late final double dotSize;
  late final double cardPadding;
  
  _ResponsiveTimeline(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      // Mobile
      timelineWidth = 40;
      dotSize = 20;
      cardPadding = 12;
    } else if (screenWidth < 1200) {
      // Tablet
      timelineWidth = 60;
      dotSize = 24;
      cardPadding = 16;
    } else {
      // Desktop
      timelineWidth = 80;
      dotSize = 28;
      cardPadding = 20;
    }
  }
}
```

### 3. Theme Usage ✅
```dart
// Always use Theme.of(context)
Text(
  locationName,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
  ),
)
```

### 4. Widget Composition ✅
```dart
// Small, reusable widgets
class _TimelineDot extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSignificant;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: isSignificant ? [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }
}
```

---

## Icon Mapping

### Speed-Based Icons
```dart
IconData getActivityIcon(double? speedKmh) {
  if (speedKmh == null) return Icons.circle;
  if (speedKmh < 1) return Icons.place;              // Standing
  if (speedKmh < 5) return Icons.directions_walk;    // Walking
  if (speedKmh < 15) return Icons.directions_run;    // Running/Cycling
  if (speedKmh < 50) return Icons.directions_bike;   // Cycling fast
  if (speedKmh < 120) return Icons.directions_car;   // Car
  return Icons.flight;                                // Plane
}
```

### Color Mapping
```dart
Color getPointColor(BuildContext context, TimelineItem item) {
  final theme = Theme.of(context);
  
  if (item.isSignificant) {
    return Colors.orange;  // Important location
  }
  
  if (item.hasMedia) {
    return Colors.purple;  // Has photos
  }
  
  return theme.colorScheme.primary;  // Regular point
}
```

---

## Accessibility

### 1. Semantic Labels
```dart
Semantics(
  label: 'Location: $locationName at ${formatTime(timestamp)}',
  child: _TimelineItemCard(...),
)
```

### 2. High Contrast
```dart
// Ensure text contrast ratios meet WCAG AA standards
// Use theme colors that adapt to light/dark mode
```

### 3. Large Touch Targets
```dart
// Minimum 48x48 logical pixels for interactive elements
GestureDetector(
  onTap: onTap,
  child: Container(
    constraints: BoxConstraints(minHeight: 48, minWidth: 48),
    child: child,
  ),
)
```

---

## Error Handling

### 1. Network Errors
```dart
if (state.hasError) {
  return _ErrorTimeline(
    message: 'Failed to load timeline',
    onRetry: () => ref.refresh(timelineControllerProvider(tripId)),
  );
}
```

### 2. Missing Data
```dart
if (item.locationName == null) {
  locationName = '${item.latitude.toStringAsFixed(4)}, '
                 '${item.longitude.toStringAsFixed(4)}';
}
```

### 3. Image Loading Errors
```dart
CachedNetworkImage(
  imageUrl: mediaUrl,
  errorWidget: (context, url, error) => Container(
    color: Colors.grey.shade200,
    child: Icon(Icons.broken_image, color: Colors.grey),
  ),
)
```

---

## Summary

### Key Features
✅ **Beautiful vertical timeline** with connecting lines
✅ **Photo grid integration** with posts at each location
✅ **Travel statistics** (speed, distance, time)
✅ **Responsive design** for all screen sizes
✅ **Interactive elements** (tap, expand, navigate)
✅ **Performance optimized** with lazy loading and caching
✅ **Theme compliant** using Theme.of(context)
✅ **Accessible** with semantic labels and high contrast

### Technology Stack
- **State Management**: Riverpod 2.x
- **Navigation**: GoRouter
- **Image Caching**: cached_network_image
- **Models**: Freezed
- **Responsive**: MediaQuery + LayoutBuilder
- **Theme**: Material 3 Design

### Next Steps
1. ✅ Create backend endpoint `/trips/{tripId}/timeline`
2. ✅ Implement Flutter repository method
3. ✅ Create timeline controller with Riverpod
4. ✅ Build responsive UI components
5. ✅ Integrate into TripDetailScreen
6. ✅ Test on all device sizes
7. ✅ Polish animations and interactions

**This timeline will provide a stunning, Instagram/Snapchat-style journey visualization! 🗺️✨**

