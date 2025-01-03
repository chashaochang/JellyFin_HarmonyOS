import { HMRouter, HMRouterMgr } from "@hadss/hmrouter"
import { GlobalContext,
  IjkPlayerControl,
  StandardGSYVideoModel, StandardGSYVideoPlayer } from "player"
import { ToastUtil } from "@pura/harmony-utils"
import { PlayOptions } from "../../player/interaction/PlayOptions"
import { PlayerException } from "../../player/PlayerException"
import { PlayerViewModel } from "./PlayerViewModel"
import { PiPWindow } from "@kit.ArkUI"
import { Constants } from "../../utils/Constants"
import { common } from "@kit.AbilityKit"
import { Subtitle } from "../../entity/Subtitle"

@HMRouter({
  pageUrl: '/Player',
  interceptors: ['jumpInfoInterceptor'],
  // lifecycle: 'playerLifecycle',
  // animator: 'pageAnimator'
})
@ComponentV2
export struct PlayerView {
  options: PlayOptions = HMRouterMgr.getCurrentParam() as PlayOptions
  @Local videoModel: StandardGSYVideoModel = new StandardGSYVideoModel();
  @Local viewModel: PlayerViewModel = new PlayerViewModel(this.videoModel)
  pipController?: PiPWindow.PiPController;
  xComponentController?: XComponentController
  backClickListener: () => void = () => {
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.stop();
    }
    HMRouterMgr.pop()
  }

  async aboutToAppear(): Promise<void> {
    switch (this.viewModel.queueManager.initializePlaybackQueue(this.options)) {
      case PlayerException.InvalidPlayOptions:
        ToastUtil.showToast('无法解析播放信息')
        break
      case PlayerException.NetworkFailure:
        ToastUtil.showToast('无法从服务器加载媒体信息')
        break
      case PlayerException.UnsupportedContent:
        ToastUtil.showToast('该媒体无法在本设备上播放')
        break
      default:
        break
    }
    this.videoModel.setBackClickListener(this.backClickListener);
    // this.videoModel.setFullClickListener(this.fullClickListener);
    this.videoModel.setCoverImage($r('app.media.app_icon'));
    //监听切换到桌面/恢复状态开启关闭画中画
    let context = getContext(this) as common.UIAbilityContext;
    context.eventHub.on('onForeground', () => {
      if (canIUse('SystemCapability.Window.SessionManager')) {
        this.pipController?.stopPiP()
      }
    })
    context.eventHub.on('onBackground', async () => {

    })
  }

  async aboutToDisappear(): Promise<void> {
    //后台播放音频
    // if (!this.viewModel.notificationHelper.allowBackgroundAudio) {
    //   this.viewModel.pause()
    // }
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (player) {
      player.stop();
      player.release()
    }
    await this.viewModel.reportPlaybackStop()
    let context = getContext(this) as common.UIAbilityContext;
    context.eventHub.off('onForeground')
    context.eventHub.off('onBackground')
  }

  async createPipController() {
    if (canIUse('SystemCapability.Window.SessionManager')) {
      let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
      if (player) {
        this.xComponentController = player.xComponentController
      }
      this.pipController = await PiPWindow.create({
        context: getContext(this),
        componentController: this.xComponentController,
        navigationId: Constants.NAVIGATION_ID,
        templateType: PiPWindow.PiPTemplateType.VIDEO_PLAY
      });
      this.pipController.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
        this.onStateChange(state, reason);
      });
      this.pipController.on('controlPanelActionEvent', (event: PiPWindow.PiPActionEventType, status?: number) => {
        this.onActionEvent(event, status);
      });
    }
  }

  onStateChange(state: PiPWindow.PiPState, reason: string) {
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    if (canIUse('SystemCapability.Window.SessionManager')) {
      switch (state) {
        case PiPWindow.PiPState.ABOUT_TO_START:
          // this.curState = 'ABOUT_TO_START';
          // this.curError = $r('app.string.current_error_hint');
          break;
        case PiPWindow.PiPState.STARTED:
          // this.curState = 'STARTED';
          // this.curError = $r('app.string.current_error_hint');
          break;
        case PiPWindow.PiPState.ABOUT_TO_STOP:
          // this.curState = 'ABOUT_TO_STOP';
          // this.curError = $r('app.string.current_error_hint');
          //点了画中画的关闭按钮
          if (player) {
            player.stop();
          }
          break;
        case PiPWindow.PiPState.STOPPED:
          if (player) {
            //player.updatePlayStatus(true);
            player.resumePlay();
          }
          break;
        case PiPWindow.PiPState.ABOUT_TO_RESTORE:
          // this.curState = 'ABOUT_TO_RESTORE';
          // this.curError = $r('app.string.current_error_hint');
          break;
        case PiPWindow.PiPState.ERROR:
          // this.curState = 'ERROR';
          // this.curError = reason;
          break;
        default:
          break;
      }
      // Logger.info(`[${TAG}] onStateChange: ${this.curState}, reason: ${reason}`);
    }
  }

  onActionEvent(event: PiPWindow.PiPActionEventType, status: number | undefined) {
    let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    switch (event) {
      case 'playbackStateChanged':
        if (status === 0) {
          //this.player?.updatePlayStatus(false);
          if (player) {
            player.pause();
          }
        } else {
          //this.player?.updatePlayStatus(true);
          if (player) {
            //player.updatePlayStatus(true);
            player.resumePlay();
          }
        }
        break;
      default:
        break;
    }
    // this.buttonAction = event + `-status:${status}`;
    // Logger.info(`[${TAG}] onActionEvent: ${this.buttonAction} status:${status}}`);
  }

  build() {
    Stack() {
      StandardGSYVideoPlayer({
        videoModel: this.videoModel,
        onInit: async () => {
          // this.viewModel.setupPlayer()
          //开启自动画中画
          if (canIUse('SystemCapability.Window.SessionManager')) {
            if (!this.pipController) {
              await this.createPipController();
              this.pipController!.setAutoStartEnabled(true);
            }
          }
        },
      }).width('100%')
        .height('100%')
    }.width('100%')
    .height('100%')
    .alignContent(Alignment.Bottom)
  }
}