import { HMInterceptor, HMInterceptorAction, HMInterceptorInfo, IHMInterceptor } from "@hadss/hmrouter";
import { GlobalContext } from "@pura/harmony-utils";
import { IjkPlayerControl } from "player/Index";
import { WindowUtil } from "../../utils/WindowUtil";

@HMInterceptor({ interceptorName: 'jumpInfoInterceptor', global: true })
export class JumpInfoInterceptor implements IHMInterceptor {
  handle(info: HMInterceptorInfo): HMInterceptorAction {
    let connectionInfo: string = info.type === 'push' ? 'jump to' : 'back to';
    console.log(`${info.srcName} ${connectionInfo} ${info.targetName}`)
    if(info.type === 'push' && info.targetName === '/Player'){
      //跳转到PlayerView横屏
      WindowUtil.setMainWindowLandscape(getContext(this))
    } else if(info.type === 'pop' && info.srcName === '/Player'){
      //跳出PlayerView竖屏
      WindowUtil.setMainWindowRestricted(getContext(this))
      let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl
      if(player){
        player.stop()
        player.release()
      }
    }
    return HMInterceptorAction.DO_NEXT;
  }
}