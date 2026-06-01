# 混合应用多技术栈集成方案

将 **Native (iOS/Android)**、**React Native**、**Flutter** 和 **WebView** 集成到统一混合应用中的演示项目，实现跨技术栈路由、通信和页面间数据传递。

## 架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                       原生层 (Native)                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │ AppRouter│  │ EventBus │  │ PageData │  │  桥接适配器 │  │
│  │(URL路由) │  │(消息中转) │  │(数据传递) │  │┌──┐┌──┐┌──┐│  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  ││RN││FL││WV││  │
│       │              │              │        │└──┘└──┘└──┘│  │
│       │              │              │        └───────────┘  │
└───────┼──────────────┼──────────────┼───────────────────────┘
        │              │              │
   ┌────┴────┐   ┌─────┴─────┐  ┌────┴────┐
   │ 路由分发 │   │  消息转发  │  │数据传输  │
   └────┬────┘   └─────┬─────┘  └────┬────┘
        │              │              │
┌───────┼──────────────┼──────────────┼───────────────────────┐
│  ┌────▼────┐   ┌─────▼────┐   ┌────▼─────┐                │
│  │  React  │   │  Flutter │   │  WebView │                │
│  │  Native │   │   模块   │   │  (HTML)  │                │
│  └─────────┘   └──────────┘   └──────────┘                │
│                   跨平台模块层                               │
└─────────────────────────────────────────────────────────────┘
```

## 项目结构

```
App-Hybrid-Technology-Stack-Solution/
├── iOSDemoProject/          # iOS 原生应用 (UIKit + Swift)
├── AndroidDemoProject/      # Android 原生应用 (Kotlin + Jetpack Compose)
├── ReactNativeModule/       # React Native 模块 (TypeScript)
├── FlutterModule/           # Flutter 模块 (Dart)
├── WebModule/               # WebView 页面 (HTML + JavaScript)
└── SharedProtocol/          # 协议文档 & JSON Schema
```

## 路由系统

所有导航使用统一的 URL-scheme 格式：

```
app://{技术栈}/{页面}?{参数}
```

| 路由 | 目标页面 |
|------|----------|
| `app://native/home` | 原生首页 |
| `app://native/demo` | 原生通信演示页 |
| `app://rn/home` | React Native 首页 |
| `app://rn/detail?id=123` | React Native 详情页 |
| `app://flutter/home` | Flutter 首页 |
| `app://flutter/detail?id=456` | Flutter 详情页 |
| `app://webview?url=...` | WebView 页面 |

任何技术栈都可以通过 URL 字符串调用 Router 导航到其他任意技术栈。

---

## 通信协议

系统提供**两种并存的通信方式**，根据场景自由选择，也可组合使用：

| 方式 | 适用场景 | 生命周期 |
|------|----------|----------|
| **EventBus** | 实时消息、发布/订阅、即发即忘 | 瞬时（无持久化） |
| **PageData** | 页面跳转时传递复杂数据 | 持久化直到被消费或 TTL 过期 |

---

### EventBus（事件总线）

基于 JSON 的事件总线，支持四种消息类型：

| 类型 | 说明 | 使用场景 |
|------|------|----------|
| `request` | 请求（期望回复） | 从其他技术栈获取数据 |
| `response` | 响应（回复请求） | 返回请求的数据 |
| `notification` | 单向通知（指定目标） | 埋点、日志上报 |
| `broadcast` | 广播（所有技术栈接收） | 主题切换、状态同步 |

#### 消息格式

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

#### 各平台用法

**iOS (Swift)**
```swift
// 发送请求并等待响应
EventBus.shared.sendRequest(to: .rn, channel: "getUserInfo", payload: ["userId": AnyCodable("1")]) { response in
    print(response.payload)
}

// 广播给所有技术栈
EventBus.shared.broadcast(channel: "themeChanged", payload: ["theme": AnyCodable("dark")])

// 订阅事件
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

### PageData（页面数据传递）

跨技术栈的页面间数据传递机制，支持在导航时传递复杂对象。

#### 为什么需要 PageData？

URL query 参数只支持简单的字符串键值对。PageData 允许传递复杂对象（用户资料、列表、配置项），原理：

1. 导航前将数据存入原生层的集中存储
2. URL 中仅传递轻量的 `_dataId` 引用
3. 目标页面通过 `_dataId` 取出（并消费）完整数据

#### 数据流

```
源页面                        原生层                          目标页面
  │                            │                              │
  │── put(data) ──────────────▶│                              │
  │◀── dataId ────────────────│                              │
  │                            │                              │
  │── navigate(url?_dataId=x)─▶│── 路由分发到目标 ───────────▶│
  │                            │                              │
  │                            │◀── consume(dataId) ─────────│
  │                            │── 返回数据 ─────────────────▶│
```

#### 各平台用法

**iOS (Swift)**
```swift
// 导航并传递数据（一步完成）
AppRouter.shared.navigate(
    to: "app://flutter/detail?id=123",
    data: ["user": ["name": "John", "age": 30], "token": "abc"]
)

// 手动存储后导航
let dataId = PageDataStore.shared.put(source: .native, target: .rn, route: "app://rn/home", data: ["items": [1, 2, 3]])

// 在目标页面消费数据
let entry = PageDataStore.shared.consume(dataId: dataId)
```

**React Native (TypeScript)**
```typescript
import { NativeRouter } from './bridge/NativeRouter';
import { PageData } from './bridge/PageData';

// 导航并传递数据
await NativeRouter.navigateWithData('app://flutter/home', { user: { name: 'John' } });

// 在目标页面消费数据
if (props._dataId) {
  const entry = await PageData.consume(props._dataId);
  console.log(entry?.data);
}
```

**Flutter (Dart)**
```dart
import 'bridge/native_router.dart';
import 'bridge/page_data.dart';

// 导航并传递数据
await NativeRouter.navigateWithData('app://rn/home', {'user': {'name': 'John'}});

// 在目标页面消费数据
final entry = await PageData.consume(dataId);
```

**WebView (JavaScript)**
```javascript
// 导航并传递数据
PageData.navigateWithData('app://rn/home', { message: 'Hello', list: [1, 2, 3] });

// 在目标页面自动消费（从 URL 中读取 _dataId）
PageData.getFromURL().then(function(entry) {
  if (entry) console.log('收到数据:', entry.data);
});
```

#### PageData 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `dataId` | string (UUID) | 自动生成的唯一标识 |
| `source` | string | 发送方技术栈 (`native`, `rn`, `flutter`, `webview`) |
| `target` | string | 接收方技术栈 |
| `route` | string? | 关联的路由 URL（可选） |
| `data` | object | 任意 JSON 数据 |
| `timestamp` | number | 创建时间（Unix 毫秒） |
| `ttl` | number | 存活时间（毫秒，默认 300000 = 5 分钟） |

#### 关键行为

- **自动过期**：数据在 `ttl` 毫秒后过期（默认 5 分钟）
- **消费语义**：`consume()` 读取并删除（一次性读取）
- **获取语义**：`get()` 读取不删除（允许多次读取）
- **路由查找**：`getByRoute()` / `consumeByRoute()` 按路由 URL 查找
- **线程安全**：iOS 使用并发队列，Android 使用 ConcurrentHashMap

---

## 导航控制

### 按路径关闭页面 (removePage)

从任何页面关闭导航栈中的指定页面，无需在该页面上操作：

```
AppRouter.removePage("app://rn/home")   // 从栈中移除 RN 首页
```

路由匹配规则：比较 `host + path`，忽略 query 参数。`removePage("app://rn/detail")` 会移除 `app://rn/detail?id=123`。

| 平台 | API |
|------|-----|
| iOS (Swift) | `AppRouter.shared.removePage(route: "app://rn/home")` |
| Android (Kotlin) | `AppRouter.removePage("app://rn/home")` |
| React Native (TS) | `NativeRouter.removePage('app://rn/home')` |
| Flutter (Dart) | `NativeRouter.removePage('app://rn/home')` |
| WebView (JS) | `AppRouter.removePage('app://rn/home')` |

### 获取导航栈

| 平台 | API |
|------|-----|
| iOS (Swift) | `AppRouter.shared.getNavigationStack()` |
| Android (Kotlin) | `AppRouter.getNavigationStack()` |
| React Native (TS) | `await NativeRouter.getNavigationStack()` |
| Flutter (Dart) | `await NativeRouter.getNavigationStack()` |

### 带返回值的 Pop

关闭页面时将数据返回给上一页。返回数据通过 EventBus 的 `pageResult` 频道广播。

| 平台 | API |
|------|-----|
| iOS (Swift) | `AppRouter.shared.pop(withResult: ["key": "value"])` |
| Android (Kotlin) | `AppRouter.popWithResult(activity, JSONObject(...))` |
| React Native (TS) | `NativeRouter.popWithResult({ key: 'value' })` |
| Flutter (Dart) | `NativeRouter.popWithResult({'key': 'value'})` |
| WebView (JS) | `AppEventBus.broadcast('pageResult', {...}); AppRouter.pop()` |

---

## 导航生命周期监听

订阅导航动画完成事件，从任何技术栈监听。

### 事件类型

| 事件 | 说明 |
|------|------|
| `pushCompleted` | 页面推入动画完成（页面已完全可见） |
| `popCompleted` | 页面弹出动画完成（页面已完全消失） |
| `removeCompleted` | 页面通过 `removePage()` 从栈中移除 |

### 各平台用法

**iOS (Swift)**
```swift
AppRouter.shared.onNavigationEvent(.pushCompleted) { info in
    print("Push 完成: \(info.route)")
}
AppRouter.shared.onNavigationEvent(.popCompleted) { info in
    print("Pop 完成: \(info.route)")
}
```

**Android (Kotlin)**
```kotlin
AppRouter.onNavigationEvent("pushCompleted") { info ->
    Log.d("Nav", "Push 完成: ${info.route}")
}
AppRouter.onNavigationEvent("popCompleted") { info ->
    Log.d("Nav", "Pop 完成: ${info.route}")
}
```

**React Native (TypeScript)**
```typescript
// 监听特定事件
const unsubscribe = NativeRouter.onNavigationEvent('pushCompleted', (info) => {
    console.log(`Push 完成: ${info.route}`);
});

// 监听所有事件
const unsubscribe = NativeRouter.onNavigationEvent('*', (info) => {
    console.log(`${info.event}: ${info.route}`);
});

unsubscribe(); // 取消订阅
```

**Flutter (Dart)**
```dart
final unsubscribe = NativeRouter.onNavigationEvent('pushCompleted', (info) {
    print('Push 完成: ${info.route}');
});

// 监听所有事件
final unsubscribe = NativeRouter.onNavigationEvent('*', (info) {
    print('${info.event}: ${info.route}');
});

unsubscribe(); // 取消订阅
```

**WebView (JavaScript)**
```javascript
var unsubscribe = AppRouter.onNavigationEvent('*', function(info) {
    console.log(info.event + ': ' + info.route);
});

unsubscribe(); // 取消订阅
```

### 广播机制

所有生命周期事件同时通过 EventBus 的 `navigationLifecycle` 频道广播：
```json
{ "event": "pushCompleted", "route": "app://rn/home", "timestamp": 1717200000000 }
```

这使得任何订阅了 EventBus 的页面都能被动监听导航状态变化。

---

## 快速开始

### 环境要求

- **iOS**: Xcode 15+, CocoaPods
- **Android**: Android Studio Ladybug+, JDK 11+
- **React Native**: Node.js 18+, npm/yarn
- **Flutter**: Flutter SDK 3.0+

### 配置步骤

#### 1. React Native 模块

```bash
cd ReactNativeModule
npm install
```

#### 2. Flutter 模块

```bash
cd FlutterModule
flutter pub get
```

#### 3. iOS 项目

```bash
open iOSDemoProject/iOSDemoProject.xcodeproj
```

如需完整 RN/Flutter 集成：
```bash
cd iOSDemoProject && pod install && open iOSDemoProject.xcworkspace
```

#### 4. Android 项目

```bash
open -a "Android Studio" AndroidDemoProject
```

如需完整 Flutter 集成，取消 `settings.gradle.kts` 中 Flutter 模块引用的注释。

---

## 演示功能

每个演示页面（Native、RN、Flutter、WebView）都实现了**所有通信流程**：

### EventBus 通信
- **请求/响应**：发送 `getUserInfo` 请求，接收结构化响应
- **广播**：向所有活跃的技术栈同时发送公告
- **通知**：单向定向消息（如埋点事件）

### PageData 数据传递
- **带数据导航**：向目标页面传递复杂对象（用户资料、列表、配置）
- **自动消费**：目标页面自动获取并展示接收到的数据
- **跨栈传递**：任意技术栈互传（RN→Flutter、WebView→Native 等）

### 导航控制
- **打开页面**：导航到任意技术栈
- **按路径关闭页面**：远程关闭栈中指定页面
- **带返回值 Pop**：关闭时将数据返回给上一页
- **打印导航栈**：查看当前导航栈结构

### 导航生命周期
- **Push/Pop/Remove 完成**：所有事件记录在事件日志中
- 每个活跃页面都能实时监听导航状态变化

---

## 核心文件说明

### iOS 端
| 文件 | 职责 |
|------|------|
| `Router/AppRouter.swift` | URL 路由 + 导航生命周期 + removePage |
| `EventBus/EventBus.swift` | 消息代理单例 |
| `PageData/PageDataStore.swift` | 页面数据存储与传递 |
| `PageData/PageDataBridge.swift` | PageData 桥接处理器 |
| `Demo/NativeDemoViewController.swift` | 综合演示页面 |

### Android 端
| 文件 | 职责 |
|------|------|
| `router/AppRouter.kt` | URL 路由 + 导航生命周期 + removePage |
| `eventbus/EventBus.kt` | 消息代理单例 |
| `pagedata/PageDataStore.kt` | 页面数据存储与传递 |
| `pagedata/PageDataBridge.kt` | PageData 桥接处理器 |
| `demo/NativeDemoActivity.kt` | 综合演示页面 |

### 跨平台模块
| 文件 | 职责 |
|------|------|
| `ReactNativeModule/src/bridge/NativeEventBus.ts` | RN 端事件总线封装 |
| `ReactNativeModule/src/bridge/NativeRouter.ts` | RN 端路由（导航、removePage、生命周期） |
| `ReactNativeModule/src/bridge/PageData.ts` | RN 端 PageData API |
| `FlutterModule/lib/bridge/native_event_bus.dart` | Flutter 端事件总线封装 |
| `FlutterModule/lib/bridge/native_router.dart` | Flutter 端路由（导航、removePage、生命周期） |
| `FlutterModule/lib/bridge/page_data.dart` | Flutter 端 PageData API |
| `WebModule/js/bridge.js` | WebView JS 桥接（EventBus + Router + 生命周期） |
| `WebModule/js/page-data.js` | WebView PageData API |
| `SharedProtocol/page-data-schema.json` | PageData JSON Schema 定义 |

---

## 技术实现细节

### 桥接机制

| 技术栈 | iOS 桥接方式 | Android 桥接方式 |
|--------|-------------|-----------------|
| React Native | RCTBridgeModule + RCTEventEmitter | ReactContextBaseJavaModule + DeviceEventEmitter |
| Flutter | FlutterMethodChannel | MethodChannel |
| WebView | WKScriptMessageHandler + evaluateJavaScript | @JavascriptInterface + evaluateJavascript |

### 设计决策

**为什么使用原生层作为消息中枢？**
RN、Flutter、WebView 各自运行在隔离环境中（JS 线程、Dart Isolate、WebView 进程），无法直接通信。原生层是唯一的公共层，可在所有技术栈之间中转消息和数据。

**为什么用 URL-scheme 路由？**
URL 是所有技术栈都能轻松构造的字符串格式，避免了技术栈间的耦合。原生 Router 是唯一知道如何将 URL 解析为具体 ViewController/Activity 的实体。

**为什么 PageData 存储在原生层？**
原生层是所有技术栈共享的公共存储空间。数据在 native 侧集中管理，确保跨栈可达性和线程安全。

**EventBus vs PageData 如何选择？**

| | PageData | EventBus |
|---|---------|----------|
| **目的** | 页面跳转时传递数据 | 活跃页面间实时通信 |
| **生命周期** | 持久化直到被消费或过期 | 即发即忘（无持久化） |
| **模式** | 存储 → 导航 → 取出 | 发布 → 订阅 |
| **典型场景** | 表单数据、对象传递、页面参数 | 主题同步、实时通知、状态更新 |

---

## 集成说明

当前 Demo 对 RN 和 Flutter 使用**占位容器**（原生 UI 模拟），使项目无需完整 RN/Flutter SDK 即可编译运行。WebView 桥接为完整实现。

启用真实 RN/Flutter 集成步骤：
1. 取消 `Podfile` / `settings.gradle.kts` 中 SDK 依赖的注释
2. 将占位容器替换为真实的 `RCTRootView` / `FlutterViewController`
3. 桥接模块已是生产就绪代码，无需修改

## 许可证

MIT
