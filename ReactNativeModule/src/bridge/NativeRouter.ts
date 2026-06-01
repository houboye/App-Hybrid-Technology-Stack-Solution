import { NativeModules } from 'react-native';

const { AppRouterModule } = NativeModules;

export const NativeRouter = {
  navigate(url: string): void {
    AppRouterModule.navigate(url);
  },

  pop(): void {
    AppRouterModule.pop();
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
