package com.by.androiddemoproject.router

import android.net.Uri

object Routes {
    const val NATIVE_HOME = "app://native/home"
    const val NATIVE_DEMO = "app://native/demo"
    const val RN_HOME = "app://rn/home"
    const val RN_DETAIL = "app://rn/detail"
    const val FLUTTER_HOME = "app://flutter/home"
    const val FLUTTER_DETAIL = "app://flutter/detail"
    const val WEBVIEW = "app://webview"

    fun rnDetail(id: String) = "app://rn/detail?id=$id"
    fun flutterDetail(id: String) = "app://flutter/detail?id=$id"
    fun webview(url: String) = "app://webview?url=${Uri.encode(url)}"
}

fun Uri.queryParameters(): Map<String, String> {
    val params = mutableMapOf<String, String>()
    queryParameterNames.forEach { name ->
        getQueryParameter(name)?.let { params[name] = it }
    }
    return params
}
