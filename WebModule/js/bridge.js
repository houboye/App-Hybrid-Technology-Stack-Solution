(function() {
  'use strict';

  function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0;
      return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
  }

  function isIOS() {
    return !!(window.webkit && window.webkit.messageHandlers);
  }

  function isAndroid() {
    return !!window.AndroidBridge;
  }

  // Router
  window.AppRouter = {
    navigate: function(url) {
      if (isIOS()) {
        window.webkit.messageHandlers.router.postMessage(JSON.stringify({ method: 'navigate', args: url }));
      } else if (isAndroid()) {
        window.AndroidBridge.navigate(url);
      } else {
        console.warn('[AppRouter] No native bridge available');
      }
    },

    removePage: function(route) {
      if (isIOS()) {
        window.webkit.messageHandlers.router.postMessage(JSON.stringify({ method: 'removePage', args: route }));
      } else if (isAndroid()) {
        window.AndroidBridge.removePage(route);
      } else {
        console.warn('[AppRouter] No native bridge available');
      }
    },

    pop: function() {
      if (isIOS()) {
        window.webkit.messageHandlers.router.postMessage(JSON.stringify({ method: 'pop', args: null }));
      } else if (isAndroid()) {
        window.AndroidBridge.pop();
      } else {
        console.warn('[AppRouter] No native bridge available');
      }
    },

    _lifecycleHandlers: [],

    onNavigationEvent: function(event, handler) {
      var entry = { event: event, handler: handler };
      this._lifecycleHandlers.push(entry);
      return function() {
        var idx = AppRouter._lifecycleHandlers.indexOf(entry);
        if (idx >= 0) AppRouter._lifecycleHandlers.splice(idx, 1);
      };
    }
  };

  // Event Bus
  window.AppEventBus = {
    _pendingCallbacks: {},
    _channelHandlers: {},
    _allHandlers: [],

    sendMessage: function(msg) {
      var json = JSON.stringify(msg);
      if (isIOS()) {
        window.webkit.messageHandlers.eventBus.postMessage(json);
      } else if (isAndroid()) {
        window.AndroidBridge.sendMessage(json);
      } else {
        console.warn('[AppEventBus] No native bridge available');
      }
    },

    sendRequest: function(target, channel, payload) {
      var self = this;
      return new Promise(function(resolve) {
        var callbackId = generateUUID();
        self._pendingCallbacks[callbackId] = resolve;
        self.sendMessage({
          id: generateUUID(),
          type: 'request',
          channel: channel,
          source: 'webview',
          target: target,
          payload: payload || {},
          callbackId: callbackId,
          timestamp: Date.now()
        });
      });
    },

    sendNotification: function(target, channel, payload) {
      this.sendMessage({
        id: generateUUID(),
        type: 'notification',
        channel: channel,
        source: 'webview',
        target: target,
        payload: payload || {},
        callbackId: null,
        timestamp: Date.now()
      });
    },

    broadcast: function(channel, payload) {
      this.sendMessage({
        id: generateUUID(),
        type: 'broadcast',
        channel: channel,
        source: 'webview',
        target: '*',
        payload: payload || {},
        callbackId: null,
        timestamp: Date.now()
      });
    },

    respond: function(originalMsg, payload) {
      this.sendMessage({
        id: generateUUID(),
        type: 'response',
        channel: originalMsg.channel,
        source: 'webview',
        target: originalMsg.source,
        payload: payload || {},
        callbackId: originalMsg.callbackId,
        timestamp: Date.now()
      });
    },

    subscribe: function(channel, handler) {
      if (channel === '*') {
        this._allHandlers.push(handler);
      } else {
        if (!this._channelHandlers[channel]) {
          this._channelHandlers[channel] = [];
        }
        this._channelHandlers[channel].push(handler);
      }
      // Return unsubscribe function
      var self = this;
      return function() {
        if (channel === '*') {
          var idx = self._allHandlers.indexOf(handler);
          if (idx >= 0) self._allHandlers.splice(idx, 1);
        } else {
          var handlers = self._channelHandlers[channel];
          if (handlers) {
            var i = handlers.indexOf(handler);
            if (i >= 0) handlers.splice(i, 1);
          }
        }
      };
    }
  };

  // Native-to-WebView callback
  window.__onNativeEvent = function(jsonString) {
    try {
      var msg = JSON.parse(jsonString);

      if (msg.type === 'response' && msg.callbackId && AppEventBus._pendingCallbacks[msg.callbackId]) {
        AppEventBus._pendingCallbacks[msg.callbackId](msg);
        delete AppEventBus._pendingCallbacks[msg.callbackId];
        return;
      }

      // Dispatch navigation lifecycle events to AppRouter handlers
      if (msg.channel === 'navigationLifecycle' && msg.payload) {
        AppRouter._lifecycleHandlers.forEach(function(entry) {
          if (entry.event === msg.payload.event || entry.event === '*') {
            entry.handler(msg.payload);
          }
        });
      }

      // Notify channel-specific handlers
      var handlers = AppEventBus._channelHandlers[msg.channel] || [];
      handlers.forEach(function(h) { h(msg); });

      // Notify wildcard handlers
      AppEventBus._allHandlers.forEach(function(h) { h(msg); });
    } catch(e) {
      console.error('[AppEventBus] Parse error:', e);
    }
  };

})();
