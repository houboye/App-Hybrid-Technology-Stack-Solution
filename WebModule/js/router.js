(function() {
  'use strict';

  // Convenience routing helpers for WebView pages
  window.AppRoutes = {
    nativeHome: 'app://native/home',
    nativeDemo: 'app://native/demo',
    rnHome: 'app://rn/home',
    flutterHome: 'app://flutter/home',

    rnDetail: function(id) {
      return 'app://rn/detail?id=' + encodeURIComponent(id);
    },
    flutterDetail: function(id) {
      return 'app://flutter/detail?id=' + encodeURIComponent(id);
    },
    webview: function(url) {
      return 'app://webview?url=' + encodeURIComponent(url);
    }
  };

})();
