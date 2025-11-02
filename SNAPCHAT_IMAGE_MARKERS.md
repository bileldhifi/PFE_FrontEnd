# Snapchat-Style Image Markers on Map

## Overview
This document describes the implementation of Snapchat-style image markers on the map, where actual post images are displayed instead of generic orange circles.

## Changes Made

### 1. Media Viewer Screen - Reduced Opacity
**File:** `lib/post/presentation/screens/media_viewer_screen.dart`

All glassmorphism widgets now have reduced opacity for better image visibility:
- Top bar location badge: `0.85` opacity (was `0.95`)
- Close button: `0.85` opacity
- Post counter badge: `0.85-0.80` gradient
- Username badge: `0.80-0.75` gradient  
- Caption card: `0.80-0.75` gradient
- Action buttons: `0.80-0.75` gradient

### 2. Map Controller - Image Markers
**File:** `lib/map/presentation/controllers/map_trip_controller.dart`

#### New Dependencies
```dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
```

#### Key Changes

**`_addMediaMarker()` Method:**
- Now fetches posts for each track point
- Downloads the first image from the first post
- Creates a circular image with white border and orange accent ring
- Adds the image as a map style icon
- Creates a PointAnnotation instead of CircleAnnotation
- Maintains click functionality

**New `_createCircularImageWithBorder()` Method:**
- Downloads and decodes the image
- Creates a 120x120px circular canvas
- Draws a white border (8px width)
- Clips the image to a circle
- Adds an orange accent ring (3px)
- Returns PNG bytes for the map marker

**New `ImageMarkerClickListener` Class:**
- Implements `OnPointAnnotationClickListener`
- Handles clicks on image markers
- Navigates to `MediaViewerScreen`

## Features

### Marker Design
- **Size:** 120x120px circular image
- **Border:** 8px white border
- **Accent:** 3px orange ring
- **Style:** Just like Snapchat's map markers!

### Behavior
- Automatically downloads post images
- Displays first image from first post at each location
- Click opens the full media viewer
- Gracefully handles missing images (no marker shown)

## How It Works

```
1. Map loads trips and track points
   ↓
2. For each track point with posts:
   - Fetch posts via PostRepository
   - Get first media URL
   ↓
3. Download image via HTTP
   ↓
4. Process image:
   - Decode to ui.Image
   - Draw white circle background
   - Clip image to circle
   - Add orange accent ring
   ↓
5. Add to map:
   - Add image to style with unique ID
   - Create PointAnnotation
   - Attach click listener
   ↓
6. User clicks marker:
   - Navigate to MediaViewerScreen
   - Show all posts for that location
```

## API Requirements

- Posts must have media with valid URLs
- Images must be accessible at: `http://localhost:8089/app-backend/[url]`
- Backend must support CORS for image loading

## Testing

To test the feature:
1. Create posts with images at specific track points
2. View the map for that trip
3. Verify circular image markers appear
4. Click markers to open media viewer
5. Verify images load correctly

## Notes

- The `http` package is already in `pubspec.yaml`
- Images are cached by Mapbox style
- Unique image IDs prevent conflicts: `media_marker_${trackPointId}`
- Fallback: If image fails to load, no marker is shown
- Performance: Images are downloaded asynchronously

## Future Enhancements

- Add image caching to avoid re-downloading
- Support for multiple markers at same location (cluster)
- Animation when markers appear
- Show number badge if location has multiple posts
- Lazy loading: only download visible markers

