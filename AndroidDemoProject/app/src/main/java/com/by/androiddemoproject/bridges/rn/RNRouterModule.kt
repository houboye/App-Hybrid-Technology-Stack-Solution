package com.by.androiddemoproject.bridges.rn

import android.content.Context
import com.by.androiddemoproject.router.AppRouter

// MARK: - ReactContextBaseJavaModule placeholder for routing
// JavaScript usage:
// ```js
// import { NativeModules } from 'react-native';
// NativeModules.AppRouterModule.navigate('app://flutter/home');
// ```

class RNRouterModule {

    // @ReactMethod
    fun navigate(context: Context, url: String) {
        AppRouter.navigate(context, url)
    }
}
