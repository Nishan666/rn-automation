declare module '*.png';
declare module '*.jpg';
declare module '*.jpeg';
declare module '*.gif';
declare module '*.svg' {
  import type { FC, SVGProps } from 'react';
  const content: FC<SVGProps<SVGSVGElement>>;
  export default content;
}
declare module '*.json';

declare module 'react-native-config' {
  export interface NativeConfig {
    ENV_NAME?: string;
    API_URL?: string;
  }

  export const Config: NativeConfig;
  export default Config;
}