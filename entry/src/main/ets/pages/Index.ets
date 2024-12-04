import { ConnectScreen } from '../features/ConnectScreen'
import { WebViewScreen } from '../features/WebViewScreen'
import { MainViewModel, ServerState } from './MainViewModel'
import { common } from '@kit.AbilityKit';
import { ActivityEventHandler } from '../events/ActivityEventHandler';
import { BaseVideoPlayer, GlobalContext, OrientationUtil } from '@ohos/gsyvideoplayer';
import { window } from '@kit.ArkUI';
import { WindowUtil } from '../utils/WindowUtil';

@Entry
@Component
struct Index {
  @Provide('appPathStack') pathStack: NavPathStack = new NavPathStack()
  private eventHub: common.EventHub = (getContext() as common.UIAbilityContext).eventHub;
  private activityEventHandler: ActivityEventHandler = new ActivityEventHandler(this.eventHub)
  @Provide viewModel: MainViewModel = new MainViewModel()
  @Provide showExternalConnectionError: boolean = false

  aboutToAppear(): void {
    setTimeout(() => {
      this.viewModel.refreshServer()
    }, 200)
    this.activityEventHandler.subscribe(this.pathStack)
    this.pathStack.setInterception({
      // 页面跳转前拦截，允许操作栈，在当前跳转中生效。
      willShow: (from: NavDestinationContext | "navBar", to: NavDestinationContext | "navBar",
        operation: NavigationOperation, animated: boolean) => {
        // if (typeof to === "string") {
        //   console.log("target page is navigation home");
        //   return;
        // }
        if(typeof from === 'string' && typeof to !=='string'){
          if(to.pathInfo.name.indexOf('PlayerView')>=0){
            WindowUtil.setMainWindowLandscape(getContext(this))
          }
        }
        if(typeof to === 'string' && typeof from !=='string'){
          if(from.pathInfo.name.indexOf('PlayerView')>=0){
            WindowUtil.setMainWindowPortrait(getContext(this))
          }
        }
        // 重定向目标页面，更改为pageTwo页面到pageOne页面。
        // let target: NavDestinationContext = to as NavDestinationContext;
        // if (target.pathInfo.name === 'pageTwo') {
        //   target.pathStack.pop();
        //   target.pathStack.pushPathByName('pageOne', null);
        // }
      },
      // 页面跳转后回调，在该回调中操作栈在下一次跳转中刷新。
      didShow: (from: NavDestinationContext | "navBar", to: NavDestinationContext | "navBar",
        operation: NavigationOperation, isAnimated: boolean) => {
        if (typeof from === "string") {
          console.log("current transition is from navigation home");
        } else {
          console.log(`current transition is from  ${(from as NavDestinationContext).pathInfo.name}`)
        }
        if (typeof to === "string") {
          console.log("current transition to is navBar");
        } else {
          console.log(`current transition is to ${(to as NavDestinationContext).pathInfo.name}`);
        }
      },
    })
  }

  aboutToDisappear(): void {
    this.activityEventHandler.unsubscribe()
  }


  build() {
    Navigation(this.pathStack) {
      Stack() {
        if (this.viewModel.serverState === ServerState.Unset) {
          ConnectScreen()
        } else {
          WebViewScreen({
            server: this.viewModel.serverState.server
          })
        }
      }.width('100%').height('100%')
    }.hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .width('100%').height('100%')
  }
}