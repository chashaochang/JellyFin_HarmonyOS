import { HMLifecycle, HMLifecycleContext, HMRouterMgr, IHMLifecycle } from "@hadss/hmrouter";
import { GlobalContext, IjkPlayerControl } from "player/Index";

/**
 * @Author: csc
 * @CreateDate: 2024/12/17 9:44
 * @Description: 播放器页面生命周期
 */
// @HMLifecycle({ lifecycleName: 'playerLifecycle', global: true })
export class PlayerLifecycle implements IHMLifecycle {

  onBackPressed(ctx: HMLifecycleContext): boolean {
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.stop()
      player.release();
    }
    HMRouterMgr.pop()
    return true
  }

  onPageShow() {
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.resumePlay();
    }
  }

  onPageHide() {
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.pause();
    }
  }

  onShown(ctx: HMLifecycleContext): void {

  }

  onHidden(ctx: HMLifecycleContext): void {

  }

  onDisAppear(ctx: HMLifecycleContext): void {
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.stop();
      player.release();
    }
  }
}