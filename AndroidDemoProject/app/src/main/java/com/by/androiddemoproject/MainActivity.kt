package com.by.androiddemoproject

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.by.androiddemoproject.router.AppRouter
import com.by.androiddemoproject.router.Routes
import com.by.androiddemoproject.ui.theme.AndroidDemoProjectTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            AndroidDemoProjectTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    HubScreen(
                        modifier = Modifier.padding(innerPadding),
                        onNavigate = { url -> AppRouter.navigate(this, url) }
                    )
                }
            }
        }
    }
}

@Composable
fun HubScreen(modifier: Modifier = Modifier, onNavigate: (String) -> Unit) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "🏠 Hybrid App Hub",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Navigate between tech stacks",
            fontSize = 16.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(32.dp))

        HubButton(
            text = "⚛️  React Native",
            color = Color(0xFF2196F3),
            onClick = { onNavigate(Routes.RN_HOME) }
        )
        Spacer(modifier = Modifier.height(16.dp))
        HubButton(
            text = "🐦  Flutter",
            color = Color(0xFF02569B),
            onClick = { onNavigate(Routes.FLUTTER_HOME) }
        )
        Spacer(modifier = Modifier.height(16.dp))
        HubButton(
            text = "🌐  WebView",
            color = Color(0xFFFF9800),
            onClick = { onNavigate(Routes.webview("local://webHome.html")) }
        )
        Spacer(modifier = Modifier.height(16.dp))
        HubButton(
            text = "📱  Native Demo",
            color = Color(0xFF4CAF50),
            onClick = { onNavigate(Routes.NATIVE_DEMO) }
        )
    }
}

@Composable
fun HubButton(text: String, color: Color, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        colors = ButtonDefaults.buttonColors(containerColor = color),
        shape = MaterialTheme.shapes.medium
    ) {
        Text(text = text, fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
    }
}