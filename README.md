# Dumette

Dumette is a simple macOS photo viewer that allows users to add folders or individual images and display them in a randomized, looped slideshow.

## Features

- Select folders or image files using an open panel
- Include or exclude subfolders from folder selections
- Randomized and looped slideshow order
- Arrow keys navigate images or pan when zoomed in
- `+` and `-` zoom in and out in 1% increments
- High-quality image rendering with preloading of adjacent images

## Build and Run

1. Open the workspace in Xcode or use Swift Package Manager.
2. In Terminal on macOS:
   ```bash
   cd /workspaces/dumette
   swift run
   ```
3. Or use the bundled helper script on macOS:
   ```bash
   bash run-macos.sh
   ```

## Requirements

- macOS 14 or later
- Swift 5.9
