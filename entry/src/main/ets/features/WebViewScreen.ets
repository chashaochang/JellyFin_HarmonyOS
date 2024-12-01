import { webview } from "@kit.ArkWeb";
import { NativeInterface } from "../bridge/NativeInterface";
import { NativePlayer } from "../bridge/NativePlayer";
import { Constants } from "../utils/Constants";
import { url, util } from "@kit.ArkTS";
import { ExternalPlayer } from "../bridge/ExternalPlayer";

@ComponentV2
export struct WebViewScreen{
  @Param @Require hostname:string

  controller: webview.WebviewController = new webview.WebviewController();
  responseWeb: WebResourceResponse = new WebResourceResponse();

  aboutToAppear(): void {
    // 配置Web开启调试模式
    webview.WebviewController.setWebDebuggingAccess(true);
  }

  build() {
    Column(){
      Web({
        controller: this.controller,
        src: this.hostname
      })
        .darkMode(WebDarkMode.Auto)
        .domStorageAccess(true)
        .zoomAccess(true)
        .fileAccess(true)
        .mixedMode(MixedMode.All)
        .cacheMode(CacheMode.Default)
        .javaScriptAccess(true)
        .onControllerAttached(()=>{
          this.controller.registerJavaScriptProxy(new NativeInterface(),'NativeInterface',['getDeviceInformation'])
          this.controller.registerJavaScriptProxy(new NativePlayer(),'NativePlayer',['isEnabled','loadPlayer'])
          this.controller.registerJavaScriptProxy(new ExternalPlayer(),'ExternalPlayer',['isEnabled'])
        })
        .onInterceptRequest((event)=>{
          if (!event) {
            return;
          }
          // 此处匹配自己想要加载的本地离线资源，进行资源拦截替换，绕过跨域
          let path = event.request.getRequestUrl()
          if(path.match(Constants.MAIN_BUNDLE_PATH_REGEX) && !path?.includes('deferred')){
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
            // let decoder = util.TextDecoder.create('utf-8');
            // let str = decoder.decodeToString(new Uint8Array(buffer));
            // this.controller.runJavaScript(str)
            // console.log('注入native/injectionScript.js');
            // return
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
            // console.log('注入js');
            // let buffer = getContext().resourceManager.getRawFileContentSync(`native/${getLastPathSegment(path)}`)
            // let decoder = util.TextDecoder.create('utf-8');
            // let str = decoder.decodeToString(new Uint8Array(buffer));
            // this.controller.runJavaScript(str)
            // console.log(`注入native/${getLastPathSegment(path)}`);
            // return
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