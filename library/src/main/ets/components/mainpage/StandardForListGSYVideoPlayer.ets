/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import display from '@ohos.display';
import { LogUtils } from '../utils/LogUtils';
import { IjkVideoPlayer } from './IjkVideoPlayer';
import { IVideoPlayer } from './IVideoPlayer';
import { PlayStatus } from './CommonConstants';
import emitter from '@ohos.events.emitter';
import { GlobalContext } from './GlobalContext';
import { PlayerType } from './CommonConstants';
import { AvVideoPlayer } from './AvVideoPlayer';
import { StandardGSYVideoModel } from './StandardGSYVideoModel';

let updateProgressTimer: number = 0;
let changeHeight: number = 0;
let screenHeight: number = 0;
let uiLockTime: number = 0;

let videoPlayEvent: emitter.InnerEvent = {
  eventId: 1
};
let videoInitEvent: emitter.InnerEvent = {
  eventId: 2
};
let videoPauseEvent: emitter.InnerEvent = {
  eventId: 3
};

@Component
export struct StandardForListGSYVideoPlayer {
  mIVideoPlayer: IVideoPlayer | undefined = undefined;
  @Provide currentTime: string = "00:00";
  @Provide totalTime: string = "00:00";
  @State progressValue: number = 0;
  @State slideEnable: boolean = false;
  @State eventType: string = '';
  @State showBottomUi: boolean = false;
  @State fullShowTop: boolean = false;
  @State fullShowLock: boolean = false;
  @State lock: boolean = false;
  @State showPlay: boolean = true;
  @State showPause: boolean = false;
  @State showFull: Visibility = Visibility.None;
  @State mDestroyPage: boolean = false;
  @State loadingVisible: Visibility = Visibility.None;
  @State mDirection: number = 0;
  @State screenIsFull: boolean = false;
  // 是否显示音量数值的布局
  @State showVolumeUi: boolean = false;
  // 是否显示亮度数值的布局
  @State showBrightnessUi: boolean = false;
  // 是否显示横向滑动的进度布局
  @State showSeekProgressUi: boolean = false;
  // 当前音量 [0-20]
  @State mCurrentVolumeValue: number = 0;
  // 系统最大音量
  @State mMaxVolumeValue: number = 20;
  // 当前亮度 [0-255]
  @State mCurrentBrightness: number = 10;
  // 拖拽的时间
  @State mSeekCurrentTime: string = this.currentTime;
  // 当前进度
  @State mSeekTimePosition: number = 0;
  // 是否拖动进度条
  private isSeek: boolean = false;
  // 当前拖拽进度的方向资源
  @State mSeekDirectionRes: Resource = $r('app.media.video_forward_icon');
  @State coverVisible: Visibility = Visibility.Visible;
  public title: string = "";
  private xComponentId: string = 'xid';
  private uiTime: number = 0;
  sec: number = 3;
  PROGRESS_MAX_VALUE: number = 100;
  @State ijkComponentVisible: Visibility = Visibility.Hidden;
  public videoModel: StandardGSYVideoModel = new StandardGSYVideoModel();
  videoInit: (iVideoPlayer: IVideoPlayer, xid: string) => void = (iVideoPlayer: IVideoPlayer, xid: string) => {
    LogUtils.getInstance().LOGI('IJKVideoInit')
    this.mIVideoPlayer = iVideoPlayer
    this.xComponentId = xid;
    this.mIVideoPlayer.setUp(this.videoModel.getUrl(), this.videoModel.getCacheWithPlay())
  }

  @Builder
  topTitle() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      Image($r('app.media.video_back'))
        .width(15)
        .height(15)
        .margin({ top: 10, left: 15 })
        .onClick(() => {
          this.videoModel.ExecuteBackClickListener();
        })
      Text(this.videoModel.getTitle())
        .fontSize('10vp')
        .margin({ top: 10, left: 5 })
        .fontColor($r('app.color.color_white'))
    }
    .align(Alignment.BottomEnd)
    .backgroundColor($r('app.color.bottom_controls_color'))
    .position({ x: 0, y: 0 })
    .padding(10)
  }

  @Builder
  middleControls() {
    Row() {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      }
      .align(Alignment.BottomEnd)
      .width('33.3%')
      .height('100%')

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        if (this.showPlay) {
          Image($r('app.media.video_play_pressed'))
            .width(30)
            .height(30)
            .onClick(() => {
              this.videoToPlay();
            })
        }

        Image($r('app.media.icon_load'))
          .objectFit(ImageFit.Auto)
          .width(30)
          .height(30)
          .visibility(this.loadingVisible)
          .border({ width: 0 })
          .borderStyle(BorderStyle.Dashed)

        if (this.showPause) {
          Image($r('app.media.video_pause_normal'))
            .width(30)
            .height(30)
            .onClick(() => {
              LogUtils.getInstance().LOGI('click pause')
              this.videoToPause();
            })
        }
      }
      .align(Alignment.BottomEnd)
      .width('33.3%')
      .height('100%')

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
        if (this.mDirection == 1 && this.fullShowLock) {
          Image(this.lock ? $r('app.media.lock') : $r('app.media.unlock'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .margin({ right: 15 })
            .onClick(() => {
              this.lock = !this.lock;
              if (this.lock) {
                this.showBottomUi = false;
                this.fullShowTop = false;
                this.showPlay = false;
                this.showPause = false;
              }
            })
        }
      }
      .align(Alignment.BottomEnd)
      .width('33.3%')
      .height('100%')
    }.width("100%")
    .height('100%')
  }

  private videoToPause() {
    if (this.mIVideoPlayer) {
      LogUtils.getInstance().LOGI('standardGSYVideoPlayer onPause1 click')
      this.mIVideoPlayer.pause();
    }
  }

  private videoToPlay() {
    if (this.mIVideoPlayer) {
      LogUtils.getInstance().LOGI('standardGSYVideoPlayer onPlay click')
      this.timeCountdown();
      this.loadingVisible = Visibility.Visible;
      this.showPause = false;
      this.showPlay = false;
      this.videoJudgeToPlay();
    }
  }

  private videoJudgeToPlay() {
    LogUtils.getInstance().LOGI('videoJudgeToPlay');
    if (this.mIVideoPlayer) {
      if (GlobalContext.getContext().getObject('xid') !== this.mIVideoPlayer.xComponentId) {
        LogUtils.getInstance().LOGI('videoJudgeToPlay1');
        this.mIVideoPlayer.play();
        this.mIVideoPlayer.firstOrSeek = true;
      } else {
        LogUtils.getInstance().LOGI('videoJudgeToPlay2');
        if (this.mIVideoPlayer.playStatus == PlayStatus.PAUSE) {
          LogUtils.getInstance().LOGI('standardGSYVideoPlayer videoJudgeToPlay ResumePlay');
          this.mIVideoPlayer.resumePlay();
        } else {
          LogUtils.getInstance().LOGI('standardGSYVideoPlayer videoJudgeToPlay play: ' + this.mIVideoPlayer.videoUrl);
          this.mIVideoPlayer.play();
        }
      }
    }
  }

  @Builder
  bottomControls() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      Text(this.currentTime)
        .width('80px')
        .fontSize('20px')
        .margin({ left: 20 })
        .fontColor($r('app.color.color_white'))

      Slider({
        value: this.progressValue,
        min: 0,
        max: this.PROGRESS_MAX_VALUE,
        step: 1,
        style: SliderStyle.OutSet
      })
        .layoutWeight(1)
        .blockColor(Color.Blue)
        .trackColor(Color.Gray)
        .selectedColor(Color.Blue)
        .showSteps(true)
        .showTips(true)
        .onChange((value: number, mode: SliderChangeMode) => {
          clearTimeout(this.uiTime);
          if (this.mIVideoPlayer) {
            switch (mode) {
              case SliderChangeMode.Begin:
              // 通知的回调会到的慢一点，导致下面设置的showPause = true无效
              // 使用isSeek参数去控制pause通知里面的状态操作
                this.mIVideoPlayer.pause();
                this.isSeek = true;
                this.stopProgressTask();
                this.showPlay = false;
                this.showPause = true;
                break;
              case SliderChangeMode.End:
                this.showPause = false;
                this.loadingVisible = Visibility.Visible;
                this.isSeek = false;
                let seekValue = value * (this.mIVideoPlayer.getDuration() / 100);
                this.mIVideoPlayer.seekTo(seekValue);
                this.mIVideoPlayer.firstOrSeek = true;
                LogUtils.getInstance().LOGI('slider-->seekValue end: ' + seekValue);
                break;
            }
          }
        })
      Text(this.totalTime).fontSize('20px').margin({ right: ((this.showFull == Visibility.Visible)) ? 5 : 20 }).fontColor($r('app.color.color_white'))

      Image(this.screenIsFull ? $r('app.media.video_shrink') : $r('app.media.video_enlarge'))
        .width(20)
        .height(18)
        .margin({ right: 15 })
        .onClick(() => {
          this.videoModel.ExecuteFullClickListener();
        }).visibility(this.showFull)
    }
    .padding({ bottom: 10 })
    .align(Alignment.BottomEnd)
    .backgroundColor($r('app.color.bottom_controls_color'))
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
        .height('30%')
        .rotate({ angle: -180 })
        .alignSelf(ItemAlign.Center)
        .backgroundColor(Color.White);

      Image($r('app.media.video_volume_icon'))
        .objectFit(ImageFit.Auto)
        .margin({ top: 5, left: 5 })
        .width(30)
        .height(30)
        .alignSelf(ItemAlign.Center)
        .borderStyle(BorderStyle.Dashed)
    }.visibility(this.showVolumeUi ? Visibility.Visible : Visibility.Hidden)
    .width(50)
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
    Stack({ alignContent: Alignment.Bottom }) {
      if (GlobalContext.getContext().getObject('playType') == PlayerType.SYSTEM_AVPLAYER) {
        AvVideoPlayer({ videoInit: this.videoInit })
      } else {
        IjkVideoPlayer({ videoInit: this.videoInit, isVisible: this.ijkComponentVisible })
      }

      if (this.videoModel.getCoverImage()) {
        Image(this.videoModel.getCoverImage())
          .width('100%')
          .height('100%')
          .visibility(this.coverVisible)
      }

      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        this.VolumeUi()
        this.SeekProgressUi()
        this.BrightnessUi()
      }.width('100%')
      .height('100%')

      this.middleControls()
      if (this.showBottomUi) {
        if (this.mDirection == 1 && this.fullShowTop) {
          this.topTitle()
        }
        this.bottomControls()
      }
    }
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

          if (!this.showPlay) {
            this.timeCountdown();
          }
          if (event && event.fingerList && event.fingerList[0]) {
            LogUtils.getInstance().LOGI('TapGesture event.onActionStart start x: ' + event.fingerList[0].localX +
              " ---event.onActionStart start y: " + event.fingerList[0].localY);
          }
        }
      }),
      TapGesture({ count: 2 }).onAction((event: GestureEvent | undefined) => {
        if (this.lock) {
          return;
        }

        if (this.loadingVisible == Visibility.Visible) {
          return;
        }

        if (!this.mIVideoPlayer) {
          return;
        }
        LogUtils.getInstance().LOGI('double click start');
        if (this.mIVideoPlayer.xComponentId != GlobalContext.getContext().getObject('xid')) {

          this.videoToPlay();
        } else {
          if (this.mIVideoPlayer.isPlaying()) {
            this.videoToPause();
          } else {
            this.videoToPlay();
          }
        }
      })
    )).onAreaChange((oldValue: Area, newValue: Area) => {
      changeHeight = newValue.height as number;
      screenHeight = px2vp(display.getDefaultDisplaySync().height);
      this.mDirection = this.getDirection();
      this.screenIsFull = (screenHeight - changeHeight) < 50;
      // 如果用户不隐藏状态栏，全屏的时候组件高度与手机的高度差距小于50.就显示上方控制栏
      if (this.mDirection == 1 && this.screenIsFull) {
        this.fullShowTop = true;
        this.fullShowLock = true;
      }
    }).backgroundColor(Color.Black)
  }

  /**
   * 注册的emitter消息回调，在list列表中，每个item都可以收到，只能通过xid区分当前是哪个才是真正的被点击的item
   * 去做相应的事件处理，不是当前选中的，一律变为初始状态（goInit）
   */
  private emitterInit() {
    emitter.on(videoPlayEvent, (data: emitter.EventData) => {
      if (data && data.data && typeof data.data.xid === 'string') {
        if (this.xComponentId == data.data.xid) {
          this.goPlaying();
        } else {
          this.goInit();
        }
      }
    });
    emitter.on(videoInitEvent, (data: emitter.EventData) => {
      if (data && data.data && typeof data.data.xid === 'string') {
        if (this.xComponentId == data.data.xid) {
          this.goInit();
        }
      }
    });
    emitter.on(videoPauseEvent, (data: emitter.EventData) => {
      if (data && data.data && typeof data.data.xid === 'string') {
        if (this.xComponentId == data.data.xid) {
          if (GlobalContext.getContext().getObject('playType') == PlayerType.SYSTEM_AVPLAYER) {
            if (this.mIVideoPlayer && this.mIVideoPlayer.isPlaying()) {
              this.goPause();
            }
          } else {
            this.goPause();
          }
        }
      }
    })
  }

  private goPlaying() {
    LogUtils.getInstance().LOGI('standardGSYVideoPlayer onPlayingListener');
    this.loadingVisible = Visibility.None;
    this.showPlay = false;
    this.showPause = true;
    this.showBottomUi = true;
    this.coverVisible = Visibility.None;
    this.timeCountdown();
    this.stopProgressTask();
    this.startProgressTask();
    this.ijkComponentVisible = Visibility.Visible;
    if (this.mIVideoPlayer) {
      this.totalTime = this.stringForTime(this.mIVideoPlayer.getDuration());
    }
    LogUtils.getInstance().LOGI('standardGSYVideoPlayer onPlayingListener end.');
  }

  private goInit() {
    LogUtils.getInstance().LOGI('standardGSYVideoPlayer onErrorListener');
    clearTimeout(this.uiTime);
    if (this.mIVideoPlayer && GlobalContext.getContext().getObject('playType') == PlayerType.SYSTEM_AVPLAYER) {
      LogUtils.getInstance().LOGI('PlayerType.SYSTEM_AVPLAYER need to stop');
      this.mIVideoPlayer.stop();
    }
    this.loadingVisible = Visibility.None;
    this.coverVisible = Visibility.Visible;
    this.ijkComponentVisible = Visibility.Hidden;
    this.showBottomUi = false;
    this.showPlay = true;
    this.showPause = false;
  }

  private goPause() {
    LogUtils.getInstance().LOGI('standardGSYVideoPlayer onPauseListener');
    if (!this.isSeek) {
      this.showPlay = true;
      this.showPause = false;
    }
    this.stopProgressTask();
    clearTimeout(this.uiTime);
    clearTimeout(uiLockTime);
    this.showBottomUi = true;
  }

  aboutToAppear() {
    LogUtils.getInstance().setLogSwitch(true);
    LogUtils.getInstance().LOGI('standardGSYVideoPlayer aboutToAppear');
    this.emitterInit();
    this.mDirection = this.getDirection();
  }

  aboutToDisappear() {
    LogUtils.getInstance().LOGI('standardGSYVideoPlayer aboutToDisappear');
    this.emitterOff();
    this.stop();
  }

  private emitterOff() {
    emitter.off(1);
    emitter.off(2);
    emitter.off(3);
  }

  private getDirection(): number {
    return getContext().getApplicationContext().resourceManager.getConfigurationSync().direction;
  }

  resumePlay() {
    LogUtils.getInstance().LOGI('standardGSYVideoPlayer resumePlay');
    if (this.mIVideoPlayer) {
      this.timeCountdown();
      this.videoJudgeToPlay();
    }
  }

  stop() {
    LogUtils.getInstance().LOGI('standardGSYVideoPlayer stop');
    this.stopProgressTask();
    if (this.mIVideoPlayer) {
      this.mIVideoPlayer.stop();
      this.mIVideoPlayer.release();
    }
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
    let seconds: number | string = totalSeconds % 60;
    let minutes: number | string = (totalSeconds / 60) % 60;
    let hours: number | string = (totalSeconds / 3600);

    hours = this.completionNum(Math.floor(Math.floor(hours * 100) / 100));
    minutes = this.completionNum(Math.floor(Math.floor(minutes * 100) / 100));
    seconds = this.completionNum(Math.floor(Math.floor(seconds * 100) / 100));

    if (hours > 0) {
      return hours + ":" + minutes + ":" + seconds;
    } else {
      return minutes + ":" + seconds;
    }
  }

  private stopProgressTask() {
    LogUtils.getInstance().LOGI('stopProgressTask');
    clearInterval(updateProgressTimer);
  }

  private startProgressTask() {
    let that = this;
    updateProgressTimer = setInterval(() => {
      LogUtils.getInstance().LOGI('startProgressTask');
      if (!that.mDestroyPage) {
        that.setProgress();
      }
    }, 1000)
  }

  private setProgress() {
    if (this.mIVideoPlayer) {
      let position = this.mIVideoPlayer.getCurrentPosition();
      let duration = this.mIVideoPlayer.getDuration();
      let pos = 0;
      if (duration > 0) {
        this.slideEnable = true;
        let curPercent = position / duration;
        pos = curPercent * 100;
        this.progressValue = pos;
      }
      LogUtils.getInstance()
        .LOGI('setProgress position: ' + position + ' duration: ' + duration + ' progressValue: ' + pos);
      this.totalTime = this.stringForTime(duration);
      if (position > duration) {
        position = duration;
      }
      this.currentTime = this.stringForTime(position);
    }
  }

  private timeCountdown() {
    clearTimeout(this.uiTime);
    this.showPause = true;
    this.showBottomUi = true;
    if (this.mDirection == 1 && this.screenIsFull) {
      this.fullShowLock = true;
      this.fullShowTop = true;
    }
    this.sec = 3;
    this.uiTime = setInterval(() => {
      if (this.sec <= 0) {
        clearTimeout(this.uiTime);
        this.showBottomUi = false;
        this.showPause = false;
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
}