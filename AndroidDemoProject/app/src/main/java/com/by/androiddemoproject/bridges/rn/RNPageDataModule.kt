package com.by.androiddemoproject.bridges.rn

import com.by.androiddemoproject.pagedata.PageDataBridge

// MARK: - ReactContextBaseJavaModule placeholder for PageData
// In a real project, this class would:
// 1. Extend ReactContextBaseJavaModule
// 2. Override getName() returning "PageDataModule"
// 3. Be included in RNEventBridgePackage
//
// JavaScript usage:
// ```js
// import { NativeModules } from 'react-native';
// const { PageDataModule } = NativeModules;
// const dataId = await PageDataModule.put(jsonPayload);
// const jsonString = await PageDataModule.get(dataId);
// const jsonString = await PageDataModule.consume(dataId);
// const jsonString = await PageDataModule.getByRoute(route);
// const jsonString = await PageDataModule.consumeByRoute(route);
// ```

class RNPageDataModule {

    // @ReactMethod
    fun put(jsonString: String, promise: Any /* Promise */) {
        val result = PageDataBridge.handleMethodCall("put", jsonString)
        // promise.resolve(result)
    }

    // @ReactMethod
    fun get(dataId: String, promise: Any /* Promise */) {
        val result = PageDataBridge.handleMethodCall("get", dataId)
        // promise.resolve(result)
    }

    // @ReactMethod
    fun consume(dataId: String, promise: Any /* Promise */) {
        val result = PageDataBridge.handleMethodCall("consume", dataId)
        // promise.resolve(result)
    }

    // @ReactMethod
    fun getByRoute(route: String, promise: Any /* Promise */) {
        val result = PageDataBridge.handleMethodCall("getByRoute", route)
        // promise.resolve(result)
    }

    // @ReactMethod
    fun consumeByRoute(route: String, promise: Any /* Promise */) {
        val result = PageDataBridge.handleMethodCall("consumeByRoute", route)
        // promise.resolve(result)
    }
}
