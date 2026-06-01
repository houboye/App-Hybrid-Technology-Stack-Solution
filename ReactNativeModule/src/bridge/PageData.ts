import { NativeModules } from 'react-native';
import { StackId } from './types';

const { PageDataModule } = NativeModules;

export interface PageDataEntry {
  dataId: string;
  source: StackId;
  target: StackId;
  route?: string;
  data: Record<string, any>;
  timestamp: number;
  ttl: number;
}

export const PageData = {
  put(
    target: StackId,
    data: Record<string, any>,
    route?: string,
    ttl: number = 300000,
  ): Promise<string> {
    return PageDataModule.put(
      JSON.stringify({
        source: 'rn',
        target,
        route: route || null,
        data,
        ttl,
      }),
    );
  },

  get(dataId: string): Promise<PageDataEntry | null> {
    return PageDataModule.get(dataId).then((jsonString: string | null) => {
      if (!jsonString) return null;
      return JSON.parse(jsonString) as PageDataEntry;
    });
  },

  consume(dataId: string): Promise<PageDataEntry | null> {
    return PageDataModule.consume(dataId).then((jsonString: string | null) => {
      if (!jsonString) return null;
      return JSON.parse(jsonString) as PageDataEntry;
    });
  },

  getByRoute(route: string): Promise<PageDataEntry | null> {
    return PageDataModule.getByRoute(route).then((jsonString: string | null) => {
      if (!jsonString) return null;
      return JSON.parse(jsonString) as PageDataEntry;
    });
  },

  consumeByRoute(route: string): Promise<PageDataEntry | null> {
    return PageDataModule.consumeByRoute(route).then(
      (jsonString: string | null) => {
        if (!jsonString) return null;
        return JSON.parse(jsonString) as PageDataEntry;
      },
    );
  },
};
