import {
  IjkMediaPlayer,
  InterruptEvent,
  InterruptHintType,
  LogUtils,
  OnBufferingUpdateListener,
  OnCompletionListener,
  OnErrorListener,
  OnInfoListener,
  OnPreparedListener,
  OnSeekCompleteListener,
  OnTimedTextListener,
  OnVideoSizeChangedListener
} from "@ohos/ijkplayer";
import { PlayerStatus, PlayStatus } from "./PlayStatus";
import prompt from "@ohos.promptAction";
import { BusinessError, emitter, settings } from "@kit.BasicServicesKit";
import { Constants } from "../../utils/Constants";
import { PlayerUIState } from "./PlayerUIState";
import { SmartDialog } from "ohos_smart_dialog";
import { SubtitleItem } from "../../utils/SubtitleManager";
import { audio } from "@kit.AudioKit";
import { window, PiPWindow, AppStorageV2, display } from "@kit.ArkUI";
import avSessionManager from "../../utils/AVSessionManager";
import { AVCastPicker, avSession } from "@kit.AVSessionKit";
import { BaseItemKind, MediaStream } from "sdk/src/main/ets/generated-client/models";
import { QualityOption } from "../../player/qualityoptions/QualityOption";
import { common } from "@kit.AbilityKit";
import { QueueItem } from "../../entity/QueueItem";
import { AppUIState } from "../../entity/AppUIState";
import { OneMoreUtil } from "../../utils/OneMoreUtil";

let uiTime: number = 0;
let uiLockTime: number = 0;
let touchStartX: number = 0;
let touchStartY: number = 0;
let changeWidth: number = 0;
let changeHeight: number = 0;
let windowClass: window.Window | undefined = undefined;

@ComponentV2
export struct PlayerView {
  @Param @Require videoUrl: string

  @Monitor('videoUrl')
  onUrlChange() {
    this.stop()
    this.startPlayOrResumePlay()
  }

  @Param @Require onNext: () => void
  @Param @Require onAudioTrackSelected: (stream: MediaStream) => void
  @Param @Require onSubtitleSelected: (stream: MediaStream) => void
  @Param @Require onQualitySelected: (option: QualityOption) => void
  @Param @Require onEpisodeChange: (index: number) => void
  @Param @Require stopCast: () => void
  @Local progressValue: number = 0;
  @Local currentTime: string = "00:00";
  @Local totalTime: string = "00:00";
  @Local loadingVisible: Visibility = Visibility.None;
  @Local replayVisible: Visibility = Visibility.None;
  @Local slideEnable: boolean = false;
  @Local aspRatio: number = 0.5;
  @Local mContext: object | undefined = undefined;
  @Local mFirst: boolean = true;
  @Local fullShowLock: boolean = false;
  @Local lock: boolean = false;

  @Monitor('lock')
  onLockChanged() {
    if (this.lock) {
      if (OneMoreUtil.isNormalPhone()) {
        windowClass?.setPreferredOrientation(window.Orientation.LANDSCAPE);
      } else if (OneMoreUtil.isBigScreen()) {
        switch (this.appUIState.orientation){
          case display.Orientation.PORTRAIT:
            windowClass?.setPreferredOrientation(window.Orientation.PORTRAIT);
            break
          case display.Orientation.LANDSCAPE:
            windowClass?.setPreferredOrientation(window.Orientation.LANDSCAPE);
            break
          case display.Orientation.PORTRAIT_INVERTED:
            windowClass?.setPreferredOrientation(window.Orientation.PORTRAIT_INVERTED);
            break
          case display.Orientation.LANDSCAPE_INVERTED:
            windowClass?.setPreferredOrientation(window.Orientation.LANDSCAPE_INVERTED);
            break
        }
      }
    } else {
      if(OneMoreUtil.isBigScreen()){
        windowClass?.setPreferredOrientation(window.Orientation.AUTO_ROTATION)
      }
      this.onScreenChanged()
    }
  }

