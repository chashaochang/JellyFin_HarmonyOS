import { HMLifecycle, HMLifecycleContext, IHMLifecycle } from "@hadss/hmrouter";
import { BaseVideoPlayer } from "@ohos/gsyvideoplayer/Index";
import { GlobalContext } from "@pura/harmony-utils";

/**
 * @Author: csc
 * @CreateDate: 2024/12/17 9:44
 * @Description: 播放器页面生命周期
 */
@HMLifecycle({ lifecycleName: 'playerLifecycle' })
export class PlayerLifecycle implements IHMLifecycle {
  onPageShow() {
    let player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.resumePlay();
    }
  }

  onPageHide() {
    let player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.pause();
    }
  }

  onShown(ctx: HMLifecycleContext): void {

  }

  onHidden(ctx: HMLifecycleContext): void {

  }
}