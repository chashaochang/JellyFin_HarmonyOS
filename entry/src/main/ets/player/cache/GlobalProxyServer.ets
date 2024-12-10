import common from '@ohos.app.ability.common';
import { HttpProxyCacheServer } from '@ohos/video-cache';

export default class GlobalProxyServer {
  private CONTEXT_STR: string = 'getContext';
  private SERVER_STR: string = 'getServer';
  private static instance: GlobalProxyServer;
  private _objects: Map<string, Object | null> = new Map<string, Object | null>();

  private constructor() {
  }

  public static getInstance(): GlobalProxyServer {
    if (!GlobalProxyServer.instance) {
      GlobalProxyServer.instance = new GlobalProxyServer()
    }
    return GlobalProxyServer.instance;
  }

  getContext(): common.UIAbilityContext {
    return this._objects.get(this.CONTEXT_STR) as common.UIAbilityContext;
  }

  setContext(objectClass: common.UIAbilityContext) {
    this._objects.set(this.CONTEXT_STR, objectClass);
  }

  getServer(): HttpProxyCacheServer {
    return this._objects.get(this.SERVER_STR) as HttpProxyCacheServer;
  }

  setServer(objectClass: HttpProxyCacheServer) {
    try {
      let currentServer: HttpProxyCacheServer = this.getServer();
      currentServer.shutdown()
    } catch (err) {
    }
    this._objects.set(this.SERVER_STR, objectClass);
  }
}