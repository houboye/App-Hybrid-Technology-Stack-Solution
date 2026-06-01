import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { NativeRouter } from '../bridge/NativeRouter';

interface Props {
  id?: string;
}

export const RNDetailPage: React.FC<Props> = ({ id }) => {
  return (
    <View style={styles.container}>
      <Text style={styles.badge}>⚛️ React Native</Text>
      <Text style={styles.title}>Detail Page</Text>
      <Text style={styles.paramText}>ID: {id || 'none'}</Text>

      <TouchableOpacity style={styles.button} onPress={() => NativeRouter.pop()}>
        <Text style={styles.buttonText}>Go Back</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={[styles.button, styles.secondary]}
        onPress={() => NativeRouter.toFlutterDetail(id || '1')}>
        <Text style={styles.secondaryText}>
          Open Flutter Detail (same ID)
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
    padding: 24,
  },
  badge: { fontSize: 28, fontWeight: 'bold', color: '#61DAFB' },
  title: { fontSize: 22, fontWeight: '600', marginTop: 8 },
  paramText: { fontSize: 16, color: '#666', marginTop: 8, marginBottom: 24 },
  button: {
    backgroundColor: '#61DAFB',
    padding: 14,
    borderRadius: 8,
    width: '80%',
    alignItems: 'center',
    marginBottom: 12,
  },
  buttonText: { color: '#000', fontSize: 16, fontWeight: '500' },
  secondary: { backgroundColor: 'transparent', borderWidth: 1, borderColor: '#61DAFB' },
  secondaryText: { color: '#61DAFB', fontSize: 16 },
});
