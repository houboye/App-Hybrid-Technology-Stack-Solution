package com.by.androiddemoproject.bridges.rn

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

class RNContainerActivity : ComponentActivity() {
    private val moduleName by lazy { intent.getStringExtra("moduleName") ?: "home" }
    private val params by lazy {
        @Suppress("UNCHECKED_CAST")
        (intent.getSerializableExtra("params") as? HashMap<String, String>) ?: hashMapOf()
    }
    private val bridgeAdapter = RNBridgeAdapter()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        EventBus.register(bridgeAdapter)

        setContent {
            AndroidDemoProjectTheme {
                RNScreen(
                    moduleName = moduleName,
                    params = params,
                    onNavigate = { url -> AppRouter.navigate(this, url) },
                    onBroadcast = { broadcastFromRN() }
                )
            }
        }
    }

    private fun broadcastFromRN() {
        val message = EventMessage(
            type = MessageType.broadcast,
            channel = "greeting",
            source = StackId.rn,
            target = StackId.all,
            payload = JSONObject().put("message", "Hello from React Native!")
        )
        EventBus.dispatch(message)
    }

    override fun onDestroy() {
        super.onDestroy()
        EventBus.unregister(StackId.rn)
    }
}

@Composable
fun RNScreen(
    moduleName: String,
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
            Text("⚛️ React Native", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color(0xFF61DAFB))
            Text("Module: $moduleName", fontSize = 18.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            if (params.isNotEmpty()) {
                Text("Params: $params", fontSize = 14.sp, color = MaterialTheme.colorScheme.outline)
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(onClick = { onNavigate(Routes.FLUTTER_HOME) }, modifier = Modifier.fillMaxWidth()) {
                Text("Navigate to Flutter")
            }
            Button(onClick = { onNavigate(Routes.webview("local://webHome.html")) }, modifier = Modifier.fillMaxWidth()) {
                Text("Navigate to WebView")
            }
            Button(onClick = { onNavigate(Routes.NATIVE_DEMO) }, modifier = Modifier.fillMaxWidth()) {
                Text("Navigate to Native Demo")
            }

            Spacer(modifier = Modifier.height(8.dp))

            OutlinedButton(onClick = onBroadcast, modifier = Modifier.fillMaxWidth()) {
                Text("Broadcast from RN")
            }
        }
    }
}

class RNBridgeAdapter : EventBridgeAdapter {
    override val stackId: StackId = StackId.rn

    override fun send(message: EventMessage) {
        println("[RNBridge] Received: ${message.channel} -> ${message.payload}")

        // Auto-respond to requests for demo
        if (message.type == MessageType.request && message.callbackId != null) {
            val response = EventMessage(
                type = MessageType.response,
                channel = message.channel,
                source = StackId.rn,
                target = message.source,
                payload = JSONObject().put("result", "Response from RN").put("originalChannel", message.channel),
                callbackId = message.callbackId
            )
            EventBus.dispatch(response)
        }
    }
}
