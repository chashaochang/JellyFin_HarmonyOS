import { HMInterceptor, HMInterceptorAction, HMInterceptorInfo, IHMInterceptor } from "@hadss/hmrouter";
import { OneMoreUtil } from "../../utils/OneMoreUtil";
import { WindowUtil } from "../../utils/WindowUtil";
import { AppStorageV2, display } from "@kit.ArkUI";
import { AppUIState } from "../../entity/AppUIState";
import { NavModifier } from "../../pages/Index";

@HMInterceptor({ interceptorName: 'jumpInfoInterceptor', global: true })
export class JumpInfoInterceptor implements IHMInterceptor {
  handle(info: HMInterceptorInfo): HMInterceptorAction {
    let connectionInfo: string = info.type === 'push' ? 'jump to' : 'back to';
    console.log(`${info.srcName} ${connectionInfo} ${info.targetName}`)
    let appOrientation: AppUIState = AppStorageV2.connect(AppUIState, () => new AppUIState())!
    if (info.type === 'push' && info.targetName === '/Player') {
      if (OneMoreUtil.isNormalPhone()) {//普通手机
        //跳转到PlayerView支持旋转
        WindowUtil.setMainWindowRestricted(getContext(this))
      }
    } else if (info.type === 'pop' && info.srcName === '/Player') {
      if (OneMoreUtil.isNormalPhone()) {//普通手机
        //跳出PlayerView锁定竖屏
        WindowUtil.setMainWindowPortrait(getContext(this))
      } else {
        //跳转到PlayerView支持旋转
        if (OneMoreUtil.isBigScreen() && (appOrientation.orientation == display.Orientation.LANDSCAPE ||
          appOrientation.orientation == display.Orientation.LANDSCAPE_INVERTED)) {
          //横屏退出分栏模式
          let modifier = AppStorage.get<NavModifier>('modifier')
          let navInstance = modifier?.instance
          navInstance?.mode(NavigationMode.Stack)
          navInstance?.navBarWidth('100%')
        }
      }

    }
    return HMInterceptorAction.DO_NEXT;
  }
}