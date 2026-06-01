package com.by.androiddemoproject.router

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import com.by.androiddemoproject.MainActivity
import com.by.androiddemoproject.bridges.flutter.FlutterContainerActivity
import com.by.androiddemoproject.bridges.rn.RNContainerActivity
import com.by.androiddemoproject.bridges.webview.WebViewContainerActivity
import com.by.androiddemoproject.demo.NativeDemoActivity
import com.by.androiddemoproject.eventbus.EventBus
import com.by.androiddemoproject.eventbus.EventMessage
import com.by.androiddemoproject.eventbus.MessageType
import com.by.androiddemoproject.eventbus.StackId
import com.by.androiddemoproject.pagedata.PageDataStore
import org.json.JSONObject
import java.lang.ref.WeakReference
import java.util.concurrent.ConcurrentHashMap

data class NavigationLifecycleInfo(
    val event: String,
    val route: String,
    val timestamp: Long = System.currentTimeMillis()
) {
    fun toJSON(): JSONObject = JSONObject().apply {
        put("event", event)
        put("route", route)
        put("timestamp", timestamp)
    }
}

typealias NavigationLifecycleHandler = (NavigationLifecycleInfo) -> Unit

object AppRouter {
    private val activityRouteMap = ConcurrentHashMap<Int, String>()
    private val lifecycleHandlers = ConcurrentHashMap<String, MutableList<NavigationLifecycleHandler>>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var currentActivity: WeakReference<Activity>? = null

    const val EXTRA_ROUTE = "_route"

    fun setCurrentActivity(activity: Activity) {
        currentActivity = WeakReference(activity)
    }

    fun registerActivity(activity: Activity, route: String) {
        activityRouteMap[activity.hashCode()] = route
        notifyLifecycle("pushCompleted", route)
    }

    fun unregisterActivity(activity: Activity) {
        val route = activityRouteMap.remove(activity.hashCode())
        if (route != null) {
            notifyLifecycle("popCompleted", route)
        }
    }

    fun navigate(context: Context, url: String) {
        navigate(context, url, null)
    }

    fun navigate(context: Context, url: String, data: JSONObject?) {
        val uri = Uri.parse(url)
        val host = uri.host ?: return
        val path = uri.path?.trimStart('/') ?: ""
        val params = uri.queryParameters().toMutableMap()

        if (data != null) {
            val dataId = PageDataStore.put(
                source = "native",
                target = host,
                route = url,
                data = data
            )
            params["_dataId"] = dataId
        }

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
                if (params.containsKey("_dataId")) {
                    putExtra("_dataId", params["_dataId"])
                }
            }
            else -> return
        }

        intent.putExtra(EXTRA_ROUTE, url)
        context.startActivity(intent)
    }

    fun pop(activity: Activity) {
        activity.finish()
    }

    fun popWithResult(activity: Activity, data: JSONObject?) {
        if (data != null) {
            EventBus.broadcast("pageResult", data)
        }
        activity.finish()
    }

    fun removePage(route: String) {
        val matchingEntries = activityRouteMap.entries.filter { matchRoute(it.value, route) }
        if (matchingEntries.isEmpty()) return

        matchingEntries.forEach { entry ->
            notifyLifecycle("removeCompleted", entry.value)
        }

        EventBus.broadcast("removePage", JSONObject().put("route", route))
    }

    fun getNavigationStack(): List<Map<String, String>> {
        return activityRouteMap.entries.map { entry ->
            mapOf("route" to entry.value, "id" to entry.key.toString())
        }
    }

    // MARK: - Lifecycle Listeners

    fun onNavigationEvent(event: String, handler: NavigationLifecycleHandler): String {
        val id = "${event}_${System.nanoTime()}"
        lifecycleHandlers.getOrPut(event) { mutableListOf() }.add(handler)
        return id
    }

    fun removeNavigationListener(event: String) {
        lifecycleHandlers.remove(event)
    }

    private fun notifyLifecycle(event: String, route: String) {
        val info = NavigationLifecycleInfo(event = event, route = route)
        mainHandler.post {
            lifecycleHandlers[event]?.forEach { it(info) }
        }
        EventBus.broadcast("navigationLifecycle", info.toJSON())
    }

    private fun matchRoute(route: String, pattern: String): Boolean {
        if (route == pattern) return true
        val routeUri = Uri.parse(route)
        val patternUri = Uri.parse(pattern)
        return routeUri.host == patternUri.host && routeUri.path == patternUri.path
    }

    private fun resolveNative(context: Context, path: String, params: Map<String, String>): Intent {
        return when (path) {
            "demo" -> Intent(context, NativeDemoActivity::class.java)
            "home" -> Intent(context, MainActivity::class.java)
            else -> Intent(context, MainActivity::class.java)
        }.apply {
            if (params.containsKey("_dataId")) {
                putExtra("_dataId", params["_dataId"])
            }
        }
    }
}
