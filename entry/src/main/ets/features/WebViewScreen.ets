import { webview } from "@kit.ArkWeb";

@ComponentV2
export struct WebViewScreen{
  @Param @Require hostname:string

  controller: webview.WebviewController = new webview.WebviewController();

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
    }.width('100%').height('100%')
  }
}