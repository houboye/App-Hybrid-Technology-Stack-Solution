package com.by.androiddemoproject.bridges.flutter

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
import org.json.JSONObject

class FlutterContainerActivity : ComponentActivity() {
    private val route by lazy { intent.getStringExtra("route") ?: "/" }
    private val params by lazy {
        @Suppress("UNCHECKED_CAST")
        (intent.getSerializableExtra("params") as? HashMap<String, String>) ?: hashMapOf()
    }
    private val bridgeAdapter = FlutterBridgeAdapter()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        EventBus.register(bridgeAdapter)

        setContent {
            AndroidDemoProjectTheme {
                FlutterScreen(
                    route = route,
                    params = params,
                    onNavigate = { url -> AppRouter.navigate(this, url) },
                    onBroadcast = { broadcastFromFlutter() }
                )
            }
        }
    }

    private fun broadcastFromFlutter() {
        val message = EventMessage(
            type = MessageType.broadcast,
            channel = "themeChanged",
            source = StackId.flutter,
            target = StackId.all,
            payload = JSONObject().put("theme", "dark")
        )
        EventBus.dispatch(message)
    }

    override fun onDestroy() {
        super.onDestroy()
        EventBus.unregister(StackId.flutter)
    }
}

@Composable
fun FlutterScreen(
    route: String,
    params: Map<String, String>,
    onNavigate: (String) -> Unit,
    onBroadcast: () -> Unit
) {
    Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text("🐦 Flutter", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color(0xFF02569B))
            Text("Route: $route", fontSize = 18.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            if (params.isNotEmpty()) {
                Text("Params: $params", fontSize = 14.sp, color = MaterialTheme.colorScheme.outline)
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(onClick = { onNavigate(Routes.RN_HOME) }, modifier = Modifier.fillMaxWidth()) {
                Text("Navigate to React Native")
            }
            Button(onClick = { onNavigate(Routes.webview("local://webHome.html")) }, modifier = Modifier.fillMaxWidth()) {
                Text("Navigate to WebView")
            }
            Button(onClick = { onNavigate(Routes.NATIVE_DEMO) }, modifier = Modifier.fillMaxWidth()) {
                Text("Navigate to Native Demo")
            }

            Spacer(modifier = Modifier.height(8.dp))

            OutlinedButton(onClick = onBroadcast, modifier = Modifier.fillMaxWidth()) {
                Text("Broadcast from Flutter")
            }
        }
    }
}

class FlutterBridgeAdapter : EventBridgeAdapter {
    override val stackId: StackId = StackId.flutter

    override fun send(message: EventMessage) {
        println("[FlutterBridge] Received: ${message.channel} -> ${message.payload}")

        if (message.type == MessageType.request && message.callbackId != null) {
            val response = EventMessage(
                type = MessageType.response,
                channel = message.channel,
                source = StackId.flutter,
                target = message.source,
                payload = JSONObject().put("result", "Response from Flutter").put("originalChannel", message.channel),
                callbackId = message.callbackId
            )
            EventBus.dispatch(response)
        }
    }
}
