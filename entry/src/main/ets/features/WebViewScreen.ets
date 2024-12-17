import { webview } from "@kit.ArkWeb";
import { NativeInterface } from "../bridge/NativeInterface";
import { NativePlayer } from "../bridge/NativePlayer";
import { Constants } from "../utils/Constants";
import { url, util } from "@kit.ArkTS";
import { ExternalPlayer } from "../bridge/ExternalPlayer";
import { JSONUtil } from "@pura/harmony-utils";
import ServerEntity from "../data/ServerEntity";
import { ApiClientController } from "../data/ApiClientController";

@ComponentV2
export struct WebViewScreen {
  @Local server: ServerEntity = AppStorage.get<ServerEntity>('server') ?? new ServerEntity()
  controller: webview.WebviewController = new webview.WebviewController();
  responseWeb: WebResourceResponse = new WebResourceResponse();
  apiClientController: ApiClientController = new ApiClientController()

  aboutToAppear(): void {
    // 配置Web开启调试模式
    webview.WebviewController.setWebDebuggingAccess(true);
  }

  build() {
    Column() {
      Web({
        controller: this.controller,
        src: this.server.hostname
      })
        //.backgroundColor($r('app.color.start_window_background'))
        .darkMode(WebDarkMode.Auto)
        .domStorageAccess(true)
        .zoomAccess(true)
        .fileAccess(true)
        .mixedMode(MixedMode.All)
        .cacheMode(CacheMode.Default)
        .javaScriptAccess(true)
        .onControllerAttached(() => {
          this.controller.registerJavaScriptProxy(new NativeInterface(), 'NativeInterface',
            ['getDeviceInformation', 'enableFullscreen', 'disableFullscreen', 'openUrl', 'updateMediaSession',
              'hideMediaSession', 'updateVolumeLevel', 'downloadFiles', 'openClientSettings', 'openServerSelection',
              'exitApp'])
          this.controller.registerJavaScriptProxy(new NativePlayer(), 'NativePlayer',
            ['isEnabled', 'loadPlayer', 'pausePlayer', 'resumePlayer', 'stopPlayer', 'destroyPlayer', 'seek', 'seekMs',
              'setVolume'])
          this.controller.registerJavaScriptProxy(new ExternalPlayer(), 'ExternalPlayer', ['isEnabled'])
        })
        .onInterceptRequest((event) => {
          if (!event) {
            return;
          }
          // 此处匹配自己想要加载的本地离线资源，进行资源拦截替换，绕过跨域
          let path = event.request.getRequestUrl()
          if (path.match(Constants.MAIN_BUNDLE_PATH_REGEX) && !path?.includes('deferred')) {
            const promise: Promise<String> = new Promise((resolve: Function, reject: Function) => {
              let buffer = getContext().resourceManager.getRawFileContentSync('native/injectionScript.js')
              let decoder = util.TextDecoder.create('utf-8');
              let str = decoder.decodeToString(new Uint8Array(buffer));
              this.responseWeb.setResponseData(str)
              this.responseWeb.setResponseMimeType('application/javascript')
              this.responseWeb.setResponseEncoding('utf-8');
              this.responseWeb.setResponseCode(200);
              this.responseWeb.setReasonMessage('OK');
              console.log('注入native/injectionScript.js');
              resolve("success");
            })
            promise.then(() => {
              console.log("prepare response ready");
              this.responseWeb.setResponseIsReady(true);
            })
            this.responseWeb.setResponseIsReady(false);
            return this.responseWeb
          }
          if (path.includes('/native/')) {
            const promise: Promise<String> = new Promise((resolve: Function, reject: Function) => {
              let buffer = getContext().resourceManager.getRawFileContentSync(`native/${getLastPathSegment(path)}`)
              let decoder = util.TextDecoder.create('utf-8');
              let str = decoder.decodeToString(new Uint8Array(buffer));
              this.responseWeb.setResponseData(str)
              this.responseWeb.setResponseMimeType('application/javascript')
              this.responseWeb.setResponseEncoding('utf-8');
              this.responseWeb.setResponseCode(200);
              this.responseWeb.setReasonMessage('OK');
              console.log(`注入native/${getLastPathSegment(path)}`);
              resolve("success");
            })
            promise.then(() => {
              console.log("prepare response ready");
              this.responseWeb.setResponseIsReady(true);
            })
            this.responseWeb.setResponseIsReady(false);
            return this.responseWeb
          }
          if (path.toLowerCase().endsWith(Constants.SESSION_CAPABILITIES_PATH)) {
            this.controller.runJavaScript("JSON.parse(window.localStorage.getItem('jellyfin_credentials'))")
              .then(result => {
                const credentials: Credentials | null = JSONUtil.jsonToBean(Credentials, result)
                if (credentials) {
                  let server = credentials.Servers[0]
                  this.apiClientController.setupUser(this.server.id, server.UserId, server.AccessToken)
                  AppStorage.setOrCreate('userId', server.UserId)
                }
              })
              .catch(() => {
                throw Error('Failed to extract credentials')
              })

          }
          return null
        })
    }.width('100%').height('100%')
  }
}

function getLastPathSegment(path: string): string {
  // 使用 split 方法
  const segments = path.split('/')

  // 返回最后一个非空片段
  return segments[segments.length - 1]
}

class Credentials {
  Servers: Server[]

  constructor(Servers: Server[]) {
    this.Servers = Servers
  }
}

interface Server {
  UserId: string
  AccessToken: string
}