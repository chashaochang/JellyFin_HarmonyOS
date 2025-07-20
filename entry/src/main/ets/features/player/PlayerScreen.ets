import { HMRouter, HMRouterMgr } from "@hadss/hmrouter"

import { PlayOptions } from "../../player/interaction/PlayOptions"
import { PlayerException } from "../../player/PlayerException"
import { PlayerViewModel } from "./PlayerViewModel"
import { AppStorageV2, display, window } from "@kit.ArkUI"
import { Constants } from "../../utils/Constants"
import { common } from "@kit.AbilityKit"
import { PlayerView } from "./PlayerView"
import { emitter } from "@kit.BasicServicesKit"
import { PlayerUIState } from "./PlayerUIState"
import { QueueItem } from "../../entity/QueueItem"
import { BaseItemKind, MediaStream } from "sdk/src/main/ets/generated-client/models"
import { QualityOption } from "../../player/qualityoptions/QualityOption"
import { AVCastPicker, avSession } from "@kit.AVSessionKit"
import { SimilarItem } from "../../entity/SimilarItem"
import { MediaStreamUtil } from "../../utils/MediaStreamUtil"
import { PlayerMenus } from "../../player/ui/PlayerMenus"
import { OneMoreUtil } from "../../utils/OneMoreUtil"
import { AppUIState } from "../../entity/AppUIState"
import { PlayerLifecycle } from "../../router/lifecycles/PlayerLifecycle"
import { ToastUtil } from "../../utils/ToastUtil"

@HMRouter({
  pageUrl: '/Player',
  singleton: true,
  lifecycle: 'playerLifecycle',
})
@ComponentV2
export struct PlayerScreen {
  options: PlayOptions = HMRouterMgr.getCurrentParam() as PlayOptions
  @Provider() uiState: PlayerUIState = new PlayerUIState()
  @Provider() viewModel: PlayerViewModel = new PlayerViewModel(this.uiState)
  castController: avSession.AVCastController | undefined = undefined;
  backClickListener: () => void = () => {
    HMRouterMgr.pop()
  }
  @Local showEpisodeView: boolean = false
  @Local appUIState: AppUIState = AppStorageV2.connect(AppUIState, () => new AppUIState())!;
  @Local lifecycle: PlayerLifecycle = HMRouterMgr.getCurrentLifecycleOwner()?.getLifecycle() as PlayerLifecycle;
  playerInitHeight: number = 240

  @Monitor('lifecycle.options')
  onNewInstance() {
    this.options = this.lifecycle.options
    this.uiState = new PlayerUIState()
    this.viewModel = new PlayerViewModel(this.uiState)
    this.aboutToAppear()
  }

  @Monitor('viewModel.queueManager.currentMediaSourceOrNull')
  onMediaSourceChanged() {
    if (!this.viewModel.queueManager.currentMediaSourceOrNull) {
      return
    }
    let mediaSource = this.viewModel.queueManager.currentMediaSourceOrNull!
    if (MediaStreamUtil.isLandscape(mediaSource.selectedVideoStream) == false) {
      // For portrait videos, immediately enable fullscreen
      //playerFullscreenHelper.enableFullscreen()
    }
    // else if (appPreferences.exoPlayerStartLandscapeVideoInLandscape) {
    //   // Auto-switch to landscape for landscape videos if enabled
    //   requireActivity().requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
    // }

    // Update title and player menus
    this.viewModel.uiState.title = mediaSource.name
    if (OneMoreUtil.isPc()) {
      let windowStage = AppStorage.get<window.WindowStage>('playerWindowStage')
      if (canIUse('SystemCapability.Window.SessionManager')) {
        let title = "正在播放: " + mediaSource.name
        windowStage?.getMainWindowSync().setWindowTitle(title)
      }
    }
    this.viewModel.uiState.playerMenus?.onQueueItemChanged(mediaSource, this.viewModel.queueManager.hasNext())
  }

  async aboutToAppear(): Promise<void> {
    if (OneMoreUtil.isBigScreen()) {
      if (this.appUIState.orientation == display.Orientation.LANDSCAPE ||
        this.appUIState.orientation == display.Orientation.LANDSCAPE_INVERTED) {
        //如果现在横屏分栏展示,需要手动点击才能全屏
        OneMoreUtil.updateNavModifier(this.appUIState)
      }
    }
    if (OneMoreUtil.isNormalPhone()) {
      this.playerInitHeight = 240
    } else if (OneMoreUtil.isBigScreen()) {
      this.playerInitHeight = 480
    }
    this.viewModel.initAVSession()
    // let callback = async () => {
    //   let defaultDisplay = display.getDefaultDisplaySync()
    //   this.appUIState.isFullScreen = defaultDisplay.width > defaultDisplay.height
    // }
    // try {
    //   display.on("change", callback); // 监听屏幕状态改变
    // } catch (exception) {
    //   console.error('PlayerScreen', 'Failed to register callback. Code: ' + JSON.stringify(exception));
    // }
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
        ToastUtil.showToast(this.getUIContext(), '无法解析播放信息')
        break
      case PlayerException.NetworkFailure:
        ToastUtil.showToast(this.getUIContext(), '无法从服务器加载媒体信息')
        break
      case PlayerException.UnsupportedContent:
        ToastUtil.showToast(this.getUIContext(), '该媒体无法在本设备上播放')
        break
      default:
        break
    }
    // Create playback menus
    this.viewModel.uiState.playerMenus = new PlayerMenus() //(this, playerBinding, playerControlsBinding)
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
    if (this.appUIState.isFullScreen) {
      this.appUIState.isFullScreen = false
    } else {
      HMRouterMgr.pop()
    }
  }

  @Builder
  EpisodeView() {
    Column({ space: 10 }) {
      Row() {
        Text('选集').titleStyle()
        Blank().layoutWeight(1)
        Image($r('app.media.ic_close'))
          .width(40)
          .height(40)
          .onClick(() => {
            this.showEpisodeView = false
          })
      }

      List({ space: 10 }) {
        ForEach(this.viewModel.uiState.playList, (item: QueueItem, index) => {
          ListItem() {
            Column({ space: 2 }) {
              Text(`第 ${item.playIndex} 集`)
                .fontSize(14)
                .fontColor(this.uiState.currentPlayId == item.id ? $r('app.color.color_main') : Color.Black)
              Text(item.name == `第 ${item.playIndex} 集` ? '' : item.name)
                .width('100%')
                .fontSize(14)
                .fontColor(this.uiState.currentPlayId == item.id ? $r('app.color.color_main') : Color.Black)
                .maxLines(1)
                .textOverflow({
                  overflow: TextOverflow.Ellipsis
                })
                .ellipsisMode(EllipsisMode.END)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .padding(12)
            .backgroundColor('#eeeeee')
            .borderRadius(8)
          }.padding({
            left: index % 2 === 0 ? 0 : 4,
            right: index % 2 === 0 ? 4 : 0,
          }).onClick(() => {
            this.viewModel.changeEpisode(index)
          })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .lanes(2)
    }.width('100%')
    .height('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor(Color.White)
  }

  build() {
    Flex({ direction: OneMoreUtil.isPc() ? FlexDirection.Row : FlexDirection.Column }) {
      //播放器
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
            stopCast: () => {
              this.viewModel.stopCast()
            },
            onEpisodeChange: (index: number) => {
              this.viewModel.changeEpisode(index)
            }
          }).width('100%')
            .height(this.appUIState.isFullScreen || OneMoreUtil.isPc() ? '100%' : this.playerInitHeight)
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
              right: 24
            })
            .visibility(this.uiState.isCastPlaying ? Visibility.None : Visibility.Visible)
        }
        .height(56)
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .visibility(this.appUIState.isFullScreen || OneMoreUtil.isPc() ? Visibility.None : Visibility.Visible)
      }
      .width(OneMoreUtil.isPc() && !this.appUIState.isFullScreen ? '70%' : '100%')
      .height(OneMoreUtil.isPc() ? '100%' : undefined)
      .alignContent(Alignment.Top)

      //视频相关信息
      Stack() {
        Scroll() {
          Column({ space: 20 }) {
            //标题
            Text(this.viewModel.uiState.seriesName ?? this.viewModel.uiState.title)
              .titleStyle()

            Text(this.uiState.overview)
              .width('100%')
              .fontColor(Color.White)
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

            if (this.viewModel.mediaSourceOrNull?.item.Type == BaseItemKind.Episode) {
              Row() {
                //标题
                Text('选集')
                  .titleStyle()
                Blank().layoutWeight(1)
                Image($r('app.media.ic_right')).width(24).height(24).padding(8)
                  .onClick(() => {
                    this.showEpisodeView = true
                  })
              }.alignItems(VerticalAlign.Bottom).margin({ top: 10 })

              List({
                scroller: this.uiState.scroller,
              }) {
                ForEach(this.uiState.playList, (item: QueueItem, index) => {
                  ListItem() {
                    Column({ space: 2 }) {
                      Text(`第 ${item.playIndex} 集`)
                        .fontSize(14)
                        .fontColor(this.uiState.currentPlayId == item.id ? $r('app.color.color_main') : Color.Black)
                      Text(item.name == `第 ${item.playIndex} 集` ? '' : item.name)
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
                  }.onClick(() => {
                    this.viewModel.changeEpisode(index)
                  })
                })
              }.width('100%')
              .height(60)
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
            if (this.uiState.similarItems.length > 0) {
              Row() {
                //标题
                Text('更多类似的(暂时是个摆设)')
                  .titleStyle()
                Blank().layoutWeight(1)
              }.alignItems(VerticalAlign.Bottom).margin({ top: 10 })

              List({
                scroller: this.uiState.scroller,
              }) {
                ForEach(this.uiState.similarItems, (item: SimilarItem) => {
                  ListItem() {
                    if (OneMoreUtil.isPc()) {
                      Row({ space: 16 }) {
                        Image(item.image)
                          .width(90)
                          .height(120)
                          .borderRadius(8)
                        Column({ space: 8 }) {
                          Text(item.name)
                            .fontSize(14)
                            .width('100%')
                            .maxLines(1)
                            .textAlign(TextAlign.Start)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .ellipsisMode(EllipsisMode.END)
                            .fontColor(Color.White)
                          Text(item.desc)
                            .fontSize(12)
                            .fontColor(Color.White)
                          Text(item.overview)
                            .fontSize(12)
                            .fontColor(Color.White)
                            .width('100%')
                            .layoutWeight(1)
                            .maxLines(5)
                            .align(Alignment.TopStart)
                            .textOverflow({
                              overflow: TextOverflow.Ellipsis
                            })
                            .ellipsisMode(EllipsisMode.END)
                        }.layoutWeight(1)
                        .height('100%')
                        .alignItems(HorizontalAlign.Start)
                      }.width('100%')
                      .height(120)
                      .margin({ top: 10 })
                    } else {
                      Column({ space: 4 }) {
                        Image(item.image)
                          .width(120)
                          .height(160)
                          .borderRadius(8)
                        Text(item.name)
                          .fontSize(14)
                          .width('100%')
                          .maxLines(1)
                          .textAlign(TextAlign.Center)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .ellipsisMode(EllipsisMode.END)
                          .fontColor(Color.White)
                        Text(item.desc)
                          .fontSize(12)
                          .fontColor(Color.Gray)
                      }
                      .width(120)
                      .margin({ right: 10 })
                    }
                  }.onClick(() => {
                    // let options: PlayOptions = new PlayOptions(Array.of(item.id))
                    // options.startPositionTicks = item.runTimeTicks ?? 0
                    // HMRouterMgr.replace({ pageUrl: '/Player', param: options })
                  })
                })
              }.width('100%')
              .listDirection(OneMoreUtil.isPc() ? Axis.Vertical : Axis.Horizontal)
              .scrollBar(BarState.Off)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
          .width('100%')
          .padding(16)
          .visibility(this.appUIState.isFullScreen ? Visibility.None : Visibility.Visible)
        }.width('100%')
        .height('100%')
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)

        //选集
        if (this.showEpisodeView) {
          this.EpisodeView()
        }
      }.width('100%')
      .height(OneMoreUtil.isPc() ? '100%' : undefined)
      .layoutWeight(1)
      .backgroundColor('#111111')
    }
    .width('100%')
    .height('100%')
  }
}

@Extend(Text)
function titleStyle() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .textAlign(TextAlign.Start)
  .fontColor(Color.White)
}

