# 混合应用多技术栈集成 Demo

将 **Native (iOS/Android)**、**React Native**、**Flutter** 和 **WebView** 集成到统一混合应用中的演示项目，包含跨技术栈路由和通信能力。

## 架构总览

```
┌─────────────────────────────────────────────────────┐
│                    原生层 (Native)                    │
│  ┌───────────┐  ┌───────────┐  ┌────────────────┐  │
│  │  AppRouter│  │  EventBus │  │  桥接适配器     │  │
│  │ (URL路由  │  │ (消息中转  │  │ ┌──┐ ┌──┐ ┌──┐│  │
│  │  分发器)  │  │  代理)    │  │ │RN│ │FL│ │WV││  │
│  └─────┬─────┘  └─────┬─────┘  │ └──┘ └──┘ └──┘│  │
│        │               │        └────────────────┘  │
└────────┼───────────────┼────────────────────────────┘
         │               │
    ┌────┴────┐    ┌─────┴─────┐
    │ 路由分发 │    │  消息转发  │
    └────┬────┘    └─────┬─────┘
         │               │
┌────────┼───────────────┼────────────────────────────┐
│   ┌────▼────┐  ┌───────▼──┐  ┌──────────┐          │
│   │  React  │  │  Flutter  │  │  WebView │          │
│   │  Native │  │   模块    │  │  (HTML)  │          │
│   └─────────┘  └──────────┘  └──────────┘          │
│                 跨平台模块层                          │
└─────────────────────────────────────────────────────┘
```

## 项目结构

```
MyDemoProject/
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
| `app://native/home` | 原生首页（Hub） |
| `app://native/demo` | 原生通信演示页 |
| `app://rn/home` | React Native 首页 |
| `app://rn/detail?id=123` | React Native 详情页 |
| `app://flutter/home` | Flutter 首页 |
| `app://flutter/detail?id=456` | Flutter 详情页 |
| `app://webview?url=...` | WebView 页面 |

任何技术栈都可以通过 URL 字符串调用 Router 导航到其他技术栈。

## 通信协议

基于 JSON 的事件总线，支持四种消息类型：

| 类型 | 说明 | 使用场景 |
|------|------|----------|
| `request` | 请求，期望回复 | 从其他技术栈获取数据 |
| `response` | 响应，回复请求 | 返回请求的数据 |
| `notification` | 单向通知，指定目标 | 埋点、日志上报 |
| `broadcast` | 广播，所有技术栈接收 | 主题切换、状态同步 |

### 消息格式

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

### 通信流程

```
发送方                    Native EventBus                  接收方
  │                           │                              │
  │── sendMessage(JSON) ─────▶│                              │
  │                           │── dispatch ─────────────────▶│
  │                           │                              │
  │                           │◀── response(callbackId) ─────│
  │◀── callback(response) ────│                              │
```

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
# 用 Xcode 打开项目
open iOSDemoProject/iOSDemoProject.xcodeproj
```

在 Xcode 中：
1. 选择 Target → General → 删除 "Main Interface" 中的 `Main`
2. 编译运行（`Cmd + B`，然后 `Cmd + R`）

如需完整 RN/Flutter 集成，取消 `Podfile` 中的注释并执行：
```bash
cd iOSDemoProject
pod install
open iOSDemoProject.xcworkspace
```

#### 4. Android 项目

```bash
# 用 Android Studio 打开
open -a "Android Studio" AndroidDemoProject
```

Android Studio 会自动 Gradle Sync，点击 Run 即可构建运行。

如需完整 Flutter 集成，取消 `settings.gradle.kts` 中 Flutter 模块引用的注释。

#### 5. Flutter 权限修复（如遇到 lockfile 问题）

```bash
sudo chown -R $(whoami) ~/flutter/bin/cache
```

## 演示功能

### 路由导航演示
- **全链路跳转**：Native → RN → Flutter → WebView → Native
- 每个页面都有跳转到其他所有技术栈的按钮
- 参数通过 URL query string 传递

### 通信演示
- **请求/响应**：Native 发送 `getUserInfo` 给 RN，接收响应数据
- **广播**：Flutter 广播 `themeChanged`，所有技术栈同时接收
- **通知**：WebView 单向发送 `analytics` 事件给 Native
- **事件日志**：每个页面实时显示接收到的消息

## 核心文件说明

### iOS 端
| 文件 | 职责 |
|------|------|
| `Router/AppRouter.swift` | 中心化 URL 路由分发器 |
| `EventBus/EventBus.swift` | 消息代理单例 |
| `EventBus/EventMessage.swift` | 统一消息模型 (Codable) |
| `Bridges/WebViewBridge/WebViewContainerViewController.swift` | WebView 容器 + JS 桥接 |
| `Bridges/RNBridge/RNContainerViewController.swift` | RN 页面容器 |
| `Bridges/FlutterBridge/FlutterContainerViewController.swift` | Flutter 页面容器 |
| `Demo/NativeDemoViewController.swift` | 通信功能演示页 |

### Android 端
| 文件 | 职责 |
|------|------|
| `router/AppRouter.kt` | 中心化 URL 路由分发器 |
| `eventbus/EventBus.kt` | 消息代理单例 |
| `eventbus/EventMessage.kt` | 统一消息模型 |
| `bridges/webview/WebViewContainerActivity.kt` | WebView 容器 + @JavascriptInterface |
| `bridges/rn/RNContainerActivity.kt` | RN 页面容器 |
| `bridges/flutter/FlutterContainerActivity.kt` | Flutter 页面容器 |
| `demo/NativeDemoActivity.kt` | 通信功能演示页 |

### 跨平台模块
| 文件 | 职责 |
|------|------|
| `ReactNativeModule/src/bridge/NativeEventBus.ts` | RN 端事件总线封装 |
| `ReactNativeModule/src/bridge/NativeRouter.ts` | RN 端路由封装 |
| `FlutterModule/lib/bridge/native_event_bus.dart` | Flutter 端事件总线封装 |
| `FlutterModule/lib/bridge/native_router.dart` | Flutter 端路由封装 |
| `WebModule/js/bridge.js` | WebView JS 桥接（自动识别 iOS/Android） |

## 技术实现细节

### 桥接机制

| 技术栈 | iOS 桥接方式 | Android 桥接方式 |
|--------|-------------|-----------------|
| React Native | RCTBridgeModule + RCTEventEmitter | ReactContextBaseJavaModule + RCTDeviceEventEmitter |
| Flutter | FlutterMethodChannel | MethodChannel |
| WebView | WKScriptMessageHandler + evaluateJavaScript | @JavascriptInterface + evaluateJavascript |

### 设计决策

**为什么使用原生层作为消息中枢？**
RN、Flutter、WebView 各自运行在隔离环境中（JS 线程、Dart Isolate、WebView 进程），无法直接通信。原生层是唯一的公共层，可以在所有技术栈之间中转消息。

**为什么用 URL-scheme 路由？**
URL 是所有技术栈都能轻松构造的字符串格式，避免了技术栈间的耦合。原生 Router 是唯一知道如何将 URL 解析为具体 ViewController/Activity 的实体。

**为什么预热 Flutter Engine？**
不预热的情况下，Flutter 首帧需要 1-2 秒加载。在 Application.onCreate / AppDelegate.didFinishLaunching 中预热可让 Flutter 页面秒开。

## 集成说明

当前 Demo 对 RN 和 Flutter 使用**占位容器**（原生 UI 模拟其页面效果），使项目无需完整 RN/Flutter SDK 即可编译运行。WebView 桥接为完整实现。

启用真实 RN/Flutter 集成步骤：
1. 取消 `Podfile` / `settings.gradle.kts` 中 SDK 依赖的注释
2. 将占位容器替换为真实的 `RCTRootView` / `FlutterViewController`
3. 桥接模块（`NativeEventBus.ts`、`native_event_bus.dart`）已是生产就绪代码

## 许可证

MIT
