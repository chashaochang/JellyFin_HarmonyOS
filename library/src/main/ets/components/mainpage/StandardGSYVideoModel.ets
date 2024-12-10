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
export class StandardGSYVideoModel {
  private videoUrl: string = '';
  private cacheWithPlay: boolean = false;
  private title: string = '';
  private coverImage: Resource | undefined = undefined;
  private backClickListener: () => void = () => {
  };
  private fullClickListener: () => void = () => {
  };

  public setUrl(videoUrl: string, cacheWithPlay?: boolean) {
    this.videoUrl = videoUrl;
    if (cacheWithPlay) {
      this.cacheWithPlay = cacheWithPlay;
    }
  }

  public getUrl() {
    return this.videoUrl;
  }

  public getCacheWithPlay() {
    return this.cacheWithPlay;
  }

  public getTitle() {
    return this.title;
  }

  public setTitle(title: string) {
    this.title = title;
  }

  public setBackClickListener(backClickListener: () => void) {
    this.backClickListener = backClickListener;
  }

  public setFullClickListener(fullClickListener: () => void) {
    this.fullClickListener = fullClickListener;
  }

  public ExecuteFullClickListener() {
    this.fullClickListener();
  }

  public ExecuteBackClickListener() {
    this.backClickListener();
  }

  public getCoverImage() {
    return this.coverImage;
  }

  public setCoverImage(coverImage:Resource) {
    this.coverImage = coverImage;
  }
}