package com.by.androiddemoproject.bridges.webview

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import com.by.androiddemoproject.eventbus.*
import com.by.androiddemoproject.router.AppRouter

class WebViewContainerActivity : ComponentActivity() {
    private val urlString by lazy { intent.getStringExtra("url") ?: "" }
    private lateinit var webView: WebView
    private val bridgeAdapter = WebViewBridgeAdapter()

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            addJavascriptInterface(JsBridge(), "AndroidBridge")
            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    injectBridgeScript()
                }
            }
        }

        setContentView(webView)
        bridgeAdapter.webView = webView
        EventBus.register(bridgeAdapter)
        loadContent()
    }

    private fun loadContent() {
        if (urlString.startsWith("local://")) {
            loadFallbackHTML()
        } else if (urlString.startsWith("http")) {
            webView.loadUrl(urlString)
        } else {
            loadFallbackHTML()
        }
    }

    private fun loadFallbackHTML() {
        val html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { font-family: sans-serif; padding: 20px; text-align: center; background: #f5f5f5; }
                h1 { color: #FF9800; }
                .btn { display: block; margin: 10px auto; padding: 12px 24px; background: #FF9800; color: white; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; width: 80%; }
                .btn:active { opacity: 0.7; }
                #log { text-align: left; background: #fff; padding: 10px; margin-top: 20px; border-radius: 8px; font-size: 12px; max-height: 200px; overflow-y: auto; }
            </style>
        </head>
        <body>
            <h1>🌐 WebView</h1>
            <p>URL: ${urlString}</p>
            <button class="btn" onclick="AppRouter.navigate('app://native/demo')">Navigate to Native Demo</button>
            <button class="btn" onclick="AppRouter.navigate('app://rn/home')">Navigate to React Native</button>
            <button class="btn" onclick="AppRouter.navigate('app://flutter/home')">Navigate to Flutter</button>
            <button class="btn" onclick="broadcastFromWeb()">Broadcast from WebView</button>
            <button class="btn" onclick="sendRequestToNative()">Send Request to Native</button>
            <div id="log"><b>Event Log:</b></div>
            <script>
                function broadcastFromWeb() {
                    AppEventBus.broadcast('greeting', { message: 'Hello from WebView!' });
                    appendLog('Sent broadcast: greeting');
                }
                function sendRequestToNative() {
                    AppEventBus.sendRequest('native', 'getUserInfo', { userId: '42' }).then(function(response) {
                        appendLog('Got response: ' + JSON.stringify(response.payload));
                    });
                }
                function appendLog(text) {
                    var log = document.getElementById('log');
                    log.innerHTML += '<br>' + new Date().toLocaleTimeString() + ' - ' + text;
                    log.scrollTop = log.scrollHeight;
                }
                AppEventBus.subscribe('*', function(msg) {
                    appendLog('[' + msg.source + '] ' + msg.channel + ': ' + JSON.stringify(msg.payload));
                });
            </script>
        </body>
        </html>
        """.trimIndent()
        webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
    }

    private fun injectBridgeScript() {
        webView.evaluateJavascript(BRIDGE_JS, null)
    }

    override fun onDestroy() {
        super.onDestroy()
        EventBus.unregister(StackId.webview)
    }

    inner class JsBridge {
        @JavascriptInterface
        fun navigate(url: String) {
            runOnUiThread {
                AppRouter.navigate(this@WebViewContainerActivity, url)
            }
        }

        @JavascriptInterface
        fun sendMessage(jsonString: String) {
            val message = EventMessage.fromJSONString(jsonString) ?: return
            EventBus.dispatch(message)
        }
    }

    companion object {
        private const val BRIDGE_JS = """
            window.AppRouter = {
                navigate: function(url) {
                    AndroidBridge.navigate(url);
                }
            };
            window.AppEventBus = {
                _pendingCallbacks: {},
                _channelHandlers: {},
                _allHandlers: [],
                sendMessage: function(msg) {
                    AndroidBridge.sendMessage(JSON.stringify(msg));
                },
                sendRequest: function(target, channel, payload) {
                    var self = this;
                    return new Promise(function(resolve) {
                        var callbackId = self._generateUUID();
                        self._pendingCallbacks[callbackId] = resolve;
                        self.sendMessage({
                            id: self._generateUUID(), type: 'request', channel: channel,
                            source: 'webview', target: target, payload: payload || {},
                            callbackId: callbackId, timestamp: Date.now()
                        });
                    });
                },
                sendNotification: function(target, channel, payload) {
                    this.sendMessage({
                        id: this._generateUUID(), type: 'notification', channel: channel,
                        source: 'webview', target: target, payload: payload || {},
                        callbackId: null, timestamp: Date.now()
                    });
                },
                broadcast: function(channel, payload) {
                    this.sendMessage({
                        id: this._generateUUID(), type: 'broadcast', channel: channel,
                        source: 'webview', target: '*', payload: payload || {},
                        callbackId: null, timestamp: Date.now()
                    });
                },
                subscribe: function(channel, handler) {
                    if (channel === '*') { this._allHandlers.push(handler); }
                    else { if (!this._channelHandlers[channel]) this._channelHandlers[channel] = []; this._channelHandlers[channel].push(handler); }
                },
                respond: function(originalMsg, payload) {
                    this.sendMessage({
                        id: this._generateUUID(), type: 'response', channel: originalMsg.channel,
                        source: 'webview', target: originalMsg.source, payload: payload || {},
                        callbackId: originalMsg.callbackId, timestamp: Date.now()
                    });
                },
                _generateUUID: function() {
                    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                        var r = Math.random() * 16 | 0; return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
                    });
                }
            };
            window.__onNativeEvent = function(jsonString) {
                try {
                    var msg = JSON.parse(jsonString);
                    if (msg.type === 'response' && msg.callbackId && AppEventBus._pendingCallbacks[msg.callbackId]) {
                        AppEventBus._pendingCallbacks[msg.callbackId](msg);
                        delete AppEventBus._pendingCallbacks[msg.callbackId];
                    } else {
                        (AppEventBus._channelHandlers[msg.channel] || []).forEach(function(h) { h(msg); });
                        AppEventBus._allHandlers.forEach(function(h) { h(msg); });
                    }
                } catch(e) { console.error('Event parse error:', e); }
            };
        """
    }
}

class WebViewBridgeAdapter : EventBridgeAdapter {
    override val stackId: StackId = StackId.webview
    var webView: WebView? = null

    override fun send(message: EventMessage) {
        val jsonString = message.toJSONString().replace("'", "\\'")
        val js = "window.__onNativeEvent('$jsonString')"
        webView?.post {
            webView?.evaluateJavascript(js, null)
        }
    }
}
