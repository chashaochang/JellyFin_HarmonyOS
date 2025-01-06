import { HMLifecycle, HMLifecycleContext, HMRouterMgr, IHMLifecycle } from "@hadss/hmrouter";
import { emitter } from "@kit.BasicServicesKit";
import { SmartDialog } from "ohos_smart_dialog";
import { Constants } from "../../utils/Constants";


/**
 * @Author: csc
 * @CreateDate: 2024/12/17 9:44
 * @Description: 播放器页面生命周期
 */
// @HMLifecycle({ lifecycleName: 'playerLifecycle', global: true })
export class PlayerLifecycle implements IHMLifecycle {

  onBackPressed(ctx: HMLifecycleContext): boolean {
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'onBackPressed'
      }
    })
    SmartDialog.dismiss()
    return true
  }

  onPageShow() {

  }

  onPageHide() {

  }

  onShown(ctx: HMLifecycleContext): void {
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'onPageShow'
      }
    })
  }

  onHidden(ctx: HMLifecycleContext): void {
    emitter.emit(Constants.PLAYER_EVENT, {
      data: {
        'eventName': 'onPageHide'
      }
    })
  }


}