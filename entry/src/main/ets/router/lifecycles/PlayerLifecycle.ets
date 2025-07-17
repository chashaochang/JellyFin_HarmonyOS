import { HMLifecycle, HMLifecycleContext, HMRouterMgr, IHMLifecycle } from "@hadss/hmrouter";
import { emitter } from "@kit.BasicServicesKit";
import { SmartDialog } from "ohos_smart_dialog";
import { PlayOptions } from "../../player/interaction/PlayOptions";
import { Constants } from "../../utils/Constants";


/**
 * @Author: csc
 * @CreateDate: 2024/12/17 9:44
 * @Description: 播放器页面生命周期
 */
@ObservedV2
@HMLifecycle({ lifecycleName: 'playerLifecycle' })
export class PlayerLifecycle implements IHMLifecycle {
  @Trace options: PlayOptions = HMRouterMgr.getCurrentParam() as PlayOptions

  //现阶段可以通过HMRouter提供的onPrepare生命周期来获取参数,需要依赖API19中新增的NavDestination的onNewParam生命周期来刷新参数，单例页面
  onPrepare(ctx: HMLifecycleContext): void {
    this.options = HMRouterMgr.getCurrentParam() as PlayOptions
  }

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