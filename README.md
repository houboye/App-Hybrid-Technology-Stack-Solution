# Hybrid App Multi-Stack Integration Demo

A demonstration project integrating **Native (iOS/Android)**, **React Native**, **Flutter**, and **WebView** into a unified hybrid application with cross-stack routing, communication, and page data transfer.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Native Layer                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │ AppRouter│  │ EventBus │  │ PageData │  │  Bridges   │  │
│  │(URL路由) │  │(消息中转) │  │(数据传递) │  │┌──┐┌──┐┌──┐│  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  ││RN││FL││WV││  │
│       │              │              │        │└──┘└──┘└──┘│  │
│       │              │              │        └───────────┘  │
└───────┼──────────────┼──────────────┼───────────────────────┘
        │              │              │
   ┌────┴────┐   ┌─────┴─────┐  ┌────┴────┐
   │ Routing │   │  Message  │  │  Data   │
   │ Dispatch│   │ Forwarding│  │Transfer │
   └────┬────┘   └─────┬─────┘  └────┬────┘
        │              │              │
┌───────┼──────────────┼──────────────┼───────────────────────┐
│  ┌────▼────┐   ┌─────▼────┐   ┌────▼─────┐                │
│  │  React  │   │  Flutter │   │  WebView │                │
│  │  Native │   │  Module  │   │  (HTML)  │                │
│  └─────────┘   └──────────┘   └──────────┘                │
│                Cross-Platform Modules                        │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
App-Hybrid-Technology-Stack-Solution/
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

---

## Communication Protocol

The system provides **two coexisting communication methods**. Choose based on your use case, or combine both:

| Method | Best For | Lifecycle |
|--------|----------|-----------|
| **EventBus** | Real-time messaging, pub/sub, fire-and-forget | Transient (no persistence) |
| **PageData** | Passing complex data during page navigation | Persists until consumed or TTL expires |

---

### EventBus

A JSON-based event bus supporting four message types:

| Type | Description | Use Case |
|------|-------------|----------|
| `request` | Expects a response | Fetch data from another stack |
| `response` | Reply to a request | Return requested data |
| `notification` | One-way, specific target | Analytics, logging |
| `broadcast` | One-way, all stacks | Theme changes, state sync |

#### Message Format

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

#### Platform Usage

**iOS (Swift)**
```swift
// Send request and wait for response
EventBus.shared.sendRequest(to: .rn, channel: "getUserInfo", payload: ["userId": AnyCodable("1")]) { response in
    print(response.payload)
}

// Broadcast to all stacks
EventBus.shared.broadcast(channel: "themeChanged", payload: ["theme": AnyCodable("dark")])

// Subscribe to events
EventBus.shared.subscribe(channel: "greeting") { message in
    print("[\(message.source)] \(message.payload)")
}
```

**React Native (TypeScript)**
```typescript
import { NativeEventBus } from './bridge/NativeEventBus';

const response = await NativeEventBus.sendRequest('native', 'getUserInfo', { userId: '1' });
NativeEventBus.broadcast('greeting', { message: 'Hello!' });
const unsubscribe = NativeEventBus.subscribe('*', (msg) => console.log(msg));
```

**Flutter (Dart)**
```dart
import 'bridge/native_event_bus.dart';

final response = await NativeEventBus.sendRequest('native', 'getUserInfo', {'userId': '1'});
NativeEventBus.broadcast('themeChanged', {'theme': 'dark'});
final unsub = NativeEventBus.subscribe('*', (msg) => print(msg.payload));
```

**WebView (JavaScript)**
```javascript
AppEventBus.sendRequest('native', 'getUserInfo', { userId: '42' }).then(function(resp) { ... });
AppEventBus.broadcast('greeting', { message: 'Hello from WebView!' });
AppEventBus.subscribe('*', function(msg) { console.log(msg); });
```

---

### PageData

A cross-stack page-to-page data transfer mechanism for passing complex objects during navigation.

#### Why PageData?

URL query parameters only support simple string key-value pairs. PageData lets you pass complex objects (user profiles, lists, configs) between pages by:

1. Storing data in a centralized native store before navigation
2. Passing only a lightweight `_dataId` reference in the URL
3. Target page retrieves (and consumes) the full data object

#### Data Flow

```
Source Page                    Native Layer                 Target Page
     │                              │                           │
     │── put(data) ────────────────▶│                           │
     │◀─── dataId ─────────────────│                           │
     │                              │                           │
     │── navigate(url?_dataId=xxx)─▶│── route to target ──────▶│
     │                              │                           │
     │                              │◀── consume(dataId) ──────│
     │                              │── return data ───────────▶│
```

