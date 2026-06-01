# Hybrid App Multi-Stack Integration Demo

A demonstration project integrating **Native (iOS/Android)**, **React Native**, **Flutter**, and **WebView** into a unified hybrid application with cross-stack routing and communication.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Native Layer                       │
│  ┌───────────┐  ┌───────────┐  ┌────────────────┐  │
│  │  AppRouter│  │  EventBus │  │ Bridge Adapters│  │
│  │ (URL-based│  │ (Message  │  │ ┌──┐ ┌──┐ ┌──┐│  │
│  │  dispatch)│  │  broker)  │  │ │RN│ │FL│ │WV││  │
│  └─────┬─────┘  └─────┬─────┘  │ └──┘ └──┘ └──┘│  │
│        │               │        └────────────────┘  │
└────────┼───────────────┼────────────────────────────┘
         │               │
    ┌────┴────┐    ┌─────┴─────┐
    │ Routing │    │  Message  │
    │ Dispatch│    │ Forwarding│
    └────┬────┘    └─────┬─────┘
         │               │
┌────────┼───────────────┼────────────────────────────┐
│   ┌────▼────┐  ┌───────▼──┐  ┌──────────┐          │
│   │  React  │  │  Flutter  │  │  WebView │          │
│   │  Native │  │  Module   │  │  (HTML)  │          │
│   └─────────┘  └──────────┘  └──────────┘          │
│              Cross-Platform Modules                   │
└─────────────────────────────────────────────────────┘
```

## Project Structure

```
MyDemoProject/
├── iOSDemoProject/          # iOS native app (UIKit + Swift)
├── AndroidDemoProject/      # Android native app (Kotlin + Jetpack Compose)
├── ReactNativeModule/       # React Native module (TypeScript)
├── FlutterModule/           # Flutter module (Dart)
├── WebModule/               # WebView pages (HTML + JavaScript)
└── SharedProtocol/          # Protocol documentation & JSON schemas
```

## Routing System

All navigation uses a unified URL-scheme format:

```
app://{stack}/{page}?{params}
```

| Route | Target |
|-------|--------|
| `app://native/home` | Native hub page |
| `app://native/demo` | Native communication demo |
| `app://rn/home` | React Native home |
| `app://rn/detail?id=123` | React Native detail page |
| `app://flutter/home` | Flutter home |
| `app://flutter/detail?id=456` | Flutter detail page |
| `app://webview?url=...` | WebView with specified URL |

Any tech stack can navigate to any other by calling the Router with a URL string.

## Communication Protocol

A JSON-based event bus supporting four message types:

| Type | Description | Use Case |
|------|-------------|----------|
| `request` | Expects a response | Fetch data from another stack |
| `response` | Reply to a request | Return requested data |
| `notification` | One-way, specific target | Analytics, logging |
| `broadcast` | One-way, all stacks | Theme changes, state sync |

### Message Format

```json
{
  "id": "uuid",
  "type": "request",
  "channel": "getUserInfo",
  "source": "rn",
  "target": "native",
  "payload": { "userId": "42" },
  "callbackId": "uuid",
  "timestamp": 1717200000000
}
```

## Getting Started

### Prerequisites

- **iOS**: Xcode 15+, CocoaPods
- **Android**: Android Studio Ladybug+, JDK 11+
- **React Native**: Node.js 18+, npm/yarn
- **Flutter**: Flutter SDK 3.0+

### Setup

#### 1. React Native Module

```bash
cd ReactNativeModule
npm install
```

#### 2. Flutter Module

```bash
cd FlutterModule
flutter pub get
```

#### 3. iOS Project

```bash
# Open in Xcode
open iOSDemoProject/iOSDemoProject.xcodeproj
```

In Xcode:
1. Select target → General → Remove `Main` from "Main Interface"
2. Build & Run (`Cmd + B`, then `Cmd + R`)

For full RN/Flutter integration, uncomment dependencies in `Podfile` and run:
```bash
cd iOSDemoProject
pod install
open iOSDemoProject.xcworkspace
```

#### 4. Android Project

```bash
# Open in Android Studio
open -a "Android Studio" AndroidDemoProject
```

Android Studio will auto-sync Gradle. Click Run to build.

For full Flutter integration, uncomment the Flutter module include in `settings.gradle.kts`.

### Flutter Permission Fix (if needed)

```bash
sudo chown -R $(whoami) ~/flutter/bin/cache
```

## Demo Features

### Navigation Demo
- **Full Circle**: Native → RN → Flutter → WebView → Native
- Each page has buttons to navigate to all other tech stacks
- Parameters are passed via URL query strings

### Communication Demo
- **Request/Response**: Native sends `getUserInfo` to RN, receives response
- **Broadcast**: Flutter broadcasts `themeChanged`, all stacks receive it
- **Notification**: WebView sends one-way `analytics` event to Native
- **Event Log**: Each page displays received messages in real-time

## Key Files

### iOS
| File | Purpose |
|------|---------|
| `Router/AppRouter.swift` | Central URL-scheme router |
| `EventBus/EventBus.swift` | Message broker singleton |
| `Bridges/WebViewBridge/WebViewContainerViewController.swift` | WebView with JS bridge |
| `Bridges/RNBridge/RNContainerViewController.swift` | RN container |
| `Bridges/FlutterBridge/FlutterContainerViewController.swift` | Flutter container |

### Android
| File | Purpose |
|------|---------|
| `router/AppRouter.kt` | Central URL-scheme router |
| `eventbus/EventBus.kt` | Message broker singleton |
| `bridges/webview/WebViewContainerActivity.kt` | WebView with JS interface |
| `bridges/rn/RNContainerActivity.kt` | RN container |
| `bridges/flutter/FlutterContainerActivity.kt` | Flutter container |

### Cross-Platform
| File | Purpose |
|------|---------|
| `ReactNativeModule/src/bridge/NativeEventBus.ts` | RN-side event bus wrapper |
| `FlutterModule/lib/bridge/native_event_bus.dart` | Flutter-side event bus wrapper |
| `WebModule/js/bridge.js` | WebView JS bridge (auto-detects iOS/Android) |

## Integration Notes

The current demo uses **placeholder containers** for RN and Flutter (native UI simulating their pages). This allows the project to build and run without requiring the full RN/Flutter SDK setup. The WebView bridge is fully functional.

To enable real RN/Flutter integration:
1. Uncomment SDK dependencies in `Podfile` / `settings.gradle.kts`
2. Replace placeholder containers with actual `RCTRootView` / `FlutterViewController`
3. The bridge modules (`NativeEventBus.ts`, `native_event_bus.dart`) are already production-ready

## License

MIT
