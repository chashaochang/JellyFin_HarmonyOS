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

import { media } from '@kit.MediaKit';
import { resourceManager } from '@kit.LocalizationKit';
import { emitter } from '@kit.BasicServicesKit';
import Logger from '../utils/Logger';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import GlobalProxyServer from './cache/GlobalProxyServer';

const CASE_ZERO = 0;
const CASE_ONE = 1;
const CASE_TWO = 2;
const CASE_THREE = 3;

export default class AvPlayManager {
  private tag: string = 'AVPlayManage';
  private avPlayer: media.AVPlayer | null = null;
  private surfaceID: string = '';
  private mgr: resourceManager.ResourceManager = {} as resourceManager.ResourceManager;
  // Current time of the video.
  private currentTime: number = 0;
  // Total video length.
  private durationTime: number = 0;
  // Playback rate selection.
  private speedSelect: number = 0;
  private fileDescriptor: resourceManager.RawFileDescriptor | null = null;
  private videoSrc: string = '';
  private fileSrc: string = '';

  async initPlayer(surfaceId: string, url:string,callback: (avPlayer: media.AVPlayer) => void): Promise<void> {
    Logger.info(this.tag, `initPlayer == initCamera surfaceId == ${surfaceId}`);
    this.surfaceID = surfaceId;
    Logger.info(this.tag, `initPlayer == this.surfaceID surfaceId == ${this.surfaceID}`);
    try {
      Logger.info(this.tag, 'initPlayer videoPlay avPlayerDemo');
      // Creates the avPlayer instance object.
      this.avPlayer = await media.createAVPlayer();
      // Creates a callback function for state machine changes.
      await this.setAVPlayerCallback(callback);
      Logger.info(this.tag, 'initPlayer videoPlay setAVPlayerCallback');
      // this.mgr = (GlobalContext.getContext().getObject('context') as (common.UIAbilityContext)).resourceManager;
      // Logger.info(this.tag, 'initPlayer videoPlay this.mgr');
      let tempUrl = await GlobalProxyServer?.getInstance()?.getServer()?.getProxyUrl(url)
      let proxyUrl: string|undefined = tempUrl ? tempUrl : url
      if(proxyUrl.startsWith((getContext() as common.UIAbilityContext).cacheDir)){
        const file = fs.openSync(proxyUrl,fs.OpenMode.READ_ONLY)
        proxyUrl = `fd://${file.fd}`
      }
      this.avPlayer.url = url;
    } catch (e) {
      Logger.error(this.tag, `initPlayer initPlayer err：${e}`);
    }
  }

  // Registering the avplayer callback function
  async setAVPlayerCallback(callback: (avPlayer: media.AVPlayer) => void): Promise<void> {
    if (this.avPlayer === null) {
      return;
    }
    // Callback function of the seek operation result
    this.avPlayer.on('seekDone', (seekDoneTime) => {
      Logger.info(this.tag, `setAVPlayerCallback AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
    });
    // error callback listening function. When an error occurs during the operation of the avPlayer,
    // the reset interface is invoked to trigger the reset process.
    this.avPlayer.on('error', (err) => {
      if (this.avPlayer === null) {
        return;
      }
      Logger.error(this.tag,
        `setAVPlayerCallback Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
      this.avPlayer.reset();
    });
    // Callback function for state machine changes
    this.avPlayer.on('stateChange', async (state, reason) => {
      if (this.avPlayer === null) {
        return;
      }
      switch (state) {
        case 'idle': // This state machine is triggered after the reset interface is successfully invoked.
          this.avPlayer.release();
          this.avPlayerChoose(callback);
          Logger.info(this.tag, 'setAVPlayerCallback AVPlayer state idle called.');
          break;
        case 'initialized': // This status is reported after the playback source is set on the AVPlayer.
          Logger.info(this.tag, 'setAVPlayerCallback AVPlayerstate initialized called.');
          // Set the display screen. This parameter is not required when the resource to be played is audio-only.
          this.avPlayer.surfaceId = this.surfaceID;
          Logger.info(this.tag, `setAVPlayerCallback this.avPlayer.surfaceId = ${this.avPlayer.surfaceId}`);
          this.avPlayer.prepare();
          break;
        case 'prepared': // This state machine is reported after the prepare interface is successfully invoked.
          Logger.info(this.tag, 'setAVPlayerCallback AVPlayer state prepared called.');
          this.durationTime = this.avPlayer.duration;
          this.currentTime = this.avPlayer.currentTime;
          this.avPlayer.play(); // Invoke the playback interface to start playback.
          Logger.info(this.tag, `setAVPlayerCallback this.speedSelect = ${this.speedSelect}`);
          switch (this.speedSelect) {
            case CASE_ZERO:
              this.videoSpeedOne();
              break;
            case CASE_ONE:
              this.videoSpeedOnePointTwentyFive();
              break;
            case CASE_TWO:
              this.videoSpeedOnePointSeventyFive();
              break;
            case CASE_THREE:
              this.videoSpeedTwo();
              break;
          }
          callback(this.avPlayer);
          break;
        case 'playing': // After the play interface is successfully invoked, the state machine is reported.
          Logger.info(this.tag, 'setAVPlayerCallback AVPlayer state playing called.');
          let eventDataTrue: emitter.EventData = {
            data: {
              'flag': true
            }
          };
          let innerEventTrue: emitter.InnerEvent = {
            eventId: 2,
            priority: emitter.EventPriority.HIGH
          };
          emitter.emit(innerEventTrue, eventDataTrue);
          break;
        case 'completed': // This state machine is triggered to report when the playback ends.
          Logger.info(this.tag, 'setAVPlayerCallback AVPlayer state completed called.');
          let eventDataFalse: emitter.EventData = {
            data: {
              'flag': false
            }
          };
          let innerEvent: emitter.InnerEvent = {
            eventId: 1,
            priority: emitter.EventPriority.HIGH
          };
          emitter.emit(innerEvent, eventDataFalse);
          break;
        default:
          Logger.info(this.tag, 'setAVPlayerCallback AVPlayer state unknown called.');
          break;
      }
    });
    // Listening function for reporting time
    this.avPlayer.on('timeUpdate', (time: number) => {
      this.currentTime = time;
      Logger.info(this.tag, `setAVPlayerCallback timeUpdate success,and new time is = ${this.currentTime}`);
    });
  }

  getDurationTime(): number {
    return this.durationTime;
  }

  getCurrentTime(): number {
    return this.currentTime;
  }

  videoPlay(): void {
    if (this.avPlayer) {
      try {
        this.avPlayer.play();
      } catch (e) {
        Logger.error(this.tag, `videoPlay = ${JSON.stringify(e)}`);
      }
    }
  }

  videoPause(): void {
    if (this.avPlayer) {
      try {
        this.avPlayer.pause();
        Logger.info(this.tag, 'videoPause');
      } catch (e) {
        Logger.info(this.tag, `videoPause== ${JSON.stringify(e)}`);
      }
    }
  }

  videoSpeedOne(): void {
    if (this.avPlayer) {
      try {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X);
        Logger.info(this.tag, 'videoSpeed_1_00');
      } catch (e) {
        Logger.info(this.tag, `videoSpeed_1_00== ${JSON.stringify(e)}`);
      }
    }
  }

  videoSpeedOnePointTwentyFive(): void {
    if (this.avPlayer) {
      try {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_25_X);
        Logger.info(this.tag, 'videoSpeed_1_25');
      } catch (e) {
        Logger.info(this.tag, `videoSpeed_1_25== ${JSON.stringify(e)}`);
      }
    }
  }

  videoSpeedOnePointSeventyFive(): void {
    if (this.avPlayer) {
      try {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_75_X);
        Logger.info(this.tag, 'videoSpeed_1_75');
      } catch (e) {
        Logger.info(this.tag, 'videoSpeed_1_75==' + JSON.stringify(e));
      }
    }
  }

  videoSpeedTwo(): void {
    if (this.avPlayer) {
      try {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_2_00_X);
        Logger.info(this.tag, `videoSpeed_2_0`);
      } catch (e) {
        Logger.info(this.tag, `videoSpeed_2_0== ${JSON.stringify(e)}`);
      }
    }
  }

  videoSeek(seekTime: number): void {
    if (this.avPlayer) {
      try {
        this.avPlayer.seek(seekTime, media.SeekMode.SEEK_PREV_SYNC);
        Logger.info(this.tag, `videoSeek== ${seekTime}`);
      } catch (e) {
        Logger.info(this.tag, `videoSeek== ${JSON.stringify(e)}`);
      }
    }
  }

  async videoReset(): Promise<void> {
    if (this.avPlayer === null) {
      return;
    }
    this.avPlayer.reset();
  }

  async videoRelease(): Promise<void> {
    if (this.avPlayer === null) {
      return;
    }
    this.avPlayer.release((err) => {
      if (err == null) {
        Logger.info(this.tag, 'videoRelease release success');
      } else {
        Logger.error(this.tag, `videoRelease release filed,error message is = ${err.message}`);
      }
    });
  }

  async videoChoose(videoSrc: string): Promise<void> {
    try {
      this.videoSrc = videoSrc;
      Logger.info(this.tag, `videoChoose this.videoSrc = ${this.videoSrc}`);
      this.videoReset();
    } catch (e) {
      Logger.info(this.tag, `videoChoose== ${JSON.stringify(e)}`);
    }
  }

  async avPlayerChoose(callback: (avPlayer: media.AVPlayer) => void): Promise<void> {
    try {
      Logger.info(this.tag, 'avPlayerChoose avPlayerDemo');
      // Creates the avPlayer instance object.
      this.avPlayer = await media.createAVPlayer();
      // Creates a callback function for state machine changes.
      this.fileDescriptor = null;
      Logger.info(this.tag, `avPlayerChoose this.fileDescriptor = ${this.fileDescriptor}`);
      await this.setAVPlayerCallback(callback);
      Logger.info(this.tag, 'avPlayerChoose setAVPlayerCallback');
      if (this.videoSrc === 'network.mp4') {
        this.fileSrc =
          'https:\/\/vd3.bdstatic.com\/mda-pdc2kmwtd2vxhiy4\/cae_h264\/1681502407203843413\/mda-pdc2kmwtd2vxhiy4.mp4';
      } else {
        this.fileSrc = this.videoSrc;
      }
      let regex: RegExp = new RegExp('^(http|https)', 'i');
      let bool = regex.test(this.fileSrc);
      if (bool) {
        Logger.info(this.tag, `avPlayerChoose avPlayerChoose fileDescriptor = ${JSON.stringify(this.fileDescriptor)}`);
        this.avPlayer.url = this.fileSrc;
      } else {
        this.fileDescriptor = await this.mgr.getRawFd(this.fileSrc);
        Logger.info(this.tag, `avPlayerChoose avPlayerChoose fileDescriptor = ${JSON.stringify(this.fileDescriptor)}`);
        this.avPlayer.fdSrc = this.fileDescriptor;
      }
    } catch (e) {
      Logger.info(this.tag, 'avPlayerChoose trycatch avPlayerChoose');
      this.videoReset();
    }
  }
}