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
import media from '@ohos.multimedia.media';
import { LogUtils } from '../utils/LogUtils';
import { BaseVideoPlayer } from './BaseVideoPlayer';
import { AvPlayerStatus, Events } from './CommonConstants';
import { GlobalContext } from './GlobalContext';
import { PlayStatus } from './CommonConstants';

export class AvPlayerControl extends BaseVideoPlayer {
  private avPlayer: media.AVPlayer | null = null;
  private firstPlay: boolean = true;
  public constructor() {
    super();
    this.createAVPlayer();
  }

  async createAVPlayer() {
    LogUtils.getInstance().LOGI('createAVPlayer');
    let avPlayer: media.AVPlayer = await media.createAVPlayer();
    this.avPlayer = avPlayer;
    this.bindState();
  }

  /**
   * AVPlayer binding event.
   */
  async bindState() {
    if (this.avPlayer === null) {
      return;
    }

    this.avPlayer.on(Events.STATE_CHANGE, async (state: media.AVPlayerState) => {
      let avPlayerStatus: string = state;
      if (this.avPlayer === null) {
        return;
      }

      switch (avPlayerStatus) {
        case AvPlayerStatus.IDLE:
          LogUtils.getInstance().LOGI('AvPlayerStatus.IDLE');
          this.avPlayer.url = this.videoUrl;
          break;
        case AvPlayerStatus.INITIALIZED:
          LogUtils.getInstance().LOGI('AvPlayerStatus.INITIALIZED');
          this.avPlayer.surfaceId = this.surfaceID;
          this.avPlayer.prepare();
          break;
        case AvPlayerStatus.PREPARED:
          LogUtils.getInstance().LOGI('AvPlayerStatus.PREPARED');
          this.avPlayer.videoScaleType = 0;
          this.avPlayer.play();
          break;
        case AvPlayerStatus.PLAYING:
          LogUtils.getInstance().LOGI('AvPlayerStatus.PLAYING');
          this.onPlayingStatus();
          break;
        case AvPlayerStatus.PAUSED:
          LogUtils.getInstance().LOGI('AvPlayerStatus.PAUSED');
          break;
        case AvPlayerStatus.COMPLETED:
          LogUtils.getInstance().LOGI('AvPlayerStatus.COMPLETED');
          this.onInitStatus();
          break;
        case AvPlayerStatus.RELEASED:
          LogUtils.getInstance().LOGI('AvPlayerStatus.RELEASED');
          this.avPlayer.release();
          break;
        default:
          break;
      }
    });

    this.avPlayer.on(Events.ERROR, () => {
      this.onInitStatus();
    })
  }

  play() {
    LogUtils.getInstance().LOGI('avplayer play');
    if (this.avPlayer) {
      if (this.firstPlay == true) {
        this.avPlayer.url = this.videoUrl;
        this.firstPlay = false;
      }
      GlobalContext.getContext().setObject('xid', this.xComponentId);
      GlobalContext.getContext().setObject('currentPlayer', this);
      LogUtils.getInstance().LOGI('avplayer play1: ' + this.surfaceID);
      if (this.avPlayer.state == AvPlayerStatus.STOPPED ||
          this.avPlayer.state == AvPlayerStatus.ERROR ||
          this.avPlayer.state == AvPlayerStatus.COMPLETED) {
        this.avPlayer.reset();
      }
      this.avPlayer.play();
    }
  }

  pause() {
    if (this.avPlayer) {
      this.avPlayer.pause();
      this.onPauseStatus();
    }
  }

  stop() {
    if (this.avPlayer) {
      this.avPlayer.stop();
      this.playStatus = PlayStatus.INIT;
    }
  }

  release() {
    if (this.avPlayer) {
      this.avPlayer.release();
    }
  }

  getCurrentPosition() {
    if (this.avPlayer) {
      return this.avPlayer.currentTime;
    }
    return 0;
  }

  getDuration() {
    if (this.avPlayer) {
      return this.avPlayer.duration;
    }
    return 0;
  }

  resumePlay() {
    if (this.avPlayer) {
      this.avPlayer.play();
    }
  }

  isPlaying(): boolean {
    if (this.avPlayer) {
      return this.avPlayer.state == AvPlayerStatus.PLAYING;
    }
    return false;
  }

  seekTo(time: number): void {
    if (this.avPlayer) {
      LogUtils.getInstance().LOGI('avplayer seekTo');
      this.avPlayer.seek(time, media.SeekMode.SEEK_PREV_SYNC);
      this.avPlayer.play();
    }
  }
}