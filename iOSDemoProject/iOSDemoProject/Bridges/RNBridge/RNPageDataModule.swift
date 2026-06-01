import Foundation

// MARK: - RCTBridgeModule Interface for PageData (placeholder for actual React Native integration)
// In a real project, this class would:
// 1. Extend NSObject and conform to RCTBridgeModule
// 2. Be annotated with @objc(PageDataModule) and RCT_EXPORT_MODULE()
// 3. Expose these methods to JavaScript via RCT_EXPORT_METHOD:
//
// JavaScript usage:
// ```js
// import { NativeModules } from 'react-native';
// const { PageDataModule } = NativeModules;
//
// // Store data for page transfer
// const dataId = await PageDataModule.put(JSON.stringify({ source, target, route, data, ttl }));
//
// // Retrieve data
// const jsonString = await PageDataModule.get(dataId);
// const jsonString = await PageDataModule.consume(dataId);
// const jsonString = await PageDataModule.getByRoute(route);
// const jsonString = await PageDataModule.consumeByRoute(route);
// ```

class RNPageDataModule {

    func put(_ jsonString: String, resolve: @escaping (String?) -> Void) {
        let result = PageDataBridge.shared.handleMethodCall(method: "put", arguments: jsonString)
        resolve(result)
    }

    func get(_ dataId: String, resolve: @escaping (String?) -> Void) {
        let result = PageDataBridge.shared.handleMethodCall(method: "get", arguments: dataId)
        resolve(result)
    }

    func consume(_ dataId: String, resolve: @escaping (String?) -> Void) {
        let result = PageDataBridge.shared.handleMethodCall(method: "consume", arguments: dataId)
        resolve(result)
    }

    func getByRoute(_ route: String, resolve: @escaping (String?) -> Void) {
        let result = PageDataBridge.shared.handleMethodCall(method: "getByRoute", arguments: route)
        resolve(result)
    }

    func consumeByRoute(_ route: String, resolve: @escaping (String?) -> Void) {
        let result = PageDataBridge.shared.handleMethodCall(method: "consumeByRoute", arguments: route)
        resolve(result)
    }
}
