import { deviceInfo } from "@kit.BasicServicesKit";
import { AppStorageV2, display, window } from "@kit.ArkUI";
import { HMRouterMgr } from "@hadss/hmrouter";
import { Constants } from "./Constants";
import { NavModifier } from "../pages/Index";
import { AppUIState } from "../entity/AppUIState";

export class OneMoreUtil {
  //是否大屏设备(需要分栏的) 暂时没适配折叠屏
  static isBigScreen() {
    return deviceInfo.deviceType == 'tablet' || deviceInfo.deviceType == 'car' || deviceInfo.deviceType == '2in1'
  }

  //是正常的小屏手机
  static isNormalPhone() {
    return deviceInfo.deviceType == 'phone' && !OneMoreUtil.isFoldable()
  }

  //是不是折叠屏
  static isFoldable(): boolean {
    if (canIUse('SystemCapability.Window.SessionManager')) {
      if (deviceInfo.deviceType == 'phone' && display.isFoldable()) {
        return true
      }
    }
    return false
  }

  static isPc() {
    return deviceInfo.deviceType == '2in1'
  }

  static getNavigationMode(currentDisplay: display.Orientation): NavigationMode {
    switch (currentDisplay) {
      case display.Orientation.PORTRAIT:
      case display.Orientation.PORTRAIT_INVERTED:
        return NavigationMode.Stack
      case display.Orientation.LANDSCAPE:
      case display.Orientation.LANDSCAPE_INVERTED:
        let stack = HMRouterMgr.getPathStack(Constants.NAVIGATION_ID)
        if (stack && stack.size() > 0) {
          return NavigationMode.Split
        } else {
          return NavigationMode.Stack
        }
    }
  }

  static updateNavModifier(appUIState: AppUIState, instance?: NavigationAttribute) {
    let modifier = AppStorage.get<NavModifier>('modifier')
    let navInstance = instance || modifier?.instance
    let mode = OneMoreUtil.getNavigationMode(appUIState.orientation)
    if (OneMoreUtil.isBigScreen() && !OneMoreUtil.isPc()) {
      navInstance?.mode(mode)
    } else {
      mode = NavigationMode.Stack
    }
    navInstance?.mode(mode)
    if (appUIState.isFullScreen) {
      navInstance?.navBarWidth(0)
    } else {
      if (mode == NavigationMode.Stack) {
        navInstance?.navBarWidth('100%')
      } else {
        navInstance?.navBarWidth('33%')
      }
    }

  }

  static maximize(): void {
    window.getLastWindow(getContext()).then((mainWindowClass)=>{
      if(canIUse("SystemCapability.Window.SessionManager")){
        if (mainWindowClass.getWindowStatus() === window.WindowStatusType.FLOATING) {
          mainWindowClass.maximize()
        }
      }
    })
  }

  static recover() {
    window.getLastWindow(getContext()).then((mainWindowClass)=>{
      if(canIUse("SystemCapability.Window.SessionManager")){
        if (mainWindowClass.getWindowStatus() === window.WindowStatusType.FULL_SCREEN) {
          mainWindowClass.recover()
        }
      }
    })
  }
}