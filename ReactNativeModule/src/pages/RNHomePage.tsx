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
import { EventMessage } from '../bridge/types';

export const RNHomePage: React.FC = () => {
  const [eventLog, setEventLog] = useState<string[]>([]);
  const [responseText, setResponseText] = useState<string>('');

  useEffect(() => {
    const unsubscribe = NativeEventBus.subscribe('*', (msg: EventMessage) => {
      const logEntry = `[${msg.source}] ${msg.channel}: ${JSON.stringify(msg.payload)}`;
      setEventLog((prev) => [...prev.slice(-19), logEntry]);
    });
    return unsubscribe;
  }, []);

  const handleSendRequest = async () => {
    const response = await NativeEventBus.sendRequest('native', 'getUserInfo', {
      userId: '1',
    });
    setResponseText(JSON.stringify(response.payload));
  };

  const handleBroadcast = () => {
    NativeEventBus.broadcast('greeting', {
      message: 'Hello from React Native!',
    });
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.badge}>⚛️ React Native</Text>
      <Text style={styles.subtitle}>Home Page</Text>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Navigation</Text>
        <TouchableOpacity
          style={styles.button}
          onPress={() => NativeRouter.toFlutterHome()}>
          <Text style={styles.buttonText}>Navigate to Flutter</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.button}
          onPress={() => NativeRouter.toWebView('local://webHome.html')}>
          <Text style={styles.buttonText}>Navigate to WebView</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.button}
          onPress={() => NativeRouter.toNativeDemo()}>
          <Text style={styles.buttonText}>Navigate to Native Demo</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.button}
          onPress={() => NativeRouter.toRNDetail('123')}>
          <Text style={styles.buttonText}>Navigate to RN Detail (id=123)</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Communication</Text>
        <TouchableOpacity
          style={[styles.button, styles.outlinedButton]}
          onPress={handleSendRequest}>
          <Text style={styles.outlinedButtonText}>
            Send Request to Native
          </Text>
        </TouchableOpacity>
        {responseText ? (
          <Text style={styles.response}>Response: {responseText}</Text>
        ) : null}
        <TouchableOpacity
          style={[styles.button, styles.outlinedButton]}
          onPress={handleBroadcast}>
          <Text style={styles.outlinedButtonText}>Broadcast Greeting</Text>
        </TouchableOpacity>
      </View>

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
  buttonText: { color: '#000', fontSize: 16, fontWeight: '500' },
  outlinedButton: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#61DAFB',
  },
  outlinedButtonText: { color: '#61DAFB', fontSize: 16, fontWeight: '500' },
  response: { fontSize: 12, color: '#4CAF50', marginVertical: 4 },
  logContainer: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 10,
    minHeight: 100,
    maxHeight: 200,
  },
  logEmpty: { color: '#999', fontStyle: 'italic' },
  logEntry: { fontSize: 11, color: '#333', marginBottom: 2 },
});
