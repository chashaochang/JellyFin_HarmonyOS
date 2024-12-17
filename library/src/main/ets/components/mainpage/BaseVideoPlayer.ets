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
import componentSnapshot from '@ohos.arkui.componentSnapshot';
import { IVideoPlayer } from './IVideoPlayer';
import { PlayStatus } from './CommonConstants';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { GSYVideoShotSaveListener } from '../listener/GSYVideoShotSaveListener';
import { GSYVideoGifSaveListener } from '../listener/GSYVideoGifSaveListener';
import { LogUtils } from '../utils/LogUtils';
import { ICallBack, MP4Parser } from '@ohos/mp4parser';
import { BusinessError } from '@ohos.base';
import emitter from '@ohos.events.emitter';
import { HttpProxyCacheServerBuilder } from '@ohos/video-cache';
import { GlobalContext } from "./GlobalContext";
import { PlayerType } from "./CommonConstants";

let screenshotTimerStatus: boolean = false;
let screenshotTimer: number = 0;
let gifTempPath: string = "";

export abstract class BaseVideoPlayer implements IVideoPlayer {
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

  setVideoId(id: string): void {
    this.vId = id;
  }

  setXComponentId(id: string): void {
    this.xComponentId = id;
  }

  play(): void {

  }

  resumePlay(): void {

  }

  async setUp(url: string, cacheWithPlay: boolean) {
    LogUtils.getInstance().LOGI('setUp');
    this.videoUrl = url;
    if(GlobalContext.getContext().getObject('playType') == PlayerType.SYSTEM_AVPLAYER) {
        if (this.videoUrl.startsWith('http') || this.videoUrl.startsWith('https')) {
          LogUtils.getInstance().LOGI('avplayer url is network');
        } else {
          let file = fs.openSync(this.videoUrl);
          this.videoUrl = 'fd://' + file.fd;
          LogUtils.getInstance().LOGI('avplayer fd url: ' + this.videoUrl);
        }
    }
      
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

  pause(): void {
    throw new Error('Method not implemented.');
  }

  seekTo(time: number): void {
    throw new Error('Method not implemented.');
  }

  getDuration(): number {
    return 0;
  }

  getCurrentPosition(): number {
    return 0;
  }

  stop(): void {

  }

  release(): void {

  }

  isPlaying(): boolean {
    return false;
  }

  setContext(context: object,id?:string): void {
    this.context = context;
    if (id) {
      this.xComponentId=id
    }
  }

  setOnPlayingListener(onPlayingListener: () => void): void {

  }

  setOnPauseListener(onPauseListener: () => void): void {

  }

  setOnErrorListener(onErrorListener: () => void): void {

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
}