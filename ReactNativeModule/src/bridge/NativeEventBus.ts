import { NativeModules, NativeEventEmitter } from 'react-native';
import { EventMessage, StackId } from './types';

const { EventBridgeModule } = NativeModules;
const emitter = new NativeEventEmitter(EventBridgeModule);

function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
  });
}

const pendingCallbacks = new Map<string, (msg: EventMessage) => void>();
const channelHandlers = new Map<string, Array<(msg: EventMessage) => void>>();

emitter.addListener('onEventMessage', (jsonString: string) => {
  try {
    const msg: EventMessage = JSON.parse(jsonString);

    if (msg.type === 'response' && msg.callbackId) {
      const callback = pendingCallbacks.get(msg.callbackId);
      if (callback) {
        callback(msg);
        pendingCallbacks.delete(msg.callbackId);
      }
      return;
    }

    const handlers = channelHandlers.get(msg.channel) || [];
    handlers.forEach((h) => h(msg));

    const allHandlers = channelHandlers.get('*') || [];
    allHandlers.forEach((h) => h(msg));
  } catch (e) {
    console.error('[NativeEventBus] Parse error:', e);
  }
});

export const NativeEventBus = {
  sendRequest(
    target: StackId,
    channel: string,
    payload: Record<string, any> = {},
  ): Promise<EventMessage> {
    const callbackId = generateUUID();
    const msg: EventMessage = {
      id: generateUUID(),
      type: 'request',
      channel,
      source: 'rn',
      target,
      payload,
      callbackId,
      timestamp: Date.now(),
    };
    return new Promise((resolve) => {
      pendingCallbacks.set(callbackId, resolve);
      EventBridgeModule.sendMessage(JSON.stringify(msg));
    });
  },

  sendNotification(
    target: StackId,
    channel: string,
    payload: Record<string, any> = {},
  ): void {
    const msg: EventMessage = {
      id: generateUUID(),
      type: 'notification',
      channel,
      source: 'rn',
      target,
      payload,
      timestamp: Date.now(),
    };
    EventBridgeModule.sendMessage(JSON.stringify(msg));
  },

  broadcast(channel: string, payload: Record<string, any> = {}): void {
    const msg: EventMessage = {
      id: generateUUID(),
      type: 'broadcast',
      channel,
      source: 'rn',
      target: '*',
      payload,
      timestamp: Date.now(),
    };
    EventBridgeModule.sendMessage(JSON.stringify(msg));
  },

  respond(originalMsg: EventMessage, payload: Record<string, any> = {}): void {
    const msg: EventMessage = {
      id: generateUUID(),
      type: 'response',
      channel: originalMsg.channel,
      source: 'rn',
      target: originalMsg.source,
      payload,
      callbackId: originalMsg.callbackId,
      timestamp: Date.now(),
    };
    EventBridgeModule.sendMessage(JSON.stringify(msg));
  },

  subscribe(channel: string, handler: (msg: EventMessage) => void): () => void {
    const handlers = channelHandlers.get(channel) || [];
    handlers.push(handler);
    channelHandlers.set(channel, handlers);
    return () => {
      const idx = handlers.indexOf(handler);
      if (idx >= 0) handlers.splice(idx, 1);
    };
  },
};
