export type MessageType = 'request' | 'response' | 'notification' | 'broadcast';
export type StackId = 'native' | 'rn' | 'flutter' | 'webview' | '*';

export interface EventMessage {
  id: string;
  type: MessageType;
  channel: string;
  source: StackId;
  target: StackId;
  payload: Record<string, any>;
  callbackId?: string;
  timestamp: number;
}
