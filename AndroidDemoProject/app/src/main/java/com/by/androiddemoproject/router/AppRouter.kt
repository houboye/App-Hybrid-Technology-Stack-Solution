package com.by.androiddemoproject.router

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.by.androiddemoproject.MainActivity
import com.by.androiddemoproject.bridges.flutter.FlutterContainerActivity
import com.by.androiddemoproject.bridges.rn.RNContainerActivity
import com.by.androiddemoproject.bridges.webview.WebViewContainerActivity
import com.by.androiddemoproject.demo.NativeDemoActivity

object AppRouter {

    fun navigate(context: Context, url: String) {
        val uri = Uri.parse(url)
        val host = uri.host ?: return
        val path = uri.path?.trimStart('/') ?: ""
        val params = uri.queryParameters()

        val intent: Intent = when (host) {
            "native" -> resolveNative(context, path, params)
            "rn" -> Intent(context, RNContainerActivity::class.java).apply {
                putExtra("moduleName", if (path.isEmpty()) "home" else path)
                putExtra("params", HashMap(params))
            }
            "flutter" -> Intent(context, FlutterContainerActivity::class.java).apply {
                putExtra("route", if (path.isEmpty()) "/" else "/$path")
                putExtra("params", HashMap(params))
            }
            "webview" -> Intent(context, WebViewContainerActivity::class.java).apply {
                putExtra("url", params["url"] ?: "")
            }
            else -> return
        }

        context.startActivity(intent)
    }

    private fun resolveNative(context: Context, path: String, params: Map<String, String>): Intent {
        return when (path) {
            "demo" -> Intent(context, NativeDemoActivity::class.java)
            "home" -> Intent(context, MainActivity::class.java)
            else -> Intent(context, MainActivity::class.java)
        }
    }
}
