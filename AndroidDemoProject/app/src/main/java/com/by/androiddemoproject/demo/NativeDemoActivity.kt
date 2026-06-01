package com.by.androiddemoproject.demo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.by.androiddemoproject.eventbus.*
import com.by.androiddemoproject.router.AppRouter
import com.by.androiddemoproject.router.Routes
import com.by.androiddemoproject.ui.theme.AndroidDemoProjectTheme
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class NativeDemoActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val route = intent.getStringExtra(AppRouter.EXTRA_ROUTE) ?: Routes.NATIVE_DEMO
        AppRouter.registerActivity(this, route)
        setContent {
            AndroidDemoProjectTheme {
                NativeDemoScreen(
                    onNavigate = { url -> AppRouter.navigate(this, url) },
                    onNavigateWithData = { url, data -> AppRouter.navigate(this, url, data) },
                    onRemovePage = { route -> AppRouter.removePage(route) },
                    onGetStack = { AppRouter.getNavigationStack() }
                )
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        AppRouter.unregisterActivity(this)
    }
}

@Composable
fun NativeDemoScreen(
    onNavigate: (String) -> Unit,
    onNavigateWithData: (String, JSONObject) -> Unit,
    onRemovePage: (String) -> Unit,
    onGetStack: () -> List<Map<String, String>>
) {
    val eventLog = remember { mutableStateListOf<String>() }
    var responseText by remember { mutableStateOf("") }
    val timeFormat = remember { SimpleDateFormat("HH:mm:ss", Locale.getDefault()) }

    fun appendLog(text: String) {
        val time = timeFormat.format(Date())
        eventLog.add("$time $text")
        if (eventLog.size > 50) eventLog.removeAt(0)
    }

    LaunchedEffect(Unit) {
        EventBus.subscribe("greeting") { msg ->
            appendLog("[EventBus] [${msg.source.name}] greeting: ${msg.payload}")
        }
        EventBus.subscribe("themeChanged") { msg ->
            appendLog("[EventBus] [${msg.source.name}] themeChanged: ${msg.payload}")
        }
        EventBus.subscribe("analytics") { msg ->
            appendLog("[EventBus] [${msg.source.name}] analytics: ${msg.payload}")
        }
        EventBus.subscribe("pageResult") { msg ->
            appendLog("[PageResult] [${msg.source.name}] ${msg.payload}")
        }
        EventBus.subscribe("navigationLifecycle") { msg ->
            appendLog("[Lifecycle] ${msg.payload}")
        }
        EventBus.subscribe("getUserInfo") { msg ->
            appendLog("[EventBus] [${msg.source.name}] getUserInfo request")
            if (msg.type == MessageType.request && msg.callbackId != null) {
                val response = EventMessage(
                    type = MessageType.response,
                    channel = msg.channel,
                    source = StackId.native,
                    target = msg.source,
                    payload = JSONObject().put("name", "Native User").put("id", 42),
                    callbackId = msg.callbackId
                )
                EventBus.dispatch(response)
            }
        }

        AppRouter.onNavigationEvent("pushCompleted") { info ->
            appendLog("[Lifecycle] pushCompleted: ${info.route}")
        }
        AppRouter.onNavigationEvent("popCompleted") { info ->
            appendLog("[Lifecycle] popCompleted: ${info.route}")
        }
        AppRouter.onNavigationEvent("removeCompleted") { info ->
            appendLog("[Lifecycle] removeCompleted: ${info.route}")
        }
    }

    Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("📱 Native Demo", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color(0xFF4CAF50))
            Text("All Communication Flows", fontSize = 16.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)

            Spacer(modifier = Modifier.height(24.dp))

            // === EventBus Communication ===
            Text("EventBus Communication", fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    EventBus.sendRequest(StackId.rn, "getUserInfo", JSONObject().put("userId", "1")) { response ->
                        responseText = "RN: ${response.payload}"
                        appendLog("[EventBus] RN response: ${response.payload}")
                    }
                    appendLog("[EventBus] Sent request to RN: getUserInfo")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) { Text("Send Request to RN") }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    EventBus.sendRequest(StackId.flutter, "getStatus") { response ->
                        responseText = "Flutter: ${response.payload}"
                        appendLog("[EventBus] Flutter response: ${response.payload}")
                    }
                    appendLog("[EventBus] Sent request to Flutter: getStatus")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) { Text("Send Request to Flutter") }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    EventBus.broadcast("announcement", JSONObject().put("message", "Hello from Native!"))
                    appendLog("[EventBus] Broadcast: announcement")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) { Text("Broadcast to All") }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    EventBus.sendNotification(StackId.webview, "update", JSONObject().put("action", "refresh"))
                    appendLog("[EventBus] Notification to WebView: update")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) { Text("Notify WebView") }

            if (responseText.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text("Response: $responseText", fontSize = 12.sp, color = Color(0xFF4CAF50))
            }

            Spacer(modifier = Modifier.height(24.dp))

            // === PageData Transfer ===
            Text("PageData Transfer", fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    val data = JSONObject().apply {
                        put("user", JSONObject().put("name", "John").put("age", 30))
                        put("items", JSONArray(listOf(1, 2, 3, 4, 5)))
                        put("fromPage", "NativeDemo")
                    }
                    onNavigateWithData(Routes.RN_HOME, data)
                    appendLog("[PageData] Navigate to RN with user data")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2196F3))
            ) { Text("Navigate to RN with Data") }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    val data = JSONObject().apply {
                        put("config", JSONObject().put("theme", "dark").put("locale", "zh_CN"))
                        put("message", "Data from Native via PageData")
                    }
                    onNavigateWithData(Routes.FLUTTER_HOME, data)
                    appendLog("[PageData] Navigate to Flutter with config data")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF02569B))
            ) { Text("Navigate to Flutter with Data") }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    val data = JSONObject().apply {
                        put("products", JSONArray().apply {
                            put(JSONObject().put("id", 1).put("name", "iPhone").put("price", 999))
                            put(JSONObject().put("id", 2).put("name", "iPad").put("price", 799))
                        })
                        put("currency", "USD")
                    }
                    onNavigateWithData(Routes.webview("local://webHome.html"), data)
                    appendLog("[PageData] Navigate to WebView with products data")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF9800))
            ) { Text("Navigate to WebView with Data") }

            Spacer(modifier = Modifier.height(24.dp))

            // === Navigation Control ===
            Text("Navigation Control", fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedButton(onClick = { onNavigate(Routes.RN_HOME) }, modifier = Modifier.fillMaxWidth()) {
                Text("Open RN Page")
            }
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedButton(onClick = { onNavigate(Routes.FLUTTER_HOME) }, modifier = Modifier.fillMaxWidth()) {
                Text("Open Flutter Page")
            }
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedButton(onClick = { onNavigate(Routes.webview("local://webHome.html")) }, modifier = Modifier.fillMaxWidth()) {
                Text("Open WebView Page")
            }

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedButton(
                onClick = {
                    onRemovePage(Routes.RN_HOME)
                    appendLog("[Router] removePage: app://rn/home")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFF44336))
            ) { Text("Remove RN Page from Stack") }

            Spacer(modifier = Modifier.height(8.dp))

            OutlinedButton(
                onClick = {
                    onRemovePage(Routes.FLUTTER_HOME)
                    appendLog("[Router] removePage: app://flutter/home")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFF44336))
            ) { Text("Remove Flutter Page from Stack") }

            Spacer(modifier = Modifier.height(8.dp))

            OutlinedButton(
                onClick = {
                    val stack = onGetStack()
                    val routes = stack.map { it["route"] ?: "?" }.joinToString(" → ")
                    appendLog("[Router] Stack: $routes")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF9C27B0))
            ) { Text("Print Navigation Stack") }

            Spacer(modifier = Modifier.height(24.dp))

            // Event log
            Text("Event Log", fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))

            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 100.dp, max = 250.dp),
                color = MaterialTheme.colorScheme.surfaceVariant,
                shape = MaterialTheme.shapes.small
            ) {
                Column(modifier = Modifier.padding(10.dp)) {
                    if (eventLog.isEmpty()) {
                        Text("No events yet...", fontSize = 12.sp, color = MaterialTheme.colorScheme.outline)
                    } else {
                        eventLog.forEach { entry ->
                            Text(entry, fontSize = 11.sp)
                        }
                    }
                }
            }
        }
    }
}
