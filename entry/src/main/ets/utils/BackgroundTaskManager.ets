/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = '[BackgroundTaskManager]';

/**
 * Background task tool class.
 */
export class BackgroundTaskManager {
  public static startContinuousTask(context?: common.UIAbilityContext): void {
    if (!context) {
      return;
    }
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: context.abilityInfo.bundleName,
          abilityName: context.abilityInfo.name
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj) => {
      backgroundTaskManager.startBackgroundRunning(context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, wantAgentObj).then(() => {
        hilog.info(0x0000, TAG, 'startBackgroundRunning succeeded');
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, TAG, `startBackgroundRunning failed, cause:  ${JSON.stringify(err)}`);
      });
    });
  }

  /**
   * Cancel continuous task
   */
  public static stopContinuousTask(context?: common.UIAbilityContext): void {
    if (!context) {
      return;
    }
    backgroundTaskManager.stopBackgroundRunning(context).then(() => {
      hilog.info(0x0000, TAG, 'stopBackgroundRunning succeeded');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, TAG, `stopBackgroundRunning failed, cause:  ${JSON.stringify(err)}`);
    });
  }
}