  @Local mDestroyPage: boolean = false;
  @Local playSpeed: string = '1f';
  @Local oldSeconds: number = 0;
  @Local isCurrentTime: boolean = false;
  @Local videoWidth: string = '100%';
  @Local initAspectRatio: number = 1920 / 1080;
  @Local videoAspectRatio: number = this.initAspectRatio;
  private last: number = 0;
  @Local videoParentAspectRatio: number = this.initAspectRatio;
  private mIjkMediaPlayer = IjkMediaPlayer.getInstance();
  @Local PROGRESS_MAX_VALUE: number = 100;
  @Local updateProgressTimer: number = 0;
  private updateSubtitleTimer: number = -1;
  @Local curIndex: number = 0;
  @Local recordProgressVisible: Visibility = Visibility.None;
  @Local screenshotProgressVisible: Visibility = Visibility.None;
  @Local recordSaveFilePath: string = "";
  // 是否正在加载手势滑动禁止
  private isLoadNotSeek: boolean = false;
  // 是否拖动进度条
  private isSeek: boolean = false;
  // 当前音量 [0-20]
  @Local mCurrentVolumeValue: number = 0;
  // 系统最大音量
  @Local mMaxVolumeValue: number = 20;
  // 是否显示音量数值的布局
  @Local showVolumeUi: boolean = false;
  // 是否显示亮度数值的布局
  @Local showBrightnessUi: boolean = false;
  // 当前亮度 [0-255]
  @Local mCurrentBrightness: number = 10;
  // 当前拖拽进度的方向资源
  @Local mSeekDirectionRes: Resource = $r('app.media.video_forward_icon');
  // 当前进度
  @Local mSeekTimePosition: number = 0;
  // 拖拽的时间
  @Local mSeekCurrentTime: string = this.currentTime;
  // 是否显示横向滑动的进度布局
  @Local showSeekProgressUi: boolean = false;
  @Local showControls: boolean = true;
  private panOptionBrightAndVolume: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Vertical });
  private panOptionSeek: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Horizontal });
  private isVerticalDrag: boolean = false;
  private isHorizontalDrag: boolean = false;
  private mAudioManager: audio.AudioManager | null = null;
  sec: number = 3;
  pipController?: PiPWindow.PiPController;
  xComponentController: XComponentController = new XComponentController()
  @Local hintMsgVisibility: boolean = false;
  @Local appUIState: AppUIState = AppStorageV2.connect(AppUIState, () => new AppUIState())!;

  @Monitor('appUIState.isFullScreen')
  onScreenChanged() {
    if (this.appUIState.isFullScreen) {
      windowClass?.setWindowLayoutFullScreen(true)
      windowClass?.setWindowSystemBarEnable([])
      if (OneMoreUtil.isNormalPhone()) {
        if (canIUse('SystemCapability.Window.SessionManager')) {
          windowClass?.setPreferredOrientation(window.Orientation.USER_ROTATION_LANDSCAPE);
        }
      } else if (OneMoreUtil.isBigScreen()) {

      }
    } else {
      windowClass?.setWindowLayoutFullScreen(false)
      windowClass?.setWindowSystemBarEnable(['status', 'navigation'])
      if (OneMoreUtil.isNormalPhone()) {
        SmartDialog.dismiss()
        if (canIUse('SystemCapability.Window.SessionManager')) {
          windowClass?.setPreferredOrientation(window.Orientation.USER_ROTATION_PORTRAIT);
        }
      } else if (OneMoreUtil.isBigScreen()) {

      }
    }
  }

  @Consumer() uiState: PlayerUIState = new PlayerUIState()

  @Monitor('uiState')
  onNewInstance() {
    this.stop()
  }

  @Monitor('uiState.subtitles')
  onSubtitleChanged() {
    if (this.uiState.subtitles.length > 0) {
      this.startSubTitle()
    } else {
      this.stopSubTitle()
    }
  }

  @Monitor('uiState.playerStatus')
  onPlayerStateChanged() {
    this.sendAVSessionState(this.uiState.playerStatus)
  }

  @Monitor('uiState.isCastPlaying')
  onCastChanged() {
    if (this.uiState.isCastPlaying) {
      this.appUIState.isFullScreen = false
    }
  }

  aboutToAppear() {
    try {
      let promise = window.getLastWindow(getContext(this));
      promise.then((data) => {
        windowClass = data;
      }).catch((error: BusinessError) => {
        LogUtils.getInstance().LOGI('Failed to obtain the top window. Cause: ' + JSON.stringify(error));
      })
    } catch (exception) {
      LogUtils.getInstance().LOGI('Failed to obtain the top window. Cause: ' + JSON.stringify(exception));
    }
    let groupid = audio.DEFAULT_VOLUME_GROUP_ID;
    this.mAudioManager = audio.getAudioManager();
    let volumeManager: audio.AudioVolumeManager = this.mAudioManager.getVolumeManager();
    let audioVolumeGroupManager = volumeManager.getVolumeGroupManagerSync(groupid);
    this.mMaxVolumeValue = audioVolumeGroupManager.getMaxVolumeSync(audio.AudioVolumeType.MEDIA);
    this.mCurrentVolumeValue = audioVolumeGroupManager.getVolumeSync(audio.AudioVolumeType.MEDIA);
    if (canIUse('SystemCapability.Applications.Settings.Core')) {
      this.mCurrentBrightness =
        Number(settings.getValueSync(getContext(this), settings.display.SCREEN_BRIGHTNESS_STATUS, '10'));
    }
    emitter.on(Constants.PLAYER_EVENT, async (data) => {
      if (data.data && data.data['eventName']) {
        let name = data.data['eventName'] as string
        switch (name) {
          case 'onPageShow':
            if (this.uiState.isCastPlaying) {
              return
            }
            this.onLockChanged()
            if (this.mContext && !this.mFirst) {
              this.startPlayOrResumePlay();
            }
            break
          case 'onPageHide':
            this.pause()
            break
          case 'Pause':
            this.pause()
            break
          case 'Play':
          case 'Resume':
            this.startPlayOrResumePlay()
            break
          case 'Stop':
            this.stop()
            break
          case 'Destroy':
            this.stop()
            break
          case 'Seek':
            let ms = data.data['args'] as number | undefined
            if (ms) {
              this.seekTo(ms + '')
            }
            break
          case 'setVolume':
            let volume = data.data['args'] as number | undefined
            if (volume) {
              if (this.mAudioManager) {
                this.mAudioManager.setVolume(audio.AudioVolumeType.MEDIA, volume, (err: BusinessError) => {
                  if (err) {
                    LogUtils.getInstance().LOGI(`Failed to set the volume. ${err}`);
                    return;
                  }
                })
              }
            }
            break
          case 'Speed':
            let speed = data.data['args'] as string | undefined
            if (speed) {
              this.playSpeed = speed
            }
            break
        }
      }
    })

    LogUtils.getInstance().LOGI("aboutToAppear");
    let event: Callback<InterruptEvent> = (event) => {
      LogUtils.getInstance().LOGI(`event: ${JSON.stringify(event)}`);
      if (event.hintType === InterruptHintType.INTERRUPT_HINT_PAUSE) {
        this.pause();
      } else if (event.hintType === InterruptHintType.INTERRUPT_HINT_RESUME) {
        this.startPlayOrResumePlay();
      } else if (event.hintType === InterruptHintType.INTERRUPT_HINT_STOP) {
        this.stop();
      }
    }
    this.mIjkMediaPlayer.on('audioInterrupt', event);

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
    this.stopSubTitle()
    emitter.off(Constants.PLAYER_EVENT.eventId)
    LogUtils.getInstance().LOGI("aboutToDisappear");
    this.mDestroyPage = true;
    this.mIjkMediaPlayer.setScreenOnWhilePlaying(false);
    // this.stopRecord(false);
    if (this.uiState.CONTROL_PlayStatus != PlayStatus.INIT) {
      this.stop();
    }
    this.mIjkMediaPlayer.off('audioInterrupt');
  }

  @Builder
  dialogEpisode(_this: PlayerView) {
    Column({ space: 10 }) {
      List({ space: 8, initialIndex: _this.uiState.playList.findIndex(e => e.id == _this.uiState.currentPlayId) }) {
        ForEach(_this.uiState.playList, (item: QueueItem, index) => {
          ListItem() {
            Column() {
              Text(`第 ${item.playIndex} 集  ` + (item.name == `第 ${item.playIndex} 集` ? '' : item.name))
                .fontColor(_this.uiState.currentPlayId == item.id ? $r('app.color.color_main') : Color.White)
                .fontSize(14)
                .maxLines(1)
                .ellipsisMode(EllipsisMode.END)
                .textOverflow({
                  overflow: TextOverflow.Ellipsis
                })
            }
            .width('100%')
            .height(40)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
            .padding(12)
            .borderWidth(1)
            .borderColor(_this.uiState.currentPlayId == item.id ? $r('app.color.color_main') : Color.Gray)
            .borderRadius(8)
            .onClick(() => {
              _this.onEpisodeChange(index)
              SmartDialog.dismiss()
            })
          }
        })
      }.width('100%').height('100%')
    }.height('100%').padding(20).backgroundColor('rgba(0,0,0,0.8)')
    .width(300)
  }

  @Builder
  dialogSpeed(_this: PlayerView) {
    Column({ space: 10 }) {
      Stack() {
        Text('3.0X')
          .fontColor(_this.playSpeed === '3f' ? $r('app.color.color_main') : Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }.menuItemStyle().onClick(() => {
        _this.playSpeed = '3f'
        _this.mIjkMediaPlayer.setSpeed(_this.playSpeed);
        SmartDialog.dismiss()
      })

      Stack() {
        Text('2.0X')
          .fontColor(_this.playSpeed === '2f' ? $r('app.color.color_main') : Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }.menuItemStyle().onClick(() => {
        _this.playSpeed = '2f'
        _this.mIjkMediaPlayer.setSpeed(_this.playSpeed);
        SmartDialog.dismiss()
      })

      Stack() {
        Text('1.5X')
          .fontColor(_this.playSpeed === '1.5f' ? $r('app.color.color_main') : Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }.menuItemStyle().onClick(() => {
        _this.playSpeed = '1.5f'
        _this.mIjkMediaPlayer.setSpeed(_this.playSpeed);
        SmartDialog.dismiss()
      })

      Stack() {
        Text('1.25X')
          .fontColor(_this.playSpeed === '1.25f' ? $r('app.color.color_main') : Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }.menuItemStyle().onClick(() => {
        _this.playSpeed = '1.25f'
        _this.mIjkMediaPlayer.setSpeed(_this.playSpeed);
        SmartDialog.dismiss()
      })

      Stack() {
        Text('1.0X')
          .fontColor(_this.playSpeed === '1f' ? $r('app.color.color_main') : Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }.menuItemStyle().onClick(() => {
        _this.playSpeed = '1f'
        _this.mIjkMediaPlayer.setSpeed(_this.playSpeed);
        SmartDialog.dismiss()
      })

      Stack() {
        Text('0.75X')
          .fontColor(_this.playSpeed === '0.75f' ? $r('app.color.color_main') : Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
      }.menuItemStyle().onClick(() => {
        _this.playSpeed = '0.75f'
        _this.mIjkMediaPlayer.setSpeed(_this.playSpeed);
        SmartDialog.dismiss()
      })
    }.height('100%').padding(10).backgroundColor('rgba(0,0,0,0.8)')
    .width(200)
  }

  @Builder
  audioMenu() {
    Menu() {
      ForEach(this.uiState.audioStreams, (item: MediaStream) => {
        MenuItem({
          content: item.DisplayTitle
        }).selectIcon(true)
          .selected(this.uiState.selectedAudioStream == item)
          .onClick(() => {
            this.onAudioTrackSelected(item)
          })
      })
    }
  }

  @Builder
  subtitleMenu() {
    Menu() {
      ForEach(this.uiState.subtitleStreams, (item: MediaStream) => {
        MenuItem({
          content: item.DisplayTitle
        }).selectIcon(true)
          .selected(this.uiState.selectedSubtitleStream == item)
          .onClick(() => {
            this.onSubtitleSelected(item)
          })
      })
    }
  }

  @Builder
  qualityMenu() {
    Menu() {
      ForEach(this.uiState.qualityOptions, (option: QualityOption) => {
        MenuItem({
          content: `${option.maxHeight}p - ${this.formatBitrate(option.bitrate)}`
        }).selectIcon(true)
          .selected(this.uiState.selectedBitrate == option.bitrate)
          .onClick(() => {
            this.onQualitySelected(option)
          })
      })
    }
  }

  @Builder
  topControlView() {
    Row() {
      if (this.appUIState.isFullScreen) {
        Image($r('app.media.ic_back'))
          .width(44)
          .height(44)
          .padding(12)
          .margin({
            left: 16
          })
          .onClick(() => {
            this.appUIState.isFullScreen = false
          })
        Text(this.uiState.title)
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 4 })
          .layoutWeight(1)
        AVCastPicker({
          normalColor: Color.White,
        })
          .width('24vp')
          .height('24vp')
          .margin({
            right: 32
          })
          .visibility(this.uiState.isCastPlaying ? Visibility.None : Visibility.Visible)
      }
    }.height(56).width('100%').justifyContent(FlexAlign.Start)
  }

  @Builder
  bottomControlView() {
    if (this.appUIState.isFullScreen) {
      Column() {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
          Text(this.currentTime)
            .fontColor(Color.White)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .margin({
              left: 16,
              right: 8
            })
          Slider({
            value: this.progressValue,
            min: 0,
            max: this.PROGRESS_MAX_VALUE,
            step: 1,
            style: SliderStyle.OutSet
          })
            .layoutWeight(1)
            .blockColor(Color.White)
            .trackColor(Color.Gray)
            .selectedColor($r('app.color.color_main'))
            .showTips(true)
            .enabled(this.slideEnable)
            .onChange((value: number, mode: SliderChangeMode) => {
              if (mode == 2) {
                this.isSeek = true;
                this.mDestroyPage = false;
                this.showLoadIng();
                LogUtils.getInstance().LOGI("slider-->seekValue start:" + value);
                let seekValue = value * (this.mIjkMediaPlayer.getDuration() / 100);
                this.seekTo(seekValue + "");
                this.setProgress()
                LogUtils.getInstance().LOGI("slider-->seekValue end:" + seekValue);
                this.isSeek = false;
              }
            })
          Text(this.totalTime).fontColor(Color.White).fontSize(13).fontWeight(FontWeight.Bold).margin({
            left: 8,
            right: 16
          })
        }.width('100%')

        Row() {
          Image(this.uiState.CONTROL_PlayStatus == PlayStatus.PLAY ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(44)
            .height(44)
            .padding(12)
            .onClick(() => {
              if (this.uiState.CONTROL_PlayStatus == PlayStatus.PLAY) {
                this.pause();
              } else {
                this.startPlayOrResumePlay();
              }
            })
          if (this.uiState.playerMenus?.hasNext) {
            Image($r('app.media.ic_next'))
              .width(44)
              .height(44)
              .padding(12)
              .onClick(() => {
                this.onNext()
              })
          }
          Button() {
            Image($r("app.media.ic_audio"))
              .width(44)
              .height(44)
              .padding(12)
          }.backgroundColor(Color.Transparent).bindMenu(this.audioMenu())

          Button() {
            Image($r("app.media.ic_subtitle"))
              .width(44)
              .height(44)
              .padding(12)
          }.backgroundColor(Color.Transparent).bindMenu(this.subtitleMenu())

          Button() {
            Image($r("app.media.ic_info"))
              .width(44)
              .height(44)
              .padding(12)
          }.backgroundColor(Color.Transparent)
          .onClick(() => {
            if (this.uiState.playerMenus) {
              this.uiState.playerMenus.isShowPlayBackInfo = true
            }
          })

          Blank().layoutWeight(1)
          if (this.uiState.mediaType == BaseItemKind.Episode) {
            Text('选集')
              .fontColor(Color.White)
              .fontSize(16)
              .height('100%')
              .padding({
                left: 16, right: 16
              })
              .onClick(() => {
                SmartDialog.show({
                  builder: this.dialogEpisode,
                  builderArgs: this,
                  alignment: Alignment.End,
                })
              })
          }
          Button() {
            Text('质量')
              .fontColor(Color.White)
              .fontSize(16)
              .height('100%')
              .padding({
                left: 16, right: 16
              })
          }.backgroundColor(Color.Transparent).bindMenu(this.qualityMenu())

          Text('倍速')
            .fontColor(Color.White)
            .fontSize(16)
            .height('100%')
            .padding({
              left: 16, right: 16
            })
            .onClick(() => {
              SmartDialog.show({
                builder: this.dialogSpeed,
                builderArgs: this,
                alignment: Alignment.End,
              })
            })
        }.height(44).padding({
          left: 8,
          right: 8
        })
      }.padding({
        left: 16,
        right: 16
      })
    } else {
      Row() {
        Image(this.uiState.CONTROL_PlayStatus == PlayStatus.PLAY ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
          .width(44)
          .height(44)
          .padding(12)
          .onClick(() => {
            if (this.uiState.CONTROL_PlayStatus == PlayStatus.PLAY) {
              this.pause();
            } else {
              this.startPlayOrResumePlay();
            }
          })
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
          Text(this.currentTime).fontColor(Color.White).fontSize(13).fontWeight(FontWeight.Bold)
          Slider({
            value: this.progressValue,
            min: 0,
            max: this.PROGRESS_MAX_VALUE,
            step: 1,
            style: SliderStyle.OutSet
          })
            .layoutWeight(1)
            .margin(4)
            .blockColor(Color.White)
            .trackColor(Color.Gray)
            .selectedColor($r('app.color.color_main'))
            .showSteps(true)
            .showTips(true)
            .enabled(this.slideEnable)
            .onChange((value: number, mode: SliderChangeMode) => {
              if (mode == 2) {
                this.isSeek = true;
                this.mDestroyPage = false;
                this.showLoadIng();
                LogUtils.getInstance().LOGI("slider-->seekValue start:" + value);
                let seekValue = value * (this.mIjkMediaPlayer.getDuration() / 100);
                this.seekTo(seekValue + "");
                this.setProgress()
                LogUtils.getInstance().LOGI("slider-->seekValue end:" + seekValue);
                this.isSeek = false;
              }
            })
          Text(this.totalTime).fontColor(Color.White).fontSize(13).fontWeight(FontWeight.Bold)
        }.layoutWeight(1)

        // Image($r('app.media.ic_pip')).width(48).height(48).padding(12).onClick(() => {
        //   this.startPip();
        //   this.hintMsgVisibility = true;
        // })
        Image($r('app.media.ic_full')).width(48).height(48).padding(12).onClick(() => {
          this.appUIState.isFullScreen = true
        })
      }.height(52).width('100%')
    }
  }

  @Builder
  VolumeUi() {
    Column() {
      Progress({
        value: Number((this.mCurrentVolumeValue / this.mMaxVolumeValue * 100).toFixed(0)),
        total: 100,
        type: ProgressType.Linear
      })
        .style({ strokeWidth: 10, enableSmoothEffect: false })
        .width(100)
        .rotate({ angle: -90 })
        .margin({ top: 20, left: -20 })
        .alignSelf(ItemAlign.Center)
        .backgroundColor(Color.White);

      Image($r('app.media.video_volume_icon'))
        .objectFit(ImageFit.Auto)
        .margin({ top: 50, left: -15 })
        .width(30)
        .height(30)
        .alignSelf(ItemAlign.Center)
        .borderStyle(BorderStyle.Dashed)
    }.visibility(this.showVolumeUi ? Visibility.Visible : Visibility.Hidden)
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  BrightnessUi() {
    Column() {
      Image($r('app.media.video_brightness_6_white_36dp'))
        .objectFit(ImageFit.Auto)
        .width(30)
        .height(30)
        .border({ width: 0 })
        .alignSelf(ItemAlign.Center)

      Text((this.mCurrentBrightness / 255 * 100).toFixed(0) + '%')
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(80)
    }.visibility(this.showBrightnessUi ? Visibility.Visible : Visibility.Hidden)
    .width(80)
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  SeekProgressUi() {
    Column() {
      Image(this.mSeekDirectionRes)
        .objectFit(ImageFit.Auto)
        .width(30)
        .height(30)
        .border({ width: 0 })
        .margin({ top: 10 })
        .alignSelf(ItemAlign.Center)

      Row() {
        Text(this.mSeekCurrentTime)
          .fontColor(Color.Blue)
          .textAlign(TextAlign.Center)

        Text('/')
          .textAlign(TextAlign.Center)

        Text(this.totalTime)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }.margin({ top: 10 })

      Progress({
        value: this.mSeekTimePosition,
        total: 100,
        type: ProgressType.Linear
      })
        .style({ strokeWidth: 5, enableSmoothEffect: false })
        .padding({ left: 10, right: 10 })
        .margin({ top: 10, bottom: 10 })
        .backgroundColor(Color.White);
    }
    .visibility(this.showSeekProgressUi ? Visibility.Visible : Visibility.Hidden)
    .width(200)
    .backgroundColor('#55bcbcbc')
    .alignItems(HorizontalAlign.Center)
    .alignSelf(ItemAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text('当前视频正在画中画播放')
        .fontColor(Color.Gray)
        .margin({ bottom: 30 })
        .visibility(this.hintMsgVisibility ? Visibility.Visible : Visibility.Hidden)
      Column() {
        XComponent({
          id: 'xcomponentId',
          type: XComponentType.SURFACE,
          libraryname: 'ijkplayer_napi',
          controller: this.xComponentController
        })
          .onLoad(async (event?: object) => {
            if (!!event) {
              this.initDelayPlay(event);
              //开启自动画中画
              if (canIUse('SystemCapability.Window.SessionManager')) {
                if (!this.pipController) {
                  await this.createPipController();
                  // this.pipController!.setAutoStartEnabled(true)
                }
              }
            }
          })
          .onDestroy(() => {
          })
          .width('100%')
          .width(this.videoWidth)
          .aspectRatio(this.videoAspectRatio)
          .id('xcomponentId')
      }.aspectRatio(this.videoAspectRatio)

      //字幕
      if (this.uiState.subtitles.length > 0) {
        Stack() {
          Text(this.uiState.currentSubtitle)
            .fontSize(this.appUIState.isFullScreen ? 21 : 13)
            .fontColor(Color.White)
            .width('100%')
            .padding(20)
            .textAlign(TextAlign.Center)
            .textShadow({
              radius: vp2px(2),
            })
            .hitTestBehavior(HitTestMode.None)
        }.height('100%').alignContent(Alignment.Bottom)
      }

      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        this.VolumeUi()
        this.SeekProgressUi()
        this.BrightnessUi()
      }.width('100%')
      .height('100%')


      Column() {
        //顶部菜单
        this.topControlView()
        Blank().layoutWeight(1)
        //底部菜单
        this.bottomControlView()
      }.height('100%')
      .visibility(this.showControls ? Visibility.Visible : Visibility.Hidden)

      if (this.appUIState.isFullScreen && this.fullShowLock) {
        Stack() {
          Image(this.lock ? $r('app.media.lock') : $r('app.media.unlock'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .margin({ right: 60 })
            .onClick(() => {
              this.lock = !this.lock;
              if (this.lock) {
                this.showControls = false
              }
            })
        }.width('100%')
        .alignContent(Alignment.End)
      }

      Image($r('app.media.icon_replay'))
        .objectFit(ImageFit.Auto)
        .width('120px')
        .height('120px')
        .visibility(this.replayVisible)
        .border({ width: 0 })
        .borderStyle(BorderStyle.Dashed)
        .onClick(() => {
          this.startPlayOrResumePlay();
        })
      Image($r('app.media.icon_load'))
        .objectFit(ImageFit.Auto)
        .width('120px')
        .height('120px')
        .visibility(this.loadingVisible)
        .border({ width: 0 })
        .borderStyle(BorderStyle.Dashed)

      Text(this.uiState.playerMenus?.playBackInfo)
        .backgroundColor($r('sys.color.mask_primary'))
        .borderRadius(16)
        .fontColor(Color.White)
        .fontSize(12)
        .position({
          x: 0, y: 0
        })
        .padding(16)
        .visibility(this.uiState.playerMenus?.isShowPlayBackInfo ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          if (this.uiState.playerMenus) {
            this.uiState.playerMenus.isShowPlayBackInfo = false
          }
        })
        .margin({
          top: 48,
          bottom: 96,
          left: 12,
          right: 12
        })
      Stack() {
        Button('退出投屏')
          .onClick(() => {
            this.stopCast()
          })
      }.width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .visibility(this.uiState.isCastPlaying ? Visibility.Visible : Visibility.Hidden)

      //长按三倍速提示
      Stack({ alignContent: Alignment.Top }) {
        Row() {
          Image($r('app.media.ic_speed')).height(20)
          Text('正在倍速播放')
            .fontSize(14)
            .fontColor(Color.White)
        }
        .margin({
          top: 20
        })
        .padding(4)
        .backgroundColor(Color.Black)
        .borderRadius(4)
        .opacity(0.4)
      }
      .width('100%')
      .height('100%')
      .visibility(this.uiState.isFastSpeed ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
    .backgroundColor($r('sys.color.black'))
    .clip(true)
    .gesture(GestureGroup(GestureMode.Parallel,
      TapGesture().onAction((event: GestureEvent | undefined) => {
        if (event) {
          if (this.lock) {
            this.timeLockCountdown();
            return;
          }
          if (this.loadingVisible == Visibility.Visible) {
            return;
          }
          if (!this.showControls) {
            this.timeCountdown();
          }
          if (event && event.fingerList && event.fingerList[0]) {
            LogUtils.getInstance().LOGI('TapGesture event.onActionStart start x: ' + event.fingerList[0].localX +
              " ---event.onActionStart start y: " + event.fingerList[0].localY);
          }
        }
      }),
      // 绑定声音屏幕亮度拖动手势
      PanGesture(this.panOptionBrightAndVolume)
        .onActionStart((event: GestureEvent | undefined) => {
          LogUtils.getInstance().LOGI('Vertical Pan Start');
          if (this.lock) {
            return;
          }
          if (this.isHorizontalDrag) {
            return;
          }
          if (event && event.fingerList && event.fingerList[0]) {
            touchStartX = event.fingerList[0].localX;
            touchStartY = event.fingerList[0].localY;
            LogUtils.getInstance().LOGI('VerticalPanBrightAndVolume event.onActionStart start x: ' + touchStartX +
              ' event.onActionStart start y: ' + touchStartY);
          }
        })
        .onActionUpdate((event: GestureEvent | undefined) => {
          if (this.lock) {
            return;
          }
          if (this.isHorizontalDrag) {
            return;
          }
          this.isVerticalDrag = true;
          if (event && event.fingerList && event.fingerList[0]) {
            let touchY = event.fingerList[0].localY;
            let deltaY = touchY - touchStartY;

            // 移动距离占播放器高度的比例(deltaY取反是因为值的正负与滑动方向相反)
            let percent = (-deltaY / changeHeight);
            let width = changeWidth as number;
            if (touchStartX >= (width / 2)) {
              this.showVolumeUi = true;

              let playerVolumeValue = this.mCurrentVolumeValue;
              playerVolumeValue += this.mMaxVolumeValue * percent;

              if (playerVolumeValue < 0) {
                playerVolumeValue = 0;
              }
              if (playerVolumeValue > this.mMaxVolumeValue) {
                playerVolumeValue = this.mMaxVolumeValue;
              }
              this.mCurrentVolumeValue = playerVolumeValue;
              if (this.mAudioManager) {
                this.mAudioManager.setVolume(audio.AudioVolumeType.MEDIA, playerVolumeValue, (err: BusinessError) => {
                  if (err) {
                    LogUtils.getInstance().LOGI(`Failed to set the volume. ${err}`);
                    return;
                  }
                })
              }
            } else {
              this.showBrightnessUi = true;

              let brightness = this.mCurrentBrightness;
              brightness += 255 * percent;
              if (brightness < 0) {
                brightness = 5;
              }
              if (brightness > 255) {
                brightness = 255;
              }
              let finalValue = brightness / 255;
              if (windowClass) {
                windowClass.setWindowBrightness(finalValue);
              }
              this.mCurrentBrightness = brightness;
            }
            touchStartY = touchY;
          }
        })
        .onActionEnd((_event: GestureEvent | undefined) => {
          LogUtils.getInstance().LOGI('Vertical Pan End')
          this.showVolumeUi = false;
          this.showBrightnessUi = false;
          this.isVerticalDrag = false;
        }),
      PanGesture(this.panOptionSeek)
        .onActionStart((event: GestureEvent | undefined) => {
          LogUtils.getInstance().LOGI('Horizontal Pan Start');
          if (!this.mIjkMediaPlayer) {
            return;
          }
          if (this.lock) {
            return;
          }
          if (this.loadingVisible == Visibility.Visible) {
            this.isLoadNotSeek = true;
            return;
          }

          if (this.isVerticalDrag) {
            return;
          }
          if (event && event.fingerList && event.fingerList[0]) {
            this.isSeek = true;
            // this.mIjkMediaPlayer.pause();
            this.showControls = false
            this.stopProgressTask();
            touchStartX = event.fingerList[0].localX;
            this.mSeekTimePosition = this.progressValue;
            LogUtils.getInstance()
              .LOGI('HorizontalSeekProgress event.onActionStart start x: ' + event.fingerList[0].localX +
                ' event.onActionStart start y: ' + event.fingerList[0].localY);
          }
        })
        .onActionUpdate((event: GestureEvent | undefined) => {
          if (!this.mIjkMediaPlayer) {
            return;
          }
          if (this.lock) {
            return;
          }
          if (this.isLoadNotSeek) {
            return;
          }

          if (this.isVerticalDrag) {
            return;
          }
          this.isHorizontalDrag = true;
          if (event && event.fingerList && event.fingerList[0]) {
            this.showSeekProgressUi = true;

            let touchX = event.fingerList[0].localX;
            let deltaX = touchX - touchStartX;
            if (deltaX > 0) {
              this.mSeekDirectionRes = $r('app.media.video_forward_icon');
            } else {
              this.mSeekDirectionRes = $r('app.media.video_backward_icon');
            }

            let position: number = this.mIjkMediaPlayer.getCurrentPosition();
            let totalTimeDuration: number = this.mIjkMediaPlayer.getDuration();
            let seekTimePosition: number = Number(position + (deltaX * totalTimeDuration / changeWidth));
            if (seekTimePosition < 0) {
              seekTimePosition = 0
            }
            if (seekTimePosition > totalTimeDuration) {
              seekTimePosition = totalTimeDuration;
            }
            // 当前调整的进度
            this.mSeekCurrentTime = this.stringForTime(seekTimePosition);
            // 设置当前进度
            this.mSeekTimePosition = Number((seekTimePosition / totalTimeDuration).toFixed(2)) * 100;
          }
        })
        .onActionEnd((_event: GestureEvent | undefined) => {
          if (!this.mIjkMediaPlayer) {
            return;
          }

          if (this.isLoadNotSeek) {
            this.isLoadNotSeek = false;
            return;
          }

          if (this.isHorizontalDrag && this.mIjkMediaPlayer) {
            this.progressValue = this.mSeekTimePosition;
            this.loadingVisible = Visibility.Visible;
            this.showControls = false
            let seekValue = this.mSeekTimePosition * (this.mIjkMediaPlayer.getDuration() / 100);
            this.seekTo(seekValue + "");
            this.setProgress()
            this.isSeek = false;
          }
          this.isHorizontalDrag = false;
          this.showSeekProgressUi = false;
        }),
      TapGesture({ count: 2 }).onAction((_event: GestureEvent | undefined) => {
        if (this.lock) {
          return;
        }
        if (this.loadingVisible == Visibility.Visible) {
          return;
        }
        if (!this.mIjkMediaPlayer) {
          return;
        }
        LogUtils.getInstance().LOGI('double click start');
        if (this.mIjkMediaPlayer.isPlaying()) {
          this.pause();
        } else {
          this.startPlayOrResumePlay();
        }
      }),
      LongPressGesture()//长按三倍速
        .onAction((event: GestureEvent) => {
          if (event) {
            //投屏不用倍速
            if (this.uiState.isCastPlaying) {
              return
            }
            this.mIjkMediaPlayer.setSpeed('3f')
            this.uiState.isFastSpeed = true
          }
        })
        // 长按动作一结束触发
        .onActionEnd((_event: GestureEvent) => {
          if (this.uiState.isFastSpeed) {
            this.mIjkMediaPlayer.setSpeed(this.playSpeed)
            this.uiState.isFastSpeed = false
          }
        })
    ))
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      changeWidth = newValue.width as number;
      changeHeight = newValue.height as number;
      // 如果用户不隐藏状态栏，全屏的时候组件高度与手机的高度差距小于50.就显示上方控制栏
      if (this.appUIState.isFullScreen) {
        this.fullShowLock = true;
      }
    })


    // Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
    //   Button($r('app.string.Play'))
    //     .onClick(() => {
    //       this.startPlayOrResumePlay();
    //     })
    //     .width('400px')
    //     .height('80px')
    //     .margin('15px')
    //   Button($r('app.string.Pause'))
    //     .onClick(() => {
    //       this.pause();
    //     })
    //     .width('400px')
    //     .height('80px')
    //     .margin('15px')
    // }
    //
    // Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
    //   Button($r('app.string.1x'))
    //     .onClick(() => {
    //       if (!this.debounce()) {
    //         return;
    //       }
    //       this.playSpeed = '1f'
    //       this.mIjkMediaPlayer.setSpeed("1f");
    //     })
    //     .width('400px')
    //     .height('80px')
    //     .margin('15px')
    //
    //   Button($r('app.string.1_5x'))
    //     .onClick(() => {
    //       if (!this.debounce()) {
    //         return;
    //       }
    //       this.playSpeed = '1.5f'
    //       this.mIjkMediaPlayer.setSpeed("1.5f");
    //     })
    //     .width('400px')
    //     .height('80px')
    //     .margin('15px')
    //
    //   Button($r('app.string.2x'))
    //     .onClick(() => {
    //       this.playSpeed = '2f'
    //       this.mIjkMediaPlayer.setSpeed("2f");
    //     })
    //     .width('400px')
    //     .height('80px')
    //     .margin('15px')
    // }

    // Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
    //   Button($r('app.string.startRecord'))
    //     .visibility(this.recordProgressVisible == Visibility.Visible ? Visibility.None : Visibility.Visible)
    //     .onClick(() => {
    //       this.startRecord()
    //     })
    //     .width('400px')
    //     .height('80px')
    //     .margin('15px')
    //
    //   Progress({ value: 0, total: 100, type: ProgressType.Ring })
    //     .width(50).color(Color.Blue)
    //     .style({ strokeWidth: 10, status: ProgressStatus.LOADING }).visibility(this.recordProgressVisible)
    //
    //   Button($r('app.string.stopRecord'))
    //     .visibility(this.recordProgressVisible == Visibility.Visible ? Visibility.None : Visibility.Visible)
    //     .onClick(() => {
    //       this.stopRecord(true)
    //     })
    //     .width('400px')
    //     .height('80px')
    //     .margin('15px')
    //
    //   Progress({ value: 0, total: 100, type: ProgressType.Ring })
    //     .width(50).color(Color.Blue)
    //     .style({ strokeWidth: 10, status: ProgressStatus.LOADING }).visibility(this.screenshotProgressVisible)
    //
    //   Button($r('app.string.screenshot'))
    //     .visibility(this.screenshotProgressVisible == Visibility.Visible ? Visibility.None : Visibility.Visible)
    //     .onClick(() => {
    //       this.screenshot()
    //     })
    //     .width('400px')
    //     .height('80px')
    //     .margin('15px')
    // }

  }

  // 开始播放字幕
  private startSubTitle() {
    if (this.uiState.subtitles.length === 0) {
      return
    }
    this.updateSubtitles();
  }

  // 停止播放字幕
  private stopSubTitle() {
    if (this.updateSubtitleTimer !== -1) {
      clearTimeout(this.updateSubtitleTimer);
      this.updateSubtitleTimer = -1;
    }
    this.uiState.currentSubtitle = '';
  }

  //更新字幕
  private updateSubtitles() {
    if (this.uiState.subtitles.length === 0) {
      return
    }
    const currentTime = this.mIjkMediaPlayer.getCurrentPosition()
    let currentSubtitle: SubtitleItem | null = null;
    let nextUpdateTime: number = Number.MAX_VALUE;

    // 查找当前时间应显示的字幕
    for (const subtitle of this.uiState.subtitles) {
      if (currentTime >= subtitle.startTime && currentTime < subtitle.endTime) {
        currentSubtitle = subtitle;
        nextUpdateTime = subtitle.endTime;
        break;
      } else if (subtitle.startTime > currentTime) {
        nextUpdateTime = subtitle.startTime;
        break;
      }
    }

    // 更新字幕显示
    this.uiState.currentSubtitle = currentSubtitle ? currentSubtitle.text : '';

    // 安排下一次更新
    if (nextUpdateTime !== Number.MAX_VALUE) {
      const delay = nextUpdateTime - currentTime;
      this.updateSubtitleTimer = setTimeout(() => {
        this.updateSubtitles();
      }, delay);
    }
  }

  // 跳转到指定时间
  private seekToSubtitle() {
    if (this.uiState.subtitles.length === 0) {
      return
    }
    if (this.updateSubtitleTimer !== -1) {
      clearTimeout(this.updateSubtitleTimer);
    }
    this.updateSubtitles()
  }

  private initDelayPlay(context: object) {
    this.mContext = context;
    let that = this;
    setTimeout(() => {
      that.startPlayOrResumePlay();
      that.mFirst = false;
    }, 300)
  }

  private startPlayOrResumePlay() {
    this.mDestroyPage = false;
    LogUtils.getInstance()
      .LOGI("startPlayOrResumePlay start this.uiState.CONTROL_PlayStatus:" + this.uiState.CONTROL_PlayStatus)
    if (this.uiState.CONTROL_PlayStatus == PlayStatus.INIT) {
      this.stopProgressTask();
      this.startProgressTask();
      this.play(this.videoUrl.toString());
      this.timeCountdown()
    }
    if (this.uiState.CONTROL_PlayStatus == PlayStatus.PAUSE) {
      this.uiState.CONTROL_PlayStatus = PlayStatus.PLAY
      this.mIjkMediaPlayer.start();
      this.setProgress()
      this.timeCountdown()
    }
    this.uiState.playerStatus = PlayerStatus.PLAYING
  }

  private completionNum(num: number): string | number {
    if (num < 10) {
      return '0' + num;
    } else {
      return num;
    }
  }

  private stringForTime(timeMs: number): string {
    let totalSeconds: number | string = (timeMs / 1000);
    let newSeconds: number | string = totalSeconds % 60;
    let minutes: number | string = (totalSeconds / 60) % 60;
    let hours: number | string = totalSeconds / 3600;
    //LogUtils.getInstance().LOGI("stringForTime hours:" + hours + ",minutes:" + minutes + ",seconds:" + newSeconds);
    hours = this.completionNum(Math.floor(Math.floor(hours * 100) / 100));
    minutes = this.completionNum(Math.floor(Math.floor(minutes * 100) / 100));
    newSeconds = Math.floor(Math.floor(newSeconds * 100) / 100)
    if (this.isCurrentTime) {
      if (this.oldSeconds < newSeconds || newSeconds === 0 || this.isSeek) {
        this.oldSeconds = newSeconds
      } else {
        newSeconds = this.oldSeconds
      }
    }
    newSeconds = this.completionNum(newSeconds);
    if (hours > 0) {
      return hours + ":" + minutes + ":" + newSeconds;
    } else {
      return minutes + ":" + newSeconds;
    }
  }

  private setProgress() {
    let position = this.mIjkMediaPlayer.getCurrentPosition();
    let duration = this.mIjkMediaPlayer.getDuration();
    let pos = 0;
    if (duration > 0) {
      this.slideEnable = true;
      let curPercent = position / duration;
      pos = curPercent * 100;
      if (pos > this.PROGRESS_MAX_VALUE) {
        this.progressValue = this.PROGRESS_MAX_VALUE
      } else {
        this.progressValue = pos;
      }
    }
    // LogUtils.getInstance()
    //   .LOGI("setProgress position:" + position + ",duration:" + duration + ",progressValue:" + pos);
    this.totalTime = this.stringForTime(duration);
    if (position > duration) {
      position = duration;
    }
    this.isCurrentTime = true;
    this.currentTime = this.stringForTime(position);
    this.isCurrentTime = false

  }

  private startProgressTask() {
    let that = this;
    this.updateProgressTimer = setInterval(() => {
      // LogUtils.getInstance().LOGI("startProgressTask");
      if (!that.mDestroyPage) {
        that.setProgress();
      }
    }, 300);
  }

  private stopProgressTask() {
    // LogUtils.getInstance().LOGI("stopProgressTask");
    clearInterval(this.updateProgressTimer);
  }

  private showLoadIng() {
    this.loadingVisible = Visibility.Visible;
    this.replayVisible = Visibility.None;
  }

  private hideLoadIng() {
    this.loadingVisible = Visibility.None;
    this.replayVisible = Visibility.None;
  }

  private showRePlay() {
    this.loadingVisible = Visibility.None;
    this.replayVisible = Visibility.Visible;
  }

  private play(url: string) {
    let that = this;
    that.showLoadIng();
    //设置XComponent回调的context
    if (!!this.mContext) {
      this.mIjkMediaPlayer.setContext(this.mContext, 'xcomponentId');
    }
    if (this.uiState.CONTROL_PlayStatus == PlayStatus.INIT) {
      this.mIjkMediaPlayer.reset();
    }
    this.uiState.CONTROL_PlayStatus = PlayStatus.PLAY;
    //设置debug模式
    this.mIjkMediaPlayer.setDebug(false);
    //初始化配置
    this.mIjkMediaPlayer.native_setup();
    // 初始化配置后需要重新设置音频流音量，否则音量为默认值1.0
    // this.mIjkMediaPlayer.setVolume(this.volume.toString(), this.volume.toString());
    //设置视频源
    this.mIjkMediaPlayer.setDataSource(url);
    //使用精确寻帧 例如，拖动播放后，会寻找最近的关键帧进行播放，很有可能关键帧的位置不是拖动后的位置，而是较前的位置.可以设置这个参数来解决问题
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "enable-accurate-seek", "1");
    //预读数据的缓冲区大小
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max-buffer-size", "102400");
    //停止预读的最小帧数
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "min-frames", "100");
    //启动预加载
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", "1");
    // 设置无缓冲，这是播放器的缓冲区，有数据就播放
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", "0");
    //跳帧处理,放CPU处理较慢时，进行跳帧处理，保证播放流程，画面和声音同步
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", "5");
    // 最大缓冲cache是3s， 有时候网络波动，会突然在短时间内收到好几秒的数据
    // 因此需要播放器丢包，才不会累积延时
    // 这个和第三个参数packet-buffering无关。
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max_cached_duration", "3000");
    // 无限制收流
    // this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "infbuf", "1");
    // this.mIjkMediaPlayer.setOptionLong(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "infbuf", "1")
    // 屏幕常亮
    this.mIjkMediaPlayer.setScreenOnWhilePlaying(true);
    // 设置超时
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "timeout", "30000000");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "connect_timeout", "10000000");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "addrinfo_timeout", "10000000");
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_timeout", "10000000");
    // 变速播放
    this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "soundtouch", "1");
    // 开启h265硬解码 开了4K HEVC SDR的个别视频会花屏
    // this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-hevc", "1");
    this.mIjkMediaPlayer.setSpeed(this.playSpeed);
    let Speed = this.mIjkMediaPlayer.getSpeed()
    LogUtils.getInstance().LOGI('getSpeed--' + Speed)
    //是否开启循环播放
    this.mIjkMediaPlayer.setLoopCount(false);
    let mOnVideoSizeChangedListener: OnVideoSizeChangedListener = {
      onVideoSizeChanged: (width: number, height: number, sar_num: number, sar_den: number) => {
        if (height === 0) {
          return;
        }
        const va = width / height;
        const vpa = that.videoParentAspectRatio;
        if (vpa > va) {
          that.videoWidth = (width / (height * vpa)) * 100 + '%';
        } else {
          that.videoWidth = '100%';
        }
        if (width && height) {
          that.videoAspectRatio = width / height;
        }
        LogUtils.getInstance()
          .LOGI("setOnVideoSizeChangedListener-->go:" + width + "," + height + "," + sar_num + "," + sar_den);
        that.getVideoSize();
        that.hideLoadIng();
      }
    }
    this.mIjkMediaPlayer.setOnVideoSizeChangedListener(mOnVideoSizeChangedListener);
    let mOnPreparedListener: OnPreparedListener = {
      onPrepared: () => {
        this.uiState.playerStatus = PlayerStatus.PREPARED
        LogUtils.getInstance().LOGI("setOnPreparedListener-->go");
        if (this.uiState.initSeek > 0) {
          setTimeout(() => {
            this.seekTo(this.uiState.initSeek + "")
            this.uiState.initSeek = 0
            if (this.uiState.audioTrackIndex) {
              this.mIjkMediaPlayer.selectTrack(this.uiState.audioTrackIndex + 1 + '')
            }
          }, 500)
        }
      }
    }
    this.mIjkMediaPlayer.setOnPreparedListener(mOnPreparedListener);

    let mOnTimedTextListener: OnTimedTextListener = {
      onTimedText: () => {
      }
    }
    this.mIjkMediaPlayer.setOnTimedTextListener(mOnTimedTextListener)

    let mOnCompletionListener: OnCompletionListener = {
      onCompletion: () => {
        LogUtils.getInstance().LOGI("OnCompletionListener-->go")
        that.showRePlay();
        that.currentTime = that.stringForTime(this.mIjkMediaPlayer.getDuration());
        that.progressValue = this.PROGRESS_MAX_VALUE;
        that.slideEnable = false;
        that.stop();
      }
    }
    this.mIjkMediaPlayer.setOnCompletionListener(mOnCompletionListener);

    let mOnBufferingUpdateListener: OnBufferingUpdateListener = {
      onBufferingUpdate: (_percent: number) => {
        // LogUtils.getInstance().LOGI("OnBufferingUpdateListener-->go:" + percent);
        // let MediaInfo = this.mIjkMediaPlayer.getMediaInfo()
        // LogUtils.getInstance().LOGI('getMediaInfo---' + MediaInfo);
        // let VideoWidth = this.mIjkMediaPlayer.getVideoWidth()
        // LogUtils.getInstance().LOGI('getVideoWidth---' + VideoWidth);
        //
        // let VideoHeight = this.mIjkMediaPlayer.getVideoHeight()
        // LogUtils.getInstance().LOGI('getVideoHeight---' + VideoHeight);
        //
        // let VideoSarNum = this.mIjkMediaPlayer.getVideoSarNum()
        // LogUtils.getInstance().LOGI('getVideoSarNum---' + VideoSarNum);
        //
        // let VideoSarDen = this.mIjkMediaPlayer.getVideoSarDen()
        // LogUtils.getInstance().LOGI('getVideoSarDen---' + VideoSarDen);
        //
        // let AudioSessionId = this.mIjkMediaPlayer.getAudioSessionId()
        // LogUtils.getInstance().LOGI('getAudioSessionId---' + AudioSessionId);
        //
        // let Looping = this.mIjkMediaPlayer.isLooping()
        // LogUtils.getInstance().LOGI('isLooping---' + Looping);
      }
    }
    this.mIjkMediaPlayer.setOnBufferingUpdateListener(mOnBufferingUpdateListener);

    let mOnSeekCompleteListener: OnSeekCompleteListener = {
      onSeekComplete: () => {
        if (this.uiState.isCastPlaying) {
          return
        }
        LogUtils.getInstance().LOGI("OnSeekCompleteListener-->go");
        that.startPlayOrResumePlay();
      }
    }
    this.mIjkMediaPlayer.setOnSeekCompleteListener(mOnSeekCompleteListener);

    let mOnInfoListener: OnInfoListener = {
      onInfo: (_what: number, _extra: number) => {
        //LogUtils.getInstance().LOGI("OnInfoListener-->go:" + what + "===" + extra);
        that.hideLoadIng();
      }
    }
    this.mIjkMediaPlayer.setOnInfoListener(mOnInfoListener);


    let mOnErrorListener: OnErrorListener = {
      onError: (what: number, extra: number) => {
        this.uiState.playerStatus = PlayerStatus.ERROR
        this.stopProgressTask();
        LogUtils.getInstance().LOGI("OnErrorListener-->go:" + what + "===" + extra)
        that.hideLoadIng();
        prompt.showToast({
          message: getContext()
            .resourceManager
            .getStringByNameSync("Honey_the_video_is_playing_errant_The_system_is_wandering")
        });
      }
    }


    this.mIjkMediaPlayer.setOnErrorListener(mOnErrorListener);

    this.mIjkMediaPlayer.setMessageListener();

    this.mIjkMediaPlayer.prepareAsync();

    this.mIjkMediaPlayer.start();
  }

  private getVideoSize() {
    let VideoWidth = this.mIjkMediaPlayer.getVideoWidth();
    LogUtils.getInstance().LOGI("getVideoWidth---" + VideoWidth);

    let VideoHeight = this.mIjkMediaPlayer.getVideoHeight();
    LogUtils.getInstance().LOGI("getVideoHeight---" + VideoHeight);
  }

  private pause() {
    if (this.mIjkMediaPlayer.isPlaying()) {
      this.mIjkMediaPlayer.pause();
      this.setProgress();
      this.mDestroyPage = true;
      this.uiState.CONTROL_PlayStatus = PlayStatus.PAUSE;
      this.uiState.playerStatus = PlayerStatus.PAUSED
    }
  }

  private stop() {
    this.uiState.CONTROL_PlayStatus = PlayStatus.INIT;
    this.uiState.playerStatus = PlayerStatus.STOPPED
    this.mIjkMediaPlayer.stop();
    this.mIjkMediaPlayer.release();
    this.uiState.playerStatus = PlayerStatus.RELEASED
    this.stopProgressTask();
    this.stopSubTitle()
  }

  private seekTo(value: string) {
    if (this.uiState.isCastPlaying) {
      this.mIjkMediaPlayer.seekTo(value);
    } else {
      this.mIjkMediaPlayer.seekTo(value);
      this.seekToSubtitle()
      this.sendAVSessionState(this.uiState.playerStatus)
    }
  }

  debounce() {
    const delay = 600;
    let cur = new Date().getTime();
    if (cur - this.last > delay) {
      this.last = cur;
      return true;
    }
    return false;
  }

  // private startRecord() {
  //   let isRecord = this.mIjkMediaPlayer.isRecord()
  //   if (isRecord) {
  //     prompt.showToast({
  //       message: $r('app.string.recordIng')
  //     });
  //     return
  //   }
  //   this.recordSaveFilePath = getContext(this).cacheDir + "/record.mp4";
  //   let result = this.mIjkMediaPlayer.startRecord(this.recordSaveFilePath);
  //   prompt.showToast({
  //     message: result ? $r('app.string.start_record_success') : $r('app.string.start_record_failed')
  //   });
  // }

  // private stopRecord(isShowTip: boolean) {
  //   let isRecord = this.mIjkMediaPlayer.isRecord()
  //   if (!isRecord) {
  //     if (isShowTip) {
  //       prompt.showToast({
  //         message: $r('app.string.record_not_enabled')
  //       });
  //     }
  //     return
  //   }
  //   this.recordProgressVisible = Visibility.Visible;
  //   let that = this;
  //   this.mIjkMediaPlayer.stopRecord().then((result) => {
  //     that.recordProgressVisible = Visibility.None;
  //     if (!result) {
  //       prompt.showToast({
  //         message: $r('app.string.stop_record_failed')
  //       });
  //       return;
  //     }
  //     let atManager = abilityAccessCtrl.createAtManager();
  //     atManager.requestPermissionsFromUser(getContext(that), ['ohos.permission.WRITE_IMAGEVIDEO']).then(async () => {
  //       let photoType: photoAccessHelper.PhotoType = photoAccessHelper.PhotoType.VIDEO;
  //       let extension: string = 'mp4';
  //       let options: photoAccessHelper.CreateOptions = {
  //         title: "record_" + new Date().getTime() + ""
  //       }
  //       let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext(that));
  //       phAccessHelper.createAsset(photoType, extension, options, (err, uri) => {
  //         LogUtils.getInstance().LOGI(`createAsset success uri:${uri}`)
  //         if (uri !== undefined) {
  //           let recordFile = fs.openSync(that.recordSaveFilePath);
  //           let albumFile = fs.openSync(uri, fs.OpenMode.READ_WRITE);
  //           fs.copyFileSync(recordFile.fd, albumFile.fd);
  //           fs.closeSync(recordFile);
  //           fs.closeSync(albumFile);
  //           prompt.showToast({
  //             message: $r('app.string.stop_record_success')
  //           });
  //         } else {
  //           prompt.showToast({
  //             message: $r('app.string.stop_record_failed')
  //           });
  //           LogUtils.getInstance().LOGI(`createAsset failed, error: ${err.code}, ${err.message}`)
  //         }
  //       });
  //     })
  //   })
  // }
  //
  // private screenshot() {
  //   let that = this;
  //   let saveFilePath = getContext(this).cacheDir + "/screen.jpg";
  //   this.screenshotProgressVisible = Visibility.Visible;
  //   this.mIjkMediaPlayer.screenshot(saveFilePath).then((result) => {
  //     that.screenshotProgressVisible = Visibility.None;
  //     if (!result) {
  //       prompt.showToast({
  //         message: $r('app.string.screenshot_failed')
  //       });
  //       return;
  //     }
  //     let atManager = abilityAccessCtrl.createAtManager();
  //     atManager.requestPermissionsFromUser(getContext(that), ['ohos.permission.WRITE_IMAGEVIDEO']).then(async () => {
  //       let photoType: photoAccessHelper.PhotoType = photoAccessHelper.PhotoType.IMAGE;
  //       let extension: string = 'jpg';
  //       let options: photoAccessHelper.CreateOptions = {
  //         title: "screenshot_" + new Date().getTime() + ""
  //       }
  //       let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext(that));
  //       phAccessHelper.createAsset(photoType, extension, options, (err, uri) => {
  //         LogUtils.getInstance().LOGI(`createAsset success uri:${uri}`)
  //         if (uri !== undefined) {
  //           let screenshotFile = fs.openSync(saveFilePath);
  //           let albumFile = fs.openSync(uri, fs.OpenMode.READ_WRITE);
  //           fs.copyFileSync(screenshotFile.fd, albumFile.fd);
  //           fs.closeSync(screenshotFile);
  //           fs.closeSync(albumFile);
  //           prompt.showToast({
  //             message: $r('app.string.screenshot_success')
  //           });
  //         } else {
  //           prompt.showToast({
  //             message: $r('app.string.screenshot_failed')
  //           });
  //           LogUtils.getInstance().LOGI(`createAsset failed, error: ${err.code}, ${err.message}`)
  //         }
  //       });
  //     })
  //   });
  // }

  private timeCountdown() {
    clearTimeout(uiTime);
    if (!this.lock) {
      this.showControls = true;
    }
    if (this.appUIState.isFullScreen) {
      this.fullShowLock = true
    }
    this.sec = 3;
    uiTime = setInterval(() => {
      if (this.sec <= 0) {
        clearTimeout(uiTime);
        this.showControls = false;
        this.fullShowLock = false;
      } else {
        this.sec--;
      }
    }, 1000)
  }

  private timeLockCountdown() {
    clearTimeout(uiLockTime);
    this.fullShowLock = true;
    this.sec = 3;
    uiLockTime = setInterval(() => {
      if (this.sec <= 0) {
        clearTimeout(uiLockTime);
        this.fullShowLock = false;
      } else {
        this.sec--;
      }
    }, 1000)
  }

  sendAVSessionState(status: number) {
    let playbackState: avSession.AVPlaybackState = {
      speed: Number(this.playSpeed.replace('f', '')),
      position: {
        elapsedTime: this.mIjkMediaPlayer.getCurrentPosition(),
        updateTime: Date.now()
      },
    }
    switch (status) {
      case PlayerStatus.IDLE:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_IDLE
        break
      case PlayerStatus.INITIALIZED:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_INITIAL
        break
      case PlayerStatus.PREPARED:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_PREPARE
        break
      case PlayerStatus.PLAYING:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_PLAY
        break
      case PlayerStatus.PAUSED:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_PAUSE
        break
      case PlayerStatus.COMPLETED:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_COMPLETED
        break
      case PlayerStatus.STOPPED:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_STOP
        break
      case PlayerStatus.RELEASED:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_RELEASED
        break
      case PlayerStatus.ERROR:
        playbackState.state = avSession.PlaybackState.PLAYBACK_STATE_ERROR
        break
    }
    avSessionManager.getSession()?.setAVPlaybackState(playbackState).then(() => {
      console.info('SetAVPlaybackState successfully');
    }).catch((err: BusinessError) => {
      console.error(`SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
    });
  }

  formatBitrate(bitrate: number): string {
    const BITRATE_MEGA_BIT: number = 1_000_000; // 1M
    const BITRATE_KILO_BIT: number = 1_000; // 1K
    let value: number;
    let unit: string;

    if (bitrate > BITRATE_MEGA_BIT) {
      value = bitrate / BITRATE_MEGA_BIT;
      unit = " Mbps";
    } else if (bitrate > BITRATE_KILO_BIT) {
      value = bitrate / BITRATE_KILO_BIT;
      unit = " kbps";
    } else {
      value = bitrate;
      unit = " bps";
    }
    // Format to 2 decimal places and remove trailing zeros
    const formatted = value.toFixed(2).replace(/\.?0+$/, '');
    return formatted + unit;
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
    if (canIUse('SystemCapability.Window.SessionManager')) {
      switch (state) {
        case PiPWindow.PiPState.ABOUT_TO_START:
          // this.curState = 'ABOUT_TO_START';
          // this.curError = $r('app.string.current_error_hint');
          break;
        case PiPWindow.PiPState.STARTED:
          // this.curState = 'STARTED';
          // this.curError = $r('app.string.current_error_hint');
          this.startPlayOrResumePlay()
          break;
        case PiPWindow.PiPState.ABOUT_TO_STOP:
          // this.curState = 'ABOUT_TO_STOP';
          // this.curError = $r('app.string.current_error_hint');
          //点了画中画的关闭按钮
          this.startPlayOrResumePlay()
          break;
        case PiPWindow.PiPState.STOPPED:

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
    switch (event) {
      case 'playbackStateChanged':
        if (status === 0) {
          this.pause()
        } else {
          this.startPlayOrResumePlay()
        }
        break;
      default:
        break;
    }
    // this.buttonAction = event + `-status:${status}`;
    // Logger.info(`[${TAG}] onActionEvent: ${this.buttonAction} status:${status}}`);
  }

  async startPip() {
    if (!this.pipController) {
      await this.createPipController();
    }
    if (!this.pipController) {
      console.info(`pipController create error`);
      return;
    }
    await this.pipController.startPiP();
  }

  async stopPip() {
    if (!this.pipController) {
      console.info(`pipController is not exist`);
      return;
    }
    await this.pipController.stopPiP();
  }
}

@Extend(Stack)
function menuItemStyle() {
  .borderRadius(8)
  .backgroundColor('rgba(255,255,255,0.2)')
  .width('100%')
  .layoutWeight(1)
}