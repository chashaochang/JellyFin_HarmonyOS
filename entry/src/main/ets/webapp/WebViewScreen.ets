import { webview } from "@kit.ArkWeb";
import { NativeInterface } from "../bridge/NativeInterface";
import { NativePlayer } from "../bridge/NativePlayer";
import { Constants } from "../utils/Constants";
import { util } from "@kit.ArkTS";
import { ExternalPlayer } from "../bridge/ExternalPlayer";
import { JSONUtil } from "@pura/harmony-utils";
import ServerEntity from "../data/ServerEntity";
import { ApiClientController } from "../data/ApiClientController";
import { WebappEvents } from "./WebappEvents";
import { BackController } from "./BackController";
import { ActivityEventHandler } from "../events/ActivityEventHandler";
import { common } from "@kit.AbilityKit";
import mainViewModel, { MainViewModel } from "../pages/MainViewModel";

@ComponentV2
export struct WebViewScreen {
  @Local server: ServerEntity = AppStorage.get<ServerEntity>('server') ?? new ServerEntity()
  controller: webview.WebviewController = new webview.WebviewController();
  responseWeb: WebResourceResponse = new WebResourceResponse();
  apiClientController: ApiClientController = new ApiClientController()
  timeoutId = -1
  connected = false
  webappEvents: WebappEvents = new WebappEvents(getContext())
  backController: BackController = new BackController()
  @Param @Require onBackController: (controller: BackController) => void
  @Consumer() showExternalConnectionError: boolean = false
  @Consumer() mainViewModel: MainViewModel = mainViewModel
  @Consumer() activityEventHandler: ActivityEventHandler =
    new ActivityEventHandler((getContext() as common.UIAbilityContext).eventHub, this.mainViewModel)

  aboutToAppear(): void {
    this.onBackController(this.backController)
    this.backController.setOnBackPressListener(() => {
      return this.connected && this.webappEvents.goBack()
    })
    getContext().eventHub.on('webappFunction', (action: string) => {
      this.controller.loadUrl(`javascript:${action}`)
    })
    // 配置Web开启调试模式
    webview.WebviewController.setWebDebuggingAccess(true);
    this.timeoutId = setTimeout(() => {
      this.handleError()
    }, Constants.INITIAL_CONNECTION_TIMEOUT)
  }

  aboutToDisappear(): void {
    getContext().eventHub.off('webappFunction')
  }

  handleError() {
    this.connected = false
    this.onSelectServer(true)
  }

  onSelectServer(error: boolean = false) {
    this.showExternalConnectionError = error
  }

  build() {
    Column() {
      Web({
        controller: this.controller,
        src: this.server.hostname
      })
        .backgroundColor($r('app.color.start_window_background'))
        .darkMode(WebDarkMode.Auto)
        .domStorageAccess(true)
        .zoomAccess(true)
        .fileAccess(true)
        .mixedMode(MixedMode.All)
        .cacheMode(CacheMode.Default)
        .javaScriptAccess(true)
        .onControllerAttached(() => {
          this.controller.registerJavaScriptProxy(new NativeInterface(this.activityEventHandler), 'NativeInterface',
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
              this.onConnectedToWebapp()
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
        // .onErrorReceive((err) => {
        //   this.handleError()
        // })
        .onHttpErrorReceive((e) => {
          if(e.request.getRequestUrl() == this.server.hostname){
            this.handleError()
          }
        })
        .onSslErrorEventReceive((event) => {
          event.handler.handleCancel()
          this.handleError()
        })
    }.width('100%').height('100%')
  }

  onConnectedToWebapp() {
    clearTimeout(this.timeoutId)
    this.connected = true
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