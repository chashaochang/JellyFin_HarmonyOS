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
import { GSYVideoGifSaveListener } from '../listener/GSYVideoGifSaveListener';
import { GSYVideoShotSaveListener } from '../listener/GSYVideoShotSaveListener';
import { PlayStatus } from './CommonConstants';

export interface IVideoPlayer {
  playStatus: PlayStatus;
  videoUrl: string;
  context: object | undefined;
  firstOrSeek: boolean;
  xComponentId: string;
  xComponentController:XComponentController;
  surfaceID: string;

  /**
   * 设置视频播放地址
   * @param url 视频播放地址
   * @param cacheWithPlay 是否开启边播边缓存
   */
  setUp(url: string, cacheWithPlay: boolean): void;

  /**
   * 开始播放
   */
  play(): void;

  /**
   * 恢复播放
   */
  resumePlay(): void;

  pause(): void;

  seekTo(time: number): void;

  getDuration(): number;

  getCurrentPosition(): number;

  stop(): void;

  isPlaying(): boolean;

  release(): void;

  /**
   * 设置XComponent context,用户不用操作
   * @param context xComponent上下文
   */
  setContext(context: Object,id?:string): void;

  /**
   * 设置XComponent vid,用户不用操作
   * @param id
   */
  setVideoId(id: string): void;

  /**
   * 设置XComponent xComponentId,用户不用操作
   * @param id
   */
  setXComponentId(id: string): void;

  setXComponentController(controller: XComponentController): void;

  setOnPlayingListener(onPlayingListener: () => void): void;

  setOnPauseListener(onPauseListener: () => void): void;

  setOnErrorListener(onErrorListener: () => void): void;

  saveFrame(fileSavePath: string, gsyVideoShotSaveListener: GSYVideoShotSaveListener): void;

  startGif(tmpPicPath?: string): void;

  stopGif(saveGifPath: string, gsyVideoGifSaveListener: GSYVideoGifSaveListener): void;
}