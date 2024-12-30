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
import {
  IjkMediaPlayer,
  OnCompletionListener,
  OnErrorListener,
  OnInfoListener,
  OnPreparedListener,
  OnSeekCompleteListener,
  OnVideoSizeChangedListener
} from '@ohos/ijkplayer';
import { ICallBack, MP4Parser } from '@ohos/mp4parser';
import { GSYVideoGifSaveListener } from '../listener/GSYVideoGifSaveListener';
import { GSYVideoShotSaveListener } from '../listener/GSYVideoShotSaveListener';
import { LogUtils } from '../utils/LogUtils';
import { PlayStatus } from './CommonConstants';
import { GlobalContext } from './GlobalContext';
import { IVideoPlayer } from './IVideoPlayer';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { image } from '@kit.ImageKit';
import { componentSnapshot } from '@kit.ArkUI';
import { HttpProxyCacheServerBuilder } from '@ohos/video-cache';

let screenshotTimerStatus: boolean = false;
let screenshotTimer: number = 0;
let gifTempPath: string = "";

@Observed
export class IjkPlayerControl implements IVideoPlayer {

  xComponentController: XComponentController = new XComponentController()
  mIjkMediaPlayer: IjkMediaPlayer | undefined = undefined;

  public constructor() {
    this.mIjkMediaPlayer = IjkMediaPlayer.getInstance();
  }

  surfaceID: string = '';
  firstOrSeek: boolean = true;
  playStatus = PlayStatus.INIT;
  context: object | undefined = undefined;
  vId: string = 'vid';
  xComponentId: string = "xid";
  videoUrl: string = '';
  cacheWithPlay: boolean = false;
  videoPlayingEvent: emitter.InnerEvent = {
    eventId: 1,
    priority: emitter.EventPriority.IMMEDIATE
  };
  videoInitEvent: emitter.InnerEvent = {
    eventId: 2,
    priority: emitter.EventPriority.IMMEDIATE
  };
  videoPauseEvent: emitter.InnerEvent = {
    eventId: 3,
    priority: emitter.EventPriority.IMMEDIATE
  };
  onPlayingListener: () => void = () => {

  };
  onPauseListener: () => void = () => {

  };
  onErrorListener: () => void = () => {

  };

  release(): void {
    this.mIjkMediaPlayer?.release()
  }

  setVideoId(id: string): void {
    this.vId = id;
  }

  setXComponentId(id: string): void {
    this.xComponentId = id;
  }

  setXComponentController(controller: XComponentController): void {
    this.xComponentController = controller;
  }

  isPlaying(): boolean {
    if (this.mIjkMediaPlayer) {
      return this.mIjkMediaPlayer.isPlaying();
    }
    return false;
  }

  getCurrentPosition(): number {
    if (this.mIjkMediaPlayer) {
      return this.mIjkMediaPlayer.getCurrentPosition();
    }
    return 0;
  }

  setOnPauseListener(onPauseListener: () => void) {
    this.onPauseListener = onPauseListener;
  }

  setOnErrorListener(onErrorListener: () => void) {
    this.onErrorListener = onErrorListener;
  }

  setOnPlayingListener(onPlayingListener: () => void) {
    this.onPlayingListener = onPlayingListener;
  }

  play() {
    this.initPlay();
  }

  resumePlay() {
    if (this.mIjkMediaPlayer && this.playStatus == PlayStatus.PAUSE) {
      this.mIjkMediaPlayer.start();
      this.onPlayingStatus();
    }
  }

  pause() {
    if (this.mIjkMediaPlayer && this.playStatus == PlayStatus.PLAY) {
      this.mIjkMediaPlayer.pause();
      this.onPauseStatus();
    }
  }

  seekTo(time: number) {
    if (this.mIjkMediaPlayer) {
      this.mIjkMediaPlayer.seekTo(time.toString());
    }
  }

  async setUp(url: string, cacheWithPlay: boolean) {
    LogUtils.getInstance().LOGI('setUp');

    this.videoUrl = url;
    this.cacheWithPlay = cacheWithPlay;
    LogUtils.getInstance().LOGI('setUp: ' + this.videoUrl + '--------' + this.cacheWithPlay);

    // 开启边播边缓存
    if ((this.videoUrl.startsWith('http') || this.videoUrl.startsWith('https')) && this.cacheWithPlay) {
      LogUtils.getInstance().LOGI('play with cache');
      let server = new HttpProxyCacheServerBuilder(getContext()).cacheDirectory(getContext().cacheDir).build();
      this.videoUrl = await server.getProxyUrl(this.videoUrl);
    }
    LogUtils.getInstance().LOGI('setUp2: ' + this.videoUrl + '--------' + this.cacheWithPlay);
  }

  setContext(context: object, id: string): void {
    this.context = context;
    if (id) {
      this.xComponentId=id
    }
    if (this.mIjkMediaPlayer) {
      this.mIjkMediaPlayer.setContext(this.context, id);
    }
  }

  private initPlay() {
    if (this.mIjkMediaPlayer) {
      this.playStatus = PlayStatus.PLAY;

      // 设置当前context，如果是放在list场景中，这个操作可以解决list错乱问题
      // 单例的ijk播放器，切换Context就可以锁定选择的Xcomponent
      this.mIjkMediaPlayer.setContext(this.context, this.xComponentId);
      this.mIjkMediaPlayer.reset();
      GlobalContext.getContext().setObject('xid', this.xComponentId);
      GlobalContext.getContext().setObject('currentPlayer', this);

      // 设置debug模式
      this.mIjkMediaPlayer.setDebug(false);
      this.mIjkMediaPlayer.native_setup();

      // 设置视频源
      this.mIjkMediaPlayer.setDataSource(this.videoUrl);

      // 使用精确寻帧 例如，拖动播放后，会寻找最近的关键帧进行播放，很有可能关键帧的位置不是拖动后的位置
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "enable-accurate-seek", "1");

      // 预读数据的缓冲区大小
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max-buffer-size", "102400");

      // 停止预读的最小帧数
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "min-frames", "100");

      // 启动预加载
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", "1");

      // 设置无缓冲，这是播放器的缓冲区，有数据就播放
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", "0");

      // 跳帧处理，放CPU处理较慢时，进行跳帧处理，保证播放流程，画面和声音同步
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", "5");

      // 最大缓冲cache是3s,有时候网络波动，会突然在短时间内收到好几秒的数据
      // 因此需要播放器丢包，才不会累计延时
      // 这个和第三个参数packet-buffering无关。
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max_cached_duration", "3000");

      // 无限制收流
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "infbuf", "1");

      //IjkPlayer默认是关闭字幕显示的使用以下代码配置可以显示视频字幕
      // this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "subtitle", "1")
      // 开启h264与h265硬解码
      // this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-all-videos", "1");
      // 开启h265硬解码
      // this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-hevc", "1");
      //开硬解花屏

      // 屏幕常亮
      this.mIjkMediaPlayer.setScreenOnWhilePlaying(true);

      // 设置超时
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "timeout", "10000000");
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "connect_timeout", "10000000");
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "addrinfo_timeout", "10000000");
      this.mIjkMediaPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_timeout", "10000000");

      // 是否开启循环播放
      this.mIjkMediaPlayer.setLoopCount(false);

      let mOnVideoSizeChangedListener: OnVideoSizeChangedListener = {
        onVideoSizeChanged: (width: number, height: number, sar_num: number, sar_den: number) => {
          LogUtils.getInstance()
            .LOGI("setOnVideoSizeChangedListener-->go:" + width + "," + height + "," + sar_num + "," + sar_den);
        }
      }
      this.mIjkMediaPlayer.setOnVideoSizeChangedListener(mOnVideoSizeChangedListener);

      let mOnPreparedListener: OnPreparedListener = {
        onPrepared: () => {
          LogUtils.getInstance().LOGI("setOnPreparedListener--->go");
        }
      }
      this.mIjkMediaPlayer.setOnPreparedListener(mOnPreparedListener);
      let mOnCompletionListener: OnCompletionListener = {
        onCompletion: () => {
          LogUtils.getInstance().LOGI("OnCompletionListener--->go");
          this.firstOrSeek = true;
          this.onInitStatus();
        }
      }
      this.mIjkMediaPlayer.setOnCompletionListener(mOnCompletionListener);
      let mOnSeekCompleteListener: OnSeekCompleteListener = {
        onSeekComplete: () => {
          LogUtils.getInstance().LOGI("OnSeekCompleteListener--->go");
          this.resumePlay();
        }
      }
      this.mIjkMediaPlayer.setOnSeekCompleteListener(mOnSeekCompleteListener);
      let mOnInfoListener: OnInfoListener = {
        onInfo: (what: number, extra: number) => {
          // LogUtils.getInstance().LOGI("OnInfoListener--->go:" + what + "====" + extra);
          // LogUtils.getInstance().LOGI("OnInfoListener--->go: firstOrSeek===" + this.firstOrSeek);
          if (this.firstOrSeek) {
            // LogUtils.getInstance().LOGI("OnInfoListener--->first onplay:" + this.firstOrSeek);
            this.onPlayingStatus();
            this.firstOrSeek = false;
          }
        }
      }
      this.mIjkMediaPlayer.setOnInfoListener(mOnInfoListener);
      let mOnErrorListener: OnErrorListener = {
        onError: (what: number, extra: number) => {
          LogUtils.getInstance().LOGI("OnErrorListener--->go:" + what + "====" + extra);
          this.onInitStatus()
        }
      }
      this.mIjkMediaPlayer.setOnErrorListener(mOnErrorListener);

      this.mIjkMediaPlayer.setMessageListener();
      this.mIjkMediaPlayer.prepareAsync();
      this.mIjkMediaPlayer.start();
    }
  }

  stop() {
    LogUtils.getInstance().LOGI("IjkPlayerVideoPlayer stop");
    this.ijkStop();
    this.context = undefined;
    this.firstOrSeek = true;
    GlobalContext.getContext().setObject('currentPlayer', null);
  }

  private ijkStop() {
    LogUtils.getInstance().LOGI("IjkPlayerVideoPlayer ijkStop");
    this.playStatus = PlayStatus.INIT;
    if (this.mIjkMediaPlayer) {
      this.mIjkMediaPlayer.stop();
      this.mIjkMediaPlayer.release();
    }
  }

  getDuration(): number {
    if (this.mIjkMediaPlayer) {
      return this.mIjkMediaPlayer.getDuration();
    }
    return 0;
  }

  public saveFrame(fileSavePath: string, gsyVideoShotSaveListener: GSYVideoShotSaveListener | null) {
    componentSnapshot.get(this.vId, (error: Error, pixmap: image.PixelMap) => {
      if (error) {
        console.log("error:" + JSON.stringify(error));
        return;
      }
      const imagePackerApi = image.createImagePacker();
      const packOptions: image.PackingOption = {
        format: 'image/jpeg',
        quality: 10
      }
      imagePackerApi.packToData(pixmap, packOptions).then((res) => {
        const imageFd = fs.openSync(fileSavePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.writeSync(imageFd.fd, res);
        fs.closeSync(imageFd);
        if (gsyVideoShotSaveListener) {
          gsyVideoShotSaveListener.shotResult(0);
        }
      }).catch((error: Error) => {
        if (gsyVideoShotSaveListener) {
          gsyVideoShotSaveListener.shotResult(1);
        }
      }).finally(() => {
        imagePackerApi.release();
        pixmap.release();
      });
    })
  }


  startGif(tmpPicPath?: string) {
    let count = 1;
    screenshotTimerStatus = true;
    screenshotTimer = setInterval(() => {
      if (!screenshotTimerStatus) {
        return;
      }
      let path = "";
      if (tmpPicPath) { // 路径不为空
        try {
          let res = fs.accessSync(tmpPicPath);
          if (res) {
            LogUtils.getInstance().LOGI("gifFileTempDir exists");
          } else {
            LogUtils.getInstance().LOGI("gifFileTempDir not exists");
            fs.mkdirSync(tmpPicPath);
          }
        } catch (error) {
          let err: BusinessError = error as BusinessError;
          LogUtils.getInstance()
            .LOGI("accessSync failed with error message:" + err.message + ",error code:" + err.code);
          return;
        }
      } else {
        tmpPicPath = getContext(this).cacheDir;
      }
      path = tmpPicPath + "/gifTemp" + count + ".jpeg";
      gifTempPath = tmpPicPath;
      this.saveFrame(path, null);
      count++
    }, 50);
  }


  stopGif(savaGifPath: string, gsyVideoGifSaveListener: GSYVideoGifSaveListener) {
    screenshotTimerStatus = false;
    clearInterval(screenshotTimer);
    this.pngConvertGif(gifTempPath + "/gifTemp%01d.jpeg", savaGifPath, gsyVideoGifSaveListener);
  }

  private pngConvertGif(sourcePath: string, outPath: string, gsyVideoGifSaveListener: GSYVideoGifSaveListener) {
    let callBack: ICallBack = {
      callBackResult(code: number) {
        if (gsyVideoGifSaveListener) {
          gsyVideoGifSaveListener.gifResult(code);
          fs.rmdirSync(gifTempPath);
        }
      }
    };

    MP4Parser.ffmpegCmd("ffmpeg -y -r 20 -i " + sourcePath + "  " + outPath, callBack);
  }

  /**
   * 状态切换为正在播放
   */
  public onPlayingStatus() {
    this.playStatus = PlayStatus.PLAY;
    this.onPlayingListener();
    LogUtils.getInstance().LOGI('onPlayingStatus: ' + this.xComponentId);
    let eventData: emitter.EventData = {
      data: {
        "xid": this.xComponentId
      }
    }
    emitter.emit(this.videoPlayingEvent, eventData);
  }


  /**
   * 状态切换为暂停播放
   */
  public onPauseStatus() {
    if (this.playStatus == PlayStatus.PLAY) {
      this.playStatus = PlayStatus.PAUSE;
    }
    this.onPauseListener();
    let eventData: emitter.EventData = {
      data: {
        "xid": this.xComponentId
      }
    }
    emitter.emit(this.videoPauseEvent, eventData);
  }

  /**
   * 视频切换为错误状态
   */
  public onInitStatus() {
    this.playStatus = PlayStatus.INIT;
    this.onErrorListener();
    let eventData: emitter.EventData = {
      data: {
        "xid": this.xComponentId
      }
    }
    emitter.emit(this.videoInitEvent, eventData);
  }

  selectTrack(track: number): void {
    this.mIjkMediaPlayer?.selectTrack(track+'')
  }
}