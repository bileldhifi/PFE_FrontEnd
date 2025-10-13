# Assets Directory

This directory contains app assets including images, icons, and animations.

## Structure

```
assets/
├── images/        # App images and illustrations
├── icons/         # Custom icons and graphics
└── animations/    # Lottie animations (optional)
```

## Usage

Assets are referenced in code using:

```dart
// Images
Image.asset('assets/images/logo.png')

// Icons
SvgPicture.asset('assets/icons/custom_icon.svg')

// Animations
Lottie.asset('assets/animations/loading.json')
```

## Image Guidelines

- Use PNG for images with transparency
- Use JPEG for photos
- Use SVG for icons and vector graphics
- Provide @2x and @3x versions for different screen densities
- Optimize images before adding to reduce app size

## Icon Guidelines

- Use SVG format when possible
- Keep icons simple and clear
- Follow Material Design icon principles
- Size: 24x24dp or 48x48dp

## Animation Guidelines

- Use Lottie for complex animations
- Keep file sizes small (<200KB)
- Test on low-end devices

