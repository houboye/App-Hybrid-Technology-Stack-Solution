import { NativeModules, NativeEventEmitter } from 'react-native';
import { PageData } from './PageData';
import { StackId, EventMessage } from './types';
import { NativeEventBus } from './NativeEventBus';

const { AppRouterModule } = NativeModules;

export interface NavigationLifecycleInfo {
  event: 'pushCompleted' | 'popCompleted' | 'removeCompleted';
  route: string;
  timestamp: number;
}

export type NavigationLifecycleHandler = (info: NavigationLifecycleInfo) => void;

const lifecycleHandlers: Array<{
  event: string;
  handler: NavigationLifecycleHandler;
}> = [];

NativeEventBus.subscribe('navigationLifecycle', (msg: EventMessage) => {
  const info = msg.payload as unknown as NavigationLifecycleInfo;
  if (!info || !info.event) return;
  lifecycleHandlers
    .filter((h) => h.event === info.event || h.event === '*')
    .forEach((h) => h.handler(info));
});

export const NativeRouter = {
  navigate(url: string): void {
    AppRouterModule.navigate(url);
  },

  async navigateWithData(
    url: string,
    data: Record<string, any>,
    ttl?: number,
  ): Promise<string> {
    const host = url.replace('app://', '').split('/')[0] as StackId;
    const dataId = await PageData.put(host, data, url, ttl);
    const separator = url.includes('?') ? '&' : '?';
    AppRouterModule.navigate(`${url}${separator}_dataId=${dataId}`);
    return dataId;
  },

  pop(): void {
    AppRouterModule.pop();
  },

  popWithResult(data: Record<string, any>): void {
    AppRouterModule.popWithResult(JSON.stringify(data));
  },

  removePage(route: string): void {
    AppRouterModule.removePage(route);
  },

  getNavigationStack(): Promise<Array<{ route: string; index: string }>> {
    return AppRouterModule.getNavigationStack();
  },

  onNavigationEvent(
    event: 'pushCompleted' | 'popCompleted' | 'removeCompleted' | '*',
    handler: NavigationLifecycleHandler,
  ): () => void {
    const entry = { event, handler };
    lifecycleHandlers.push(entry);
    return () => {
      const idx = lifecycleHandlers.indexOf(entry);
      if (idx >= 0) lifecycleHandlers.splice(idx, 1);
    };
  },

  toNativeHome() {
    this.navigate('app://native/home');
  },

  toNativeDemo() {
    this.navigate('app://native/demo');
  },

  toRNDetail(id: string) {
    this.navigate(`app://rn/detail?id=${id}`);
  },

  toFlutterHome() {
    this.navigate('app://flutter/home');
  },

  toFlutterDetail(id: string) {
    this.navigate(`app://flutter/detail?id=${id}`);
  },

  toWebView(url: string) {
    this.navigate(`app://webview?url=${encodeURIComponent(url)}`);
  },
};
