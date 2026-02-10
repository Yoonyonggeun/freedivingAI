# FreeDiving AI 🌊

AI-powered freediving training analysis app for iOS and Android.

## Overview

FreeDiving AI helps freedivers improve their technique by analyzing training videos and providing personalized feedback using MediaPipe pose detection and custom analysis algorithms.

## Features

### ✅ Completed

#### 1. Onboarding Flow
- Diver level selection (Beginner to Elite)
- Competition experience assessment
- Main disciplines selection (DYN, DNF, DYNB, CWT, CNF, FIM, STA)
- Personal bests input
- Training goals setup
- Beautiful gradient UI matching reference designs

#### 2. Core Infrastructure
- Flutter project setup
- Riverpod state management
- Hive local database
- Dark theme with custom design system
- Responsive UI with ScreenUtil

### 🚧 In Progress

#### 3. Static Apnea Training (Next)
- CO2 training tables
- O2 training tables
- Custom table configuration
- Timer with audio/vibration alerts
- Session history tracking

### 📋 Planned Features

#### 4. Video Analysis (Indoor Disciplines)
- Video upload/recording with shooting guides
- Streamline analysis (No-fin & Fin)
- Finning technique analysis (Bi-fins & Mono-fin)
- Arm stroke analysis (DNF)
- Breaststroke kick analysis (DNF)
- Dolphin kick analysis (Mono-fin)
- Turn analysis (multiple turn styles)
- Head position analysis
- Entry technique analysis

#### 5. Video Analysis (Depth Disciplines)
- Duck dive analysis
- Initial descent finning
- Arm stroke during descent/ascent
- FIM pulling technique
- Ascent posture analysis

#### 6. Analysis Results & Training Plans
- Score visualization
- Problem area highlights
- Video playback with synchronized feedback
- Improvement recommendations
- Personalized drill suggestions
- Progress tracking vs previous analyses

#### 7. Profile & History
- User profile management
- Training history by date/discipline
- Progress graphs and statistics
- PB updates
- Settings (notifications, units, language)
- Data backup/restore

## Tech Stack

- **Framework**: Flutter 3.35.1
- **State Management**: Riverpod
- **Local Storage**: Hive
- **Video Processing**: camera, video_player
- **AI/ML**: google_mlkit_pose_detection (MediaPipe)
- **UI**: flutter_screenutil, lottie
- **Routing**: go_router

## Project Structure

```
freediving_ai/
├── lib/
│   ├── core/
│   │   ├── constants/     # App constants
│   │   ├── theme/         # Theme and styles
│   │   ├── utils/         # Utility functions
│   │   └── extensions/    # Dart extensions
│   ├── features/
│   │   ├── onboarding/    # ✅ Onboarding flow
│   │   ├── static_training/  # Static apnea training
│   │   ├── dynamic_training/ # Video analysis
│   │   ├── analysis/      # Analysis results
│   │   ├── profile/       # User profile
│   │   └── home/          # Home screen
│   ├── services/
│   │   ├── camera/        # Camera service
│   │   ├── video/         # Video processing
│   │   ├── pose_detection/  # MediaPipe integration
│   │   └── storage/       # Local data storage
│   ├── models/            # Data models
│   └── main.dart          # App entry point
├── assets/
│   ├── images/
│   ├── animations/
│   └── guides/            # Shooting guide overlays
└── referenceImages/       # Design references
```

## Getting Started

### Prerequisites

- Flutter SDK 3.35.1+
- Dart 3.9.0+
- iOS development: Xcode, CocoaPods
- Android development: Android Studio, Android SDK

### Installation

1. Clone the repository:
```bash
cd freedivingAI/freediving_ai
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Development

### Running on iOS Simulator
```bash
flutter run -d "iPhone 15 Pro"
```

### Running on Android Emulator
```bash
flutter run -d emulator-5554
```

### Build for Production

iOS:
```bash
flutter build ios --release
```

Android:
```bash
flutter build apk --release
```

## Design References

The UI design is inspired by modern sports training apps with:
- Dark theme for reduced eye strain
- Gradient accents (pink to yellow)
- Clean, card-based layouts
- Emoji for visual engagement
- Progress indicators
- Smooth animations

Reference designs are available in `/referenceImages/`

## Disciplines Supported

### Indoor (Pool)
- **DYN** (Dynamic with Fins): Streamline, finning, turns, head position, entry
- **DNF** (Dynamic No Fins): Streamline, arm stroke, breaststroke kick, turns, start
- **DYNB** (Dynamic with Bi-fins): Dolphin kick, turns, head position, entry
- **STA** (Static Apnea): CO2/O2 training tables

### Depth
- **CWT** (Constant Weight): Duck dive, finning, arm stroke, head position
- **CNF** (Constant No Fins): Duck dive, arm stroke, breaststroke kick, head position
- **FIM** (Free Immersion): Entry, pulling technique, head position, ascent

## Timeline

- **Week 1** ✅: Project setup, onboarding
- **Week 2**: Static training, home screen enhancements
- **Week 3**: Video recording/upload, shooting guides
- **Week 4**: MediaPipe integration, basic analysis
- **Week 5**: Analysis logic refinement, results UI
- **Week 6**: Profile, history, polish
- **Week 7**: Testing, bug fixes
- **Week 8**: Beta release

## License

Private project - All rights reserved

## Contact

For questions or feedback, please contact the development team.
