import { HMRouter, HMRouterMgr } from "@hadss/hmrouter"

import { ToastUtil } from "@pura/harmony-utils"
import { PlayOptions } from "../../player/interaction/PlayOptions"
import { PlayerException } from "../../player/PlayerException"
import { PlayerViewModel } from "./PlayerViewModel"
import { display } from "@kit.ArkUI"
import { Constants } from "../../utils/Constants"
import { common } from "@kit.AbilityKit"
import { PlayerView } from "./PlayerView"
import { emitter } from "@kit.BasicServicesKit"
import { PlayerUIState } from "./PlayerUIState"
import { QueueItem } from "../../entity/QueueItem"
import { BaseItemKind, MediaStream } from "sdk/src/main/ets/generated-client/models"
import { QualityOption } from "../../player/qualityoptions/QualityOption"
import { AVCastPicker, AVCastPickerState, avSession } from "@kit.AVSessionKit"
import avSessionManager from "../../utils/AVSessionManager"

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
  castController: avSession.AVCastController | undefined = undefined;

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
            },
            onAudioTrackSelected: (stream: MediaStream) => {
              this.viewModel.trackSelectionHelper.selectAudioTrack(stream)
            },
            onSubtitleSelected: (stream: MediaStream) => {
              this.viewModel.trackSelectionHelper.selectSubtitleTrack(stream)
            },
            onQualitySelected: (option: QualityOption) => {
              this.viewModel.changeBitrate(option.bitrate)
            },
            stopCast:()=>{
              this.viewModel.stopCast()
            }
          }).height(this.screenIsFull ? '100%' : 240)
        }
        Row() {
          Image($r('app.media.ic_back'))
            .width(44)
            .height(44)
            .padding(12)
            .onClick(() => {
              this.onBackPress()
            })
          Blank().layoutWeight(1)
          AVCastPicker({
            normalColor: Color.White,
          })
            .width('24vp')
            .height('24vp')
            .margin({
              right:24
            })
            .visibility(this.uiState.isCastPlaying ? Visibility.None : Visibility.Visible)
        }
        .height(56)
        .width('100%')
        .justifyContent(FlexAlign.Start)
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
                right: 6
              })
              .backgroundColor($r('app.color.color_main'))
              .borderColor(Color.Black)
              .borderRadius(4)
          })
        }.justifyContent(FlexAlign.Start)
        .width('100%')

        if (this.viewModel.initSource?.item.Type == BaseItemKind.Episode) {
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

    }
    .width('100%')
    .height('100%')
  }

}