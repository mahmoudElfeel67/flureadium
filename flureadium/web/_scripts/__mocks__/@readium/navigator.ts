export class EpubNavigator {
  _cframes: any[] = [];
  publication: any = { resources: { findWithHref: () => null, items: [] } };
  currentLocator: any = {};
  goRight(_animated: boolean, _cb: Function) {}
  goLeft(_animated: boolean, _cb: Function) {}
  goLink(_link: any, _animated: boolean, _cb: Function) {}
  goForward(_animated: boolean, _cb: Function) {}
  submitPreferences(_prefs: any) {}
  destroy() {}
  async load() {}
}

export class WebPubNavigator extends EpubNavigator {}

export class FrameManager {
  window: Window = globalThis.window;
}

export class FXLFrameManager extends FrameManager {}

export enum TextAlignment {
  left = 'left',
  right = 'right',
  start = 'start',
  justify = 'justify',
}

export type EpubNavigatorListeners = any;
export type EpubNavigatorConfiguration = any;
