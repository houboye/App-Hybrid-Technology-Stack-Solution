import UIKit
import WebKit

class WebViewContainerViewController: UIViewController {
    private let urlString: String
    private var webView: WKWebView!
    private let bridgeAdapter: WebViewBridgeAdapter

    init(urlString: String) {
        self.urlString = urlString
        self.bridgeAdapter = WebViewBridgeAdapter()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WebView"
        view.backgroundColor = .systemBackground
        setupWebView()
        EventBus.shared.register(adapter: bridgeAdapter)
        bridgeAdapter.webView = webView
        loadContent()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        // Register message handlers
        contentController.add(self, name: "eventBus")
        contentController.add(self, name: "router")

        // Inject bridge JS at document start
        let bridgeScript = WKUserScript(
            source: Self.injectedBridgeJS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.addUserScript(bridgeScript)

        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadContent() {
        if urlString.hasPrefix("local://") {
            let fileName = urlString.replacingOccurrences(of: "local://", with: "")
            if let htmlPath = Bundle.main.path(forResource: fileName.replacingOccurrences(of: ".html", with: ""), ofType: "html", inDirectory: "WebModule/pages") {
                let htmlURL = URL(fileURLWithPath: htmlPath)
                webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent().deletingLastPathComponent())
            } else {
                loadFallbackHTML()
            }
        } else if let url = URL(string: urlString), urlString.hasPrefix("http") {
            webView.load(URLRequest(url: url))
        } else {
            loadFallbackHTML()
        }
    }

    private func loadFallbackHTML() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { font-family: -apple-system, sans-serif; padding: 20px; text-align: center; background: #f5f5f5; }
                h1 { color: #FF9800; }
                .btn { display: block; margin: 10px auto; padding: 12px 24px; background: #FF9800; color: white; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; width: 80%; }
                .btn:active { opacity: 0.7; }
                #log { text-align: left; background: #fff; padding: 10px; margin-top: 20px; border-radius: 8px; font-size: 12px; max-height: 200px; overflow-y: auto; }
            </style>
        </head>
        <body>
            <h1>\u{1F310} WebView</h1>
            <p>URL: \(urlString)</p>
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
                // Listen for incoming events
                AppEventBus.subscribe('*', function(msg) {
                    appendLog('[' + msg.source + '] ' + msg.channel + ': ' + JSON.stringify(msg.payload));
                });
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    deinit {
        EventBus.shared.unregister(stackId: .webview)
    }

    // MARK: - Injected Bridge JavaScript
    static let injectedBridgeJS = """
    window.AppRouter = {
        navigate: function(url) {
            window.webkit.messageHandlers.router.postMessage(url);
        }
    };
    window.AppEventBus = {
        _pendingCallbacks: {},
        _channelHandlers: {},
        _allHandlers: [],
        sendMessage: function(msg) {
            window.webkit.messageHandlers.eventBus.postMessage(JSON.stringify(msg));
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
            if (channel === '*') {
                this._allHandlers.push(handler);
            } else {
                if (!this._channelHandlers[channel]) this._channelHandlers[channel] = [];
                this._channelHandlers[channel].push(handler);
            }
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
                var r = Math.random() * 16 | 0;
                return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
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
                var handlers = AppEventBus._channelHandlers[msg.channel] || [];
                handlers.forEach(function(h) { h(msg); });
                AppEventBus._allHandlers.forEach(function(h) { h(msg); });
            }
        } catch(e) { console.error('Event parse error:', e); }
    };
    """
}

// MARK: - WKScriptMessageHandler
extension WebViewContainerViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "router":
            if let url = message.body as? String {
                AppRouter.shared.navigate(to: url, from: self)
            }
        case "eventBus":
            if let jsonString = message.body as? String,
               let eventMessage = EventMessage.from(jsonString: jsonString) {
                EventBus.shared.dispatch(message: eventMessage)
            }
        default:
            break
        }
    }
}

// MARK: - WebView Bridge Adapter
class WebViewBridgeAdapter: EventBridgeAdapter {
    var stackId: StackIdentifier { .webview }
    weak var webView: WKWebView?

    func send(message: EventMessage) {
        guard let jsonString = message.toJSONString() else { return }
        let escaped = jsonString.replacingOccurrences(of: "'", with: "\\'")
        let js = "window.__onNativeEvent('\(escaped)')"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
