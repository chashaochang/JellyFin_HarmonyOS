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
import { LogUtils } from '../utils/LogUtils';
import { IVideoPlayer } from './IVideoPlayer';
import { IjkPlayerControl } from './IjkPlayerControl';
import { GlobalContext } from './GlobalContext';
import { PlayerStatus } from './CommonConstants';

@Component
export struct IjkVideoPlayer {
  mIVideoPlayer: IVideoPlayer | undefined = undefined;
  private videoId: string = 'videoId' + Math.random();
  private xComponentId = 'xid' + Math.random();
  private xComponentController = new XComponentController();
  public videoInit: (mIVideoPlayer: IVideoPlayer, xid: string) => void = (mIVideoPlayer: IVideoPlayer, xid: string) => {
  }
  @Link isVisible : Visibility;
  build() {
    Stack() {
      XComponent({
        id: this.xComponentId,
        controller:this.xComponentController,
        type: XComponentType.SURFACE,
        libraryname: 'ijkplayer_napi',
      })
        .onLoad((context:object) => {
          LogUtils.getInstance().LOGI("ijkplayer_napi onload");
          this.initDelayPlay(context);
        })
        .onDestroy(() => {
        })
        .width("100%")
        .height("100%")
    }.id(this.videoId).visibility(this.isVisible)
  }

  private initDelayPlay(context: object) {
    LogUtils.getInstance().LOGI("initDelayPlay create IjkPlayerControl");
    LogUtils.getInstance().LOGI("initDelayPlay create IjkPlayerControl videoId: " + this.videoId);
    LogUtils.getInstance().LOGI("initDelayPlay create IjkPlayerControl xComponentId: " + this.xComponentId);
    this.mIVideoPlayer = new IjkPlayerControl();
    this.mIVideoPlayer.setContext(context,this.xComponentId);
    this.mIVideoPlayer.setVideoId(this.videoId);
    this.mIVideoPlayer.setXComponentId(this.xComponentId);
    this.mIVideoPlayer.setXComponentController(this.xComponentController)
    this.videoInit(this.mIVideoPlayer, this.xComponentId);
    LogUtils.getInstance().LOGI("initDelayPlay end");
    this.mIVideoPlayer.playerStatus = PlayerStatus.INITIALIZED
  }
}