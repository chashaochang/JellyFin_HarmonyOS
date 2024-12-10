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
import Window from '@ohos.window';
import { LogUtils } from './LogUtils';

export class OrientationUtil {
  /**
   * 设置屏幕方向
   * @param orientation 屏幕方向，Window.Orientation.LANDSCAPE_INVERTED 为横屏  Window.Orientation.PORTRAIT 为竖屏
   */

  static changeOrientation(context: Context, orientation: Window.Orientation) {
    let windowClass: Window.Window | null = null;
    let promise = Window.getLastWindow(context);
    promise.then((data) => {
      windowClass = data;
      if (orientation == Window.Orientation.LANDSCAPE_INVERTED) {
        windowClass.setPreferredOrientation(orientation, (err) => {
        });
        OrientationUtil.setSystemBar(false);
      }
      if (orientation == Window.Orientation.PORTRAIT) {
        windowClass.setPreferredOrientation(orientation, (err) => {
        })
        OrientationUtil.setSystemBar(true);
      }
    }).catch((err: Error) => {
      LogUtils.getInstance().LOGI("Failed to obtain the top window. Cause:" + JSON.stringify(err));
    })
  }

  /**
   * 控制显示系统导航栏
   * @param showUi
   */

  private static async setSystemBar(showUi: boolean) {
    let windowClass = await Window.getLastWindow(getContext());
    if (showUi) {
      let names: Array<'status' | 'navigation'> = ['status'];
      await windowClass.setWindowSystemBarEnable(names);
    } else {
      await windowClass.setWindowSystemBarEnable([]);
    }
  }
}