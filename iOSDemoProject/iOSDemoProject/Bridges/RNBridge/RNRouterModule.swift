import Foundation

// MARK: - RCT Router Module (placeholder for actual React Native integration)
/// JavaScript usage:
/// ```js
/// import { NativeModules } from 'react-native';
/// NativeModules.AppRouterModule.navigate('app://flutter/home');
/// NativeModules.AppRouterModule.pop();
/// ```
class RNRouterModule {

    func navigate(_ url: String) {
        AppRouter.shared.navigate(to: url)
    }

    func pop() {
        AppRouter.shared.pop()
    }
}
