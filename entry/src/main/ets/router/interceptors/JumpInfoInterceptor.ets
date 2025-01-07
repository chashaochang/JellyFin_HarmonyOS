import { HMInterceptor, HMInterceptorAction, HMInterceptorInfo, IHMInterceptor } from "@hadss/hmrouter";
import { WindowUtil } from "../../utils/WindowUtil";

@HMInterceptor({ interceptorName: 'jumpInfoInterceptor', global: true })
export class JumpInfoInterceptor implements IHMInterceptor {
  handle(info: HMInterceptorInfo): HMInterceptorAction {
    let connectionInfo: string = info.type === 'push' ? 'jump to' : 'back to';
    console.log(`${info.srcName} ${connectionInfo} ${info.targetName}`)
    if(info.type === 'push' && info.targetName === '/Player'){
      //跳转到PlayerView支持旋转
      WindowUtil.setMainWindowRestricted(getContext(this))
    } else if(info.type === 'pop' && info.srcName === '/Player'){
      //跳出PlayerView锁定竖屏
      WindowUtil.setMainWindowPortrait(getContext(this))
    }
    return HMInterceptorAction.DO_NEXT;
  }
}