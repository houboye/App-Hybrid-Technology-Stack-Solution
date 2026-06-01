(function() {
  'use strict';

  function isIOS() {
    return !!(window.webkit && window.webkit.messageHandlers);
  }

  function isAndroid() {
    return !!window.AndroidBridge;
  }

  function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0;
      return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
  }

  var pendingRequests = {};

  window.PageData = {
    put: function(target, data, route, ttl) {
      var self = this;
      var requestId = generateUUID();
      var payload = JSON.stringify({
        source: 'webview',
        target: target,
        route: route || null,
        data: data,
        ttl: ttl || 300000
      });

      return new Promise(function(resolve) {
        pendingRequests[requestId] = resolve;
        if (isIOS()) {
          window.webkit.messageHandlers.pageData.postMessage(
            JSON.stringify({ method: 'put', requestId: requestId, payload: payload })
          );
        } else if (isAndroid()) {
          window.AndroidBridge.pageDataPut(requestId, payload);
        } else {
          console.warn('[PageData] No native bridge available');
          delete pendingRequests[requestId];
          resolve(null);
        }
      });
    },

    get: function(dataId) {
      var requestId = generateUUID();
      return new Promise(function(resolve) {
        pendingRequests[requestId] = function(jsonString) {
          resolve(jsonString ? JSON.parse(jsonString) : null);
        };
        if (isIOS()) {
          window.webkit.messageHandlers.pageData.postMessage(
            JSON.stringify({ method: 'get', requestId: requestId, payload: dataId })
          );
        } else if (isAndroid()) {
          window.AndroidBridge.pageDataGet(requestId, dataId);
        } else {
          delete pendingRequests[requestId];
          resolve(null);
        }
      });
    },

    consume: function(dataId) {
      var requestId = generateUUID();
      return new Promise(function(resolve) {
        pendingRequests[requestId] = function(jsonString) {
          resolve(jsonString ? JSON.parse(jsonString) : null);
        };
        if (isIOS()) {
          window.webkit.messageHandlers.pageData.postMessage(
            JSON.stringify({ method: 'consume', requestId: requestId, payload: dataId })
          );
        } else if (isAndroid()) {
          window.AndroidBridge.pageDataConsume(requestId, dataId);
        } else {
          delete pendingRequests[requestId];
          resolve(null);
        }
      });
    },

    getFromURL: function() {
      var params = new URLSearchParams(window.location.search);
      var dataId = params.get('_dataId');
      if (!dataId) return Promise.resolve(null);
      return this.consume(dataId);
    },

    navigateWithData: function(url, data, ttl) {
      var self = this;
      var host = url.replace('app://', '').split('/')[0];
      return this.put(host, data, url, ttl).then(function(dataId) {
        if (dataId) {
          var separator = url.indexOf('?') >= 0 ? '&' : '?';
          window.AppRouter.navigate(url + separator + '_dataId=' + dataId);
        }
        return dataId;
      });
    }
  };

  window.__onPageDataResponse = function(requestId, result) {
    var callback = pendingRequests[requestId];
    if (callback) {
      callback(result);
      delete pendingRequests[requestId];
    }
  };

})();
