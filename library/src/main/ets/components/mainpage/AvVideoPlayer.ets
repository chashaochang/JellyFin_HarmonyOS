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
import { AvPlayerControl } from './AvPlayerControl';

@Component
export struct AvVideoPlayer {
  mIVideoPlayer: IVideoPlayer | undefined = undefined;
  private videoId = 'videoId' + Math.random();
  private xComponentId = 'xid' + Math.random();
  public videoInit: (mIVideoPlayer: IVideoPlayer, xid: string) => void = (mIVideoPlayer: IVideoPlayer, xid: string) => {

  }
  private xComponentController = new XComponentController();
  private surfaceID: string = '';

  build() {
    Stack() {
      XComponent({
        id: this.xComponentId,
        type: 'surface',
        libraryname: '',
        controller: this.xComponentController
      })
        .onLoad(async (context: object) => {
          this.surfaceID = this.xComponentController.getXComponentSurfaceId();
          this.initDelayPlay(context);
        })
        .onDestroy(() => {

        })
        .width('100%')
        .height('100%');
    }.id(this.videoId)
  }

  private initDelayPlay(context: object) {
    LogUtils.getInstance().LOGI('initDelayPlay create AvVideoPlayer videoId: ' + this.videoId);
    LogUtils.getInstance().LOGI('initDelayPlay create AvVideoPlayer xComponentId: ' + this.xComponentId);
    this.mIVideoPlayer = new AvPlayerControl();
    this.mIVideoPlayer.setContext(context);
    this.mIVideoPlayer.setVideoId(this.videoId);
    this.mIVideoPlayer.setXComponentId(this.xComponentId);
    this.mIVideoPlayer.surfaceID = this.surfaceID;
    LogUtils.getInstance().LOGI('initDelayPlay create AvVideoPlayer surfaceID: ' + this.surfaceID);
    this.videoInit(this.mIVideoPlayer, this.xComponentId);
  }
}