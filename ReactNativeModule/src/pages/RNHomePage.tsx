import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
} from 'react-native';
import { NativeRouter } from '../bridge/NativeRouter';
import { NativeEventBus } from '../bridge/NativeEventBus';
import { PageData } from '../bridge/PageData';
import { EventMessage } from '../bridge/types';

export const RNHomePage: React.FC<{ _dataId?: string }> = (props) => {
  const [eventLog, setEventLog] = useState<string[]>([]);
  const [responseText, setResponseText] = useState<string>('');
  const [receivedData, setReceivedData] = useState<string>('');

  const appendLog = (text: string) => {
    const time = new Date().toLocaleTimeString();
    setEventLog((prev) => [...prev.slice(-29), `${time} ${text}`]);
  };

  useEffect(() => {
    // Consume PageData if present
    if (props._dataId) {
      PageData.consume(props._dataId).then((entry) => {
        if (entry) {
          setReceivedData(JSON.stringify(entry.data, null, 2));
          appendLog(`[PageData] Received from ${entry.source}: ${JSON.stringify(entry.data)}`);
        }
      });
    }

    // EventBus subscriptions
    const unsub1 = NativeEventBus.subscribe('*', (msg: EventMessage) => {
      if (msg.channel === 'navigationLifecycle') {
        appendLog(`[Lifecycle] ${msg.payload.event}: ${msg.payload.route}`);
      } else {
        appendLog(`[EventBus] [${msg.source}] ${msg.channel}: ${JSON.stringify(msg.payload)}`);
      }
    });

    // Navigation lifecycle listener
    const unsub2 = NativeRouter.onNavigationEvent('*', (info) => {
      appendLog(`[Nav] ${info.event}: ${info.route}`);
    });

    return () => {
      unsub1();
      unsub2();
    };
  }, []);

  // === EventBus Handlers ===
  const handleSendRequest = async () => {
    appendLog('[EventBus] Sending request to Native: getUserInfo');
    const response = await NativeEventBus.sendRequest('native', 'getUserInfo', {
      userId: '1',
    });
    setResponseText(JSON.stringify(response.payload));
    appendLog(`[EventBus] Got response: ${JSON.stringify(response.payload)}`);
  };

  const handleBroadcast = () => {
    NativeEventBus.broadcast('greeting', {
      message: 'Hello from React Native!',
    });
    appendLog('[EventBus] Broadcast: greeting');
  };

  // === PageData Handlers ===
  const handleNavigateToFlutterWithData = async () => {
    const data = {
      user: { name: 'RN User', level: 5 },
      scores: [100, 95, 88],
      transferredAt: Date.now(),
    };
    await NativeRouter.navigateWithData('app://flutter/home', data);
    appendLog('[PageData] Navigate to Flutter with user scores');
  };

  const handleNavigateToWebWithData = async () => {
    const data = {
      articles: [
        { id: 1, title: 'React Native Guide', read: true },
        { id: 2, title: 'Flutter vs RN', read: false },
      ],
      source: 'RN',
    };
    await NativeRouter.navigateWithData(
      'app://webview?url=local://webHome.html',
      data,
    );
    appendLog('[PageData] Navigate to WebView with articles data');
  };

  const handleNavigateToNativeWithData = async () => {
    const data = {
      action: 'showProfile',
      userId: 42,
      preferences: { theme: 'dark', lang: 'zh' },
    };
    await NativeRouter.navigateWithData('app://native/demo', data);
    appendLog('[PageData] Navigate to Native with profile data');
  };

  // === Navigation Control ===
  const handleRemoveFlutterPage = () => {
    NativeRouter.removePage('app://flutter/home');
    appendLog('[Router] removePage: app://flutter/home');
  };

  const handleRemoveWebViewPage = () => {
    NativeRouter.removePage('app://webview');
    appendLog('[Router] removePage: app://webview');
  };

  const handlePopWithResult = () => {
    NativeRouter.popWithResult({
      status: 'success',
      selectedItem: 'item_42',
      from: 'RNHomePage',
    });
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.badge}>⚛️ React Native</Text>
      <Text style={styles.subtitle}>All Communication Flows</Text>

      {/* Received PageData */}
      {receivedData ? (
        <View style={styles.dataBox}>
          <Text style={styles.dataTitle}>Received PageData:</Text>
          <Text style={styles.dataText}>{receivedData}</Text>
        </View>
      ) : null}

      {/* EventBus Communication */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>EventBus Communication</Text>
        <TouchableOpacity style={styles.button} onPress={handleSendRequest}>
          <Text style={styles.buttonText}>Send Request to Native</Text>
        </TouchableOpacity>
        {responseText ? (
          <Text style={styles.response}>Response: {responseText}</Text>
        ) : null}
        <TouchableOpacity style={styles.button} onPress={handleBroadcast}>
          <Text style={styles.buttonText}>Broadcast Greeting</Text>
        </TouchableOpacity>
      </View>

      {/* PageData Transfer */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>PageData Transfer</Text>
        <TouchableOpacity
          style={[styles.button, { backgroundColor: '#02569B' }]}
          onPress={handleNavigateToFlutterWithData}>
          <Text style={styles.buttonText}>Navigate to Flutter with Data</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, { backgroundColor: '#FF9800' }]}
          onPress={handleNavigateToWebWithData}>
          <Text style={styles.buttonText}>Navigate to WebView with Data</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, { backgroundColor: '#4CAF50' }]}
          onPress={handleNavigateToNativeWithData}>
          <Text style={styles.buttonText}>Navigate to Native with Data</Text>
        </TouchableOpacity>
      </View>

      {/* Navigation Control */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Navigation Control</Text>
        <TouchableOpacity
          style={[styles.button, styles.outlinedButton]}
          onPress={() => NativeRouter.toFlutterHome()}>
          <Text style={styles.outlinedButtonText}>Open Flutter</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, styles.outlinedButton]}
          onPress={() => NativeRouter.toWebView('local://webHome.html')}>
          <Text style={styles.outlinedButtonText}>Open WebView</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, styles.outlinedButton]}
          onPress={() => NativeRouter.toNativeDemo()}>
          <Text style={styles.outlinedButtonText}>Open Native Demo</Text>
        </TouchableOpacity>

        <View style={styles.divider} />

        <TouchableOpacity
          style={[styles.button, styles.outlinedButton, { borderColor: '#F44336' }]}
          onPress={handleRemoveFlutterPage}>
          <Text style={[styles.outlinedButtonText, { color: '#F44336' }]}>
            Remove Flutter from Stack
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, styles.outlinedButton, { borderColor: '#F44336' }]}
          onPress={handleRemoveWebViewPage}>
          <Text style={[styles.outlinedButtonText, { color: '#F44336' }]}>
            Remove WebView from Stack
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, styles.outlinedButton, { borderColor: '#9C27B0' }]}
          onPress={handlePopWithResult}>
          <Text style={[styles.outlinedButtonText, { color: '#9C27B0' }]}>
            Pop with Result Data
          </Text>
        </TouchableOpacity>
      </View>

      {/* Event Log */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Event Log</Text>
        <View style={styles.logContainer}>
          {eventLog.length === 0 ? (
            <Text style={styles.logEmpty}>No events yet...</Text>
          ) : (
            eventLog.map((entry, index) => (
              <Text key={index} style={styles.logEntry}>
                {entry}
              </Text>
            ))
          )}
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5' },
  content: { padding: 24, alignItems: 'center' },
  badge: { fontSize: 28, fontWeight: 'bold', color: '#61DAFB' },
  subtitle: { fontSize: 18, color: '#666', marginBottom: 20 },
  section: { width: '100%', marginBottom: 24 },
  sectionTitle: { fontSize: 16, fontWeight: '600', marginBottom: 8, color: '#333' },
  button: {
    backgroundColor: '#61DAFB',
    padding: 14,
    borderRadius: 8,
    marginBottom: 8,
    alignItems: 'center',
  },
  buttonText: { color: '#fff', fontSize: 16, fontWeight: '500' },
  outlinedButton: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#61DAFB',
  },
  outlinedButtonText: { color: '#61DAFB', fontSize: 16, fontWeight: '500' },
  response: { fontSize: 12, color: '#4CAF50', marginVertical: 4 },
  dataBox: {
    width: '100%',
    backgroundColor: '#E3F2FD',
    borderRadius: 8,
    padding: 12,
    marginBottom: 20,
    borderLeftWidth: 4,
    borderLeftColor: '#2196F3',
  },
  dataTitle: { fontSize: 14, fontWeight: '600', color: '#1565C0', marginBottom: 4 },
  dataText: { fontSize: 11, color: '#333', fontFamily: 'monospace' },
  divider: { height: 1, backgroundColor: '#e0e0e0', marginVertical: 8 },
  logContainer: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 10,
    minHeight: 100,
    maxHeight: 250,
  },
  logEmpty: { color: '#999', fontStyle: 'italic' },
  logEntry: { fontSize: 11, color: '#333', marginBottom: 2 },
});
