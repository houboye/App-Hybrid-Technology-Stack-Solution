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
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class NativeDemoActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AndroidDemoProjectTheme {
                NativeDemoScreen(
                    onNavigate = { url -> AppRouter.navigate(this, url) }
                )
            }
        }
    }
}

@Composable
fun NativeDemoScreen(onNavigate: (String) -> Unit) {
    val eventLog = remember { mutableStateListOf<String>() }
    var responseText by remember { mutableStateOf("") }
    val timeFormat = remember { SimpleDateFormat("HH:mm:ss", Locale.getDefault()) }

    fun appendLog(text: String) {
        val time = timeFormat.format(Date())
        eventLog.add("$time - $text")
        if (eventLog.size > 50) eventLog.removeAt(0)
    }

    LaunchedEffect(Unit) {
        EventBus.subscribe("greeting") { msg ->
            appendLog("[${msg.source.name}] greeting: ${msg.payload}")
        }
        EventBus.subscribe("themeChanged") { msg ->
            appendLog("[${msg.source.name}] themeChanged: ${msg.payload}")
        }
        EventBus.subscribe("analytics") { msg ->
            appendLog("[${msg.source.name}] analytics: ${msg.payload}")
        }
        EventBus.subscribe("getUserInfo") { msg ->
            appendLog("[${msg.source.name}] getUserInfo request received")
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
            Text("Communication & Routing Test", fontSize = 16.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)

            Spacer(modifier = Modifier.height(24.dp))

            // Communication section
            Text("Communication", fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    EventBus.sendRequest(StackId.rn, "getUserInfo", JSONObject().put("userId", "1")) { response ->
                        responseText = "RN: ${response.payload}"
                        appendLog("Got RN response: ${response.payload}")
                    }
                    appendLog("Sent request to RN: getUserInfo")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) { Text("Send Request to RN") }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    EventBus.sendRequest(StackId.flutter, "getStatus") { response ->
                        responseText = "Flutter: ${response.payload}"
                        appendLog("Got Flutter response: ${response.payload}")
                    }
                    appendLog("Sent request to Flutter: getStatus")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) { Text("Send Request to Flutter") }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    EventBus.broadcast("announcement", JSONObject().put("message", "Hello from Native!"))
                    appendLog("Broadcast sent: announcement")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) { Text("Broadcast to All") }

            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = {
                    EventBus.sendNotification(StackId.webview, "update", JSONObject().put("action", "refresh"))
                    appendLog("Notification sent to WebView: update")
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
            ) { Text("Notify WebView") }

            if (responseText.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text("Response: $responseText", fontSize = 12.sp, color = Color(0xFF4CAF50))
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Navigation section
            Text("Navigation", fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedButton(onClick = { onNavigate(Routes.RN_HOME) }, modifier = Modifier.fillMaxWidth()) {
                Text("Open React Native")
            }
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedButton(onClick = { onNavigate(Routes.FLUTTER_HOME) }, modifier = Modifier.fillMaxWidth()) {
                Text("Open Flutter")
            }
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedButton(onClick = { onNavigate(Routes.webview("local://webHome.html")) }, modifier = Modifier.fillMaxWidth()) {
                Text("Open WebView")
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Event log
            Text("Event Log", fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.fillMaxWidth())
            Spacer(modifier = Modifier.height(8.dp))

            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 100.dp, max = 200.dp),
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
