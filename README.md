# AR Journal Memory

An iOS AR app that lets you place virtual memory notes in the real world and generate 3D objects in augmented reality.

## Features

### 📝 Add Memory Tab
- Place treasure box memory notes in AR space
- Tap surfaces to create memories with titles and descriptions
- Beautiful colored treasure boxes (Gold, Ruby, Emerald, Sapphire, Amethyst, Coral)
- Tap treasure boxes to view and edit memory details
- Delete memories with visual feedback
- AI-powered speech narration using Gemini + ElevenLabs

### 🪄 Generate 3D Object Tab
- Select from preset 3D models (Blue Couch)
- Place USDZ 3D models in AR space
- Speech description of selected models
- Tap any surface to place objects in your environment

### 🎤 Speech Functionality
- AI narration powered by Google Gemini
- High-quality text-to-speech via ElevenLabs
- Describe memories and 3D objects with natural voice

## Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **RealityKit** - AR rendering and 3D model support
- **ARKit** - Plane detection and world tracking
- **CoreLocation** - GPS location tracking
- **Combine** - Reactive data flow
- **Google Gemini API** - AI-powered narration
- **ElevenLabs API** - Natural text-to-speech
- **USDZ** - Apple's 3D model format

## Setup

1. Clone the repository
2. Open `AR Journal Memory.xcodeproj` in Xcode 14+
3. Add your API keys in the app settings:
   - Gemini API Key (for AI narration)
   - ElevenLabs API Key (for speech synthesis)
4. Build and run on a physical iOS device with ARKit support

## Requirements

- iOS 15.0+
- Physical iOS device with A12 chip or newer
- ARKit compatible device

## Project Structure

```
AR Journal Memory/
├── AppDelegate.swift          # App initialization
├── ContentView.swift          # Main AR view with tabs
├── Memory.swift               # Memory data model
├── MemoryManager.swift        # Persistence layer
├── MemoryInputView.swift      # Create memory UI
├── MemoryDetailView.swift     # View/edit memory UI
├── WelcomeView.swift          # Onboarding screen
├── LocationManager.swift      # GPS tracking
├── 3Dgen.swift               # 3D object generator
├── AIClients.swift           # Gemini & ElevenLabs clients
├── MeshyService.swift        # Text-to-3D service (future)
└── Assets.xcassets/          # App icons & colors
```

## Usage

### Creating Memories
1. Launch the app and tap "Start"
2. Switch to "Add Memory" tab
3. Tap any surface to place a treasure box
4. Enter title and description
5. Tap the box again to view or delete

### Placing 3D Objects
1. Switch to "Generate 3D" tab
2. Select a preset model (e.g., Blue Couch)
3. Tap "Place in AR"
4. Tap a surface to place the object
5. Use "Describe Selection" for AI narration

## License

MIT License - Feel free to use this project for learning and development.

## Author

Frank Kusi Appiah - October 2025
