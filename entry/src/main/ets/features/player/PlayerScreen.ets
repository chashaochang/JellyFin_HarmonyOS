import { HMRouter, HMRouterMgr } from "@hadss/hmrouter"

import { ToastUtil } from "@pura/harmony-utils"
import { PlayOptions } from "../../player/interaction/PlayOptions"
import { PlayerException } from "../../player/PlayerException"
import { PlayerViewModel } from "./PlayerViewModel"
import { display, PiPWindow, window } from "@kit.ArkUI"
import { Constants } from "../../utils/Constants"
import { common } from "@kit.AbilityKit"
import { Subtitle } from "../../entity/Subtitle"
import { PlayerView } from "./PlayerView"
import { WindowUtil } from "../../utils/WindowUtil"
import { emitter } from "@kit.BasicServicesKit"
import { PlayerUIState } from "./PlayerUIState"
import { QueueItem } from "../../entity/QueueItem"
import { BaseItemKind } from "sdk/src/main/ets/generated-client/models"

@HMRouter({
  pageUrl: '/Player',
  singleton: true,
  lifecycle: 'playerLifecycle',
  interceptors: ['jumpInfoInterceptor']
})
@ComponentV2
export struct PlayerScreen {
  options: PlayOptions = HMRouterMgr.getCurrentParam() as PlayOptions
  @Provider() screenIsFull: boolean = false;
  @Provider() uiState: PlayerUIState = new PlayerUIState()
  @Provider() viewModel: PlayerViewModel = new PlayerViewModel(this.uiState)
  pipController?: PiPWindow.PiPController;
  xComponentController?: XComponentController
  backClickListener: () => void = () => {
    HMRouterMgr.pop()
  }

  async aboutToAppear(): Promise<void> {
    this.viewModel.initAVSession()
    let callback = async () => {
      let defaultDisplay = display.getDefaultDisplaySync()
      this.screenIsFull = defaultDisplay.width > defaultDisplay.height
    }
    try {
      display.on("change", callback); // 监听屏幕状态改变
    } catch (exception) {
      console.error('PlayerScreen', 'Failed to register callback. Code: ' + JSON.stringify(exception));
    }
    emitter.on(Constants.PLAYER_EVENT, (data) => {
      if (data.data && data.data['eventName']) {
        let name = data.data['eventName'] as string
        switch (name) {
          case 'onBackPressed':
            this.onBackPress()
            break
        }
      }
    })
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

  aboutToDisappear() {
    emitter.off(Constants.PLAYER_EVENT.eventId)
    //后台播放音频
    // if (!this.viewModel.notificationHelper.allowBackgroundAudio) {
    //   this.viewModel.pause()
    // }
    // this.viewModel.playerOrNull?.stop()
    // this.viewModel.playerOrNull?.release()
    this.viewModel.reportPlaybackStop()
    let context = getContext(this) as common.UIAbilityContext;
    context.eventHub.off('onForeground')
    context.eventHub.off('onBackground')
    this.viewModel.release()
  }

  async createPipController() {
    if (canIUse('SystemCapability.Window.SessionManager')) {
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
    // let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
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
          // if (player) {
          //   player.stop();
          // }
          break;
        case PiPWindow.PiPState.STOPPED:
          // if (player) {
          //   player.updatePlayStatus(true);
          // player.resumePlay();
          // }
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
    // let player = GlobalContext.getContext().getObject("currentPlayer") as IjkPlayerControl;
    // switch (event) {
    //   case 'playbackStateChanged':
    //     if (status === 0) {
    //this.player?.updatePlayStatus(false);
    // if (player) {
    //   player.pause();
    // }
    // } else {
    //this.player?.updatePlayStatus(true);
    // if (player) {
    //player.updatePlayStatus(true);
    // player.resumePlay();
    // }
    // }
    // break;
    // default:
    //   break;
    // }
    // this.buttonAction = event + `-status:${status}`;
    // Logger.info(`[${TAG}] onActionEvent: ${this.buttonAction} status:${status}}`);
  }

  onBackPress(): boolean | void {
    if (this.screenIsFull) {
      this.screenIsFull = false
    } else {
      HMRouterMgr.pop()
    }
  }

  build() {
    Column() {
      Stack() {
        if (this.viewModel.url) {
          PlayerView({
            videoUrl: this.viewModel.url,
            onNext: () => {
              this.viewModel.queueManager.next()
            }
          }).height(this.screenIsFull ? '100%' : 240)
        }
        Row() {
          Image($r('app.media.ic_back'))
            .width(44)
            .height(44)
            .padding(12)
        }
        .height(56)
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.onBackPress()
        })
        .visibility(this.screenIsFull ? Visibility.None : Visibility.Visible)
      }.width('100%')
      .alignContent(Alignment.Top)

      Column({ space: 10 }) {
        //标题
        Text(this.viewModel.uiState.seriesName ?? this.viewModel.uiState.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(this.uiState.overview)
          .width('100%')
          .textAlign(TextAlign.Start)
          .maxLines(3)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .ellipsisMode(EllipsisMode.END)

        Row() {
          ForEach(this.uiState.genres, (item: string) => {
            Text(item)
              .fontSize(12)
              .fontColor(Color.White)
              .padding({
                left: 6,
                right: 6,
                top: 2,
                bottom: 2
              })
              .margin({
                right:6
              })
              .backgroundColor($r('app.color.color_main'))
              .borderColor(Color.Black)
              .borderRadius(4)
          })
        }.justifyContent(FlexAlign.Start)
        .width('100%')

        if (this.viewModel.initSource?.item.Type == BaseItemKind.Episode){
          Row() {
            //标题
            Text('选集')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Start)
            Blank().layoutWeight(1)
            Image($r('app.media.ic_right')).width(24).height(24).padding(8)
          }.alignItems(VerticalAlign.Bottom)

          List({
            scroller: this.uiState.scroller,
          }) {
            ForEach(this.uiState.playList, (item: QueueItem) => {
              ListItem() {
                Column({ space: 2 }) {
                  Text(`第 ${item.playIndex} 集`)
                    .fontSize(14)
                    .fontColor(this.uiState.currentPlayId == item.id ? $r('app.color.color_main') : Color.Black)
                  Text(item.name)
                    .width('100%')
                    .fontSize(14)
                    .fontColor(this.uiState.currentPlayId == item.id ? $r('app.color.color_main') : Color.Black)
                    .maxLines(1)
                    .textOverflow({
                      overflow: TextOverflow.Ellipsis
                    })
                    .ellipsisMode(EllipsisMode.END)
                }
                .width(140)
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Center)
                .padding(12)
                .backgroundColor('#eeeeee')
                .borderRadius(8)
                .margin({ right: 10 })
              }
            })
          }.width('100%')
          .height(60)
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
        }

      }.width('100%')
      .layoutWeight(1)
      .padding(16)
      .visibility(this.screenIsFull ? Visibility.None : Visibility.Visible)

      //   StandardGSYVideoPlayer({
      //     videoModel: this.videoModel,
      //     onInit: async () => {
      //       // this.viewModel.setupPlayer()
      //       //开启自动画中画
      //       if (canIUse('SystemCapability.Window.SessionManager')) {
      //         if (!this.pipController) {
      //           await this.createPipController();
      //           this.pipController!.setAutoStartEnabled(true);
      //         }
      //       }
      //     },
      //   }).width('100%')
      //     .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}