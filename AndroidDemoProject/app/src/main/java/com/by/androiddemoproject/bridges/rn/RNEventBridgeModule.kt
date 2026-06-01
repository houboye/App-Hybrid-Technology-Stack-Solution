package com.by.androiddemoproject.bridges.rn

import com.by.androiddemoproject.eventbus.EventBus
import com.by.androiddemoproject.eventbus.EventMessage

// MARK: - ReactContextBaseJavaModule placeholder
// In a real project, this class would:
// 1. Extend ReactContextBaseJavaModule
// 2. Override getName() returning "EventBridgeModule"
// 3. Be included in a ReactPackage (RNEventBridgePackage)
//
// JavaScript usage:
// ```js
// import { NativeModules, NativeEventEmitter } from 'react-native';
// const { EventBridgeModule } = NativeModules;
// EventBridgeModule.sendMessage(JSON.stringify(message));
// const emitter = new NativeEventEmitter(EventBridgeModule);
// emitter.addListener('onEventMessage', (json) => { ... });
// ```

class RNEventBridgeModule {

    // @ReactMethod
    fun sendMessage(jsonString: String) {
        val message = EventMessage.fromJSONString(jsonString) ?: return
        EventBus.dispatch(message)
    }

    // Emit to JS via RCTDeviceEventEmitter
    fun emitToJS(message: EventMessage) {
        // reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
        //     .emit("onEventMessage", message.toJSONString())
        println("[RNEventBridgeModule] Would emit to JS: ${message.channel}")
    }
}