#### Platform Usage

**iOS (Swift)**
```swift
// Navigate with data (one-step)
AppRouter.shared.navigate(
    to: "app://flutter/detail?id=123",
    data: ["user": ["name": "John", "age": 30], "token": "abc"]
)

// Manual: store then navigate
let dataId = PageDataStore.shared.put(source: .native, target: .rn, route: "app://rn/home", data: ["items": [1, 2, 3]])

// Consume on target page
let entry = PageDataStore.shared.consume(dataId: dataId)
```

**React Native (TypeScript)**
```typescript
import { NativeRouter } from './bridge/NativeRouter';
import { PageData } from './bridge/PageData';

// Navigate with data (one-step)
await NativeRouter.navigateWithData('app://flutter/home', { user: { name: 'John' } });

// Consume on target page
if (props._dataId) {
  const entry = await PageData.consume(props._dataId);
  console.log(entry?.data);
}
```

**Flutter (Dart)**
```dart
import 'bridge/native_router.dart';
import 'bridge/page_data.dart';

// Navigate with data
await NativeRouter.navigateWithData('app://rn/home', {'user': {'name': 'John'}});

// Consume on target page
final entry = await PageData.consume(dataId);
```

**WebView (JavaScript)**
```javascript
// Navigate with data
PageData.navigateWithData('app://rn/home', { message: 'Hello', list: [1, 2, 3] });

// Auto-consume on target page (reads _dataId from URL)
PageData.getFromURL().then(function(entry) {
  if (entry) console.log('Received:', entry.data);
});
```

#### PageData Schema

| Field | Type | Description |
|-------|------|-------------|
| `dataId` | string (UUID) | Auto-generated unique identifier |
| `source` | string | Originating stack (`native`, `rn`, `flutter`, `webview`) |
| `target` | string | Destination stack |
| `route` | string? | Associated route URL (optional) |
| `data` | object | Arbitrary JSON payload |
| `timestamp` | number | Creation time (Unix ms) |
| `ttl` | number | Time-to-live in ms (default: 300000 = 5 min) |

#### Key Behaviors

- **Auto-expiry**: Data expires after `ttl` milliseconds (default 5 minutes)
- **Consume semantics**: `consume()` retrieves AND deletes (one-time read)
- **Get semantics**: `get()` retrieves without deleting (allows multiple reads)
- **Route lookup**: `getByRoute()` / `consumeByRoute()` for route-based retrieval
- **Thread-safe**: Concurrent queues (iOS) / ConcurrentHashMap (Android)

---

## Navigation Control

### Remove Page by Path

Close a specific page from the navigation stack from anywhere:

```
AppRouter.removePage("app://rn/home")
```

Route matching compares `host + path`, ignoring query parameters.

| Platform | API |
|----------|-----|
| iOS (Swift) | `AppRouter.shared.removePage(route: "app://rn/home")` |
| Android (Kotlin) | `AppRouter.removePage("app://rn/home")` |
| React Native (TS) | `NativeRouter.removePage('app://rn/home')` |
| Flutter (Dart) | `NativeRouter.removePage('app://rn/home')` |
| WebView (JS) | `AppRouter.removePage('app://rn/home')` |

### Get Navigation Stack

| Platform | API |
|----------|-----|
| iOS (Swift) | `AppRouter.shared.getNavigationStack()` |
| Android (Kotlin) | `AppRouter.getNavigationStack()` |
| React Native (TS) | `await NativeRouter.getNavigationStack()` |
| Flutter (Dart) | `await NativeRouter.getNavigationStack()` |

### Pop with Result

Return data to the previous page when popping. Result is broadcast via EventBus on channel `pageResult`.

| Platform | API |
|----------|-----|
| iOS (Swift) | `AppRouter.shared.pop(withResult: ["key": "value"])` |
| Android (Kotlin) | `AppRouter.popWithResult(activity, JSONObject(...))` |
| React Native (TS) | `NativeRouter.popWithResult({ key: 'value' })` |
| Flutter (Dart) | `NativeRouter.popWithResult({'key': 'value'})` |
| WebView (JS) | `AppEventBus.broadcast('pageResult', {...}); AppRouter.pop()` |

---

## Navigation Lifecycle Listeners

Subscribe to navigation animation completion events from any tech stack.

### Events

| Event | Description |
|-------|-------------|
| `pushCompleted` | Page push animation finished (page is now visible) |
| `popCompleted` | Page pop animation finished (page is dismissed) |
| `removeCompleted` | Page removed from stack via `removePage()` |

### Platform Usage

**iOS (Swift)**
```swift
AppRouter.shared.onNavigationEvent(.pushCompleted) { info in
    print("Push done: \(info.route)")
}
```

