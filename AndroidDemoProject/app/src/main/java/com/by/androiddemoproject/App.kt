package com.by.androiddemoproject

import android.app.Application
import com.by.androiddemoproject.bridges.flutter.FlutterEngineManager

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        FlutterEngineManager.preWarm(this)
    }
}
