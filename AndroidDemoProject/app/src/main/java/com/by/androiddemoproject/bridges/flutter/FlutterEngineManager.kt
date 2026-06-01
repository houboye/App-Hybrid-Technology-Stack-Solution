package com.by.androiddemoproject.bridges.flutter

import android.content.Context

object FlutterEngineManager {
    private var isPreWarmed = false

    // Call in Application.onCreate()
    // Real implementation:
    // val engine = FlutterEngine(context)
    // engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
    // FlutterEngineCache.getInstance().put("main_engine", engine)
    fun preWarm(context: Context) {
        isPreWarmed = true
        println("[FlutterEngineManager] Engine pre-warmed")
    }

    val engineReady: Boolean get() = isPreWarmed
}