**Android (Kotlin)**
```kotlin
AppRouter.onNavigationEvent("pushCompleted") { info ->
    Log.d("Nav", "Push done: ${info.route}")
}
```

**React Native (TypeScript)**
```typescript
const unsubscribe = NativeRouter.onNavigationEvent('*', (info) => {
    console.log(`${info.event}: ${info.route}`);
});
unsubscribe(); // cleanup
```

**Flutter (Dart)**
```dart
final unsubscribe = NativeRouter.onNavigationEvent('*', (info) {
    print('${info.event}: ${info.route}');
});
unsubscribe(); // cleanup
```

**WebView (JavaScript)**
```javascript
var unsubscribe = AppRouter.onNavigationEvent('*', function(info) {
    console.log(info.event + ': ' + info.route);
});
unsubscribe(); // cleanup
```

### Broadcast Mechanism

All lifecycle events are also broadcast via EventBus on channel `navigationLifecycle`:
```json
{ "event": "pushCompleted", "route": "app://rn/home", "timestamp": 1717200000000 }
```

---

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
open iOSDemoProject/iOSDemoProject.xcodeproj
```

For full RN/Flutter integration:
```bash
cd iOSDemoProject && pod install && open iOSDemoProject.xcworkspace
```

#### 4. Android Project

```bash
open -a "Android Studio" AndroidDemoProject
```

For full Flutter integration, uncomment the Flutter module include in `settings.gradle.kts`.

---

## Demo Features

Each demo page (Native, RN, Flutter, WebView) implements **all** communication flows:

### EventBus Communication
- **Request/Response**: Send `getUserInfo` request, receive structured response
- **Broadcast**: Send announcement to all active stacks simultaneously
- **Notification**: One-way targeted messages (e.g., analytics events)

### PageData Transfer
- **Navigate with Data**: Pass complex objects to target page
- **Auto-consume**: Target page automatically retrieves and displays received data
- **Cross-stack**: Any stack can pass data to any other

### Navigation Control
- **Open pages**: Navigate to any tech stack
- **Remove page by path**: Close a specific page from the stack remotely
- **Pop with result**: Return data to the previous page on close
- **Print stack**: Inspect the current navigation stack

### Navigation Lifecycle
- **Push/Pop/Remove completed**: All events logged in the Event Log
- Every active page can monitor navigation state in real-time

---

## Key Files

### iOS
| File | Purpose |
|------|---------|
| `Router/AppRouter.swift` | URL router + navigation lifecycle + removePage |
| `EventBus/EventBus.swift` | Message broker singleton |
| `PageData/PageDataStore.swift` | Page data store & transfer |
| `PageData/PageDataBridge.swift` | Bridge handler for PageData |
| `Demo/NativeDemoViewController.swift` | Comprehensive demo page |

### Android
| File | Purpose |
|------|---------|
| `router/AppRouter.kt` | URL router + navigation lifecycle + removePage |
| `eventbus/EventBus.kt` | Message broker singleton |
| `pagedata/PageDataStore.kt` | Page data store & transfer |
| `pagedata/PageDataBridge.kt` | Bridge handler for PageData |
| `demo/NativeDemoActivity.kt` | Comprehensive demo page |

### Cross-Platform
| File | Purpose |
|------|---------|
| `ReactNativeModule/src/bridge/NativeEventBus.ts` | RN EventBus wrapper |
| `ReactNativeModule/src/bridge/NativeRouter.ts` | RN Router (navigate, removePage, lifecycle) |
| `ReactNativeModule/src/bridge/PageData.ts` | RN PageData API |
| `FlutterModule/lib/bridge/native_event_bus.dart` | Flutter EventBus wrapper |
| `FlutterModule/lib/bridge/native_router.dart` | Flutter Router (navigate, removePage, lifecycle) |
| `FlutterModule/lib/bridge/page_data.dart` | Flutter PageData API |
| `WebModule/js/bridge.js` | WebView JS bridge (EventBus + Router + lifecycle) |
| `WebModule/js/page-data.js` | WebView PageData API |
| `SharedProtocol/page-data-schema.json` | PageData JSON schema |

---

## Integration Notes

The current demo uses **placeholder containers** for RN and Flutter (native UI simulating their pages). This allows the project to build and run without requiring the full RN/Flutter SDK setup. The WebView bridge is fully functional.

To enable real RN/Flutter integration:
1. Uncomment SDK dependencies in `Podfile` / `settings.gradle.kts`
2. Replace placeholder containers with actual `RCTRootView` / `FlutterViewController`
3. The bridge modules are already production-ready

## License

MIT
