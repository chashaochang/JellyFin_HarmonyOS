import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, display, mediaquery, window } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { HMRouterMgr } from '@hadss/hmrouter';
import { DBManager } from '../data/DBManager';
import { AppUIState } from '../entity/AppUIState';
import { OneMoreUtil } from '../utils/OneMoreUtil';
import { PlayOptions } from '../player/interaction/PlayOptions';

export default class PlayerAbility extends UIAbility {
  listener?: mediaquery.MediaQueryListener
  windowStage?: window.WindowStage

  onCreate(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    //获取entry传来的播放参数
    let funcAbilityWant = want;
    let playerOptions: PlayOptions = funcAbilityWant?.parameters?.options as PlayOptions
    AppStorage.setOrCreate('playerOptions', playerOptions)
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    let funcAbilityWant = want;
    let playerOptions: PlayOptions = funcAbilityWant?.parameters?.options as PlayOptions
    AppStorage.setOrCreate('playerOptions', playerOptions)
    this.windowStage?.loadContent('pages/PcPlayerPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowStage = windowStage
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    AppStorage.setOrCreate('playerWindowStage', windowStage);
    windowStage.loadContent('pages/PcPlayerPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });

    windowStage.getMainWindow().then((windowClass) => {
      windowClass.setWindowBackgroundColor('#101010')
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#101010',
        navigationBarColor: '#101010',
        navigationBarContentColor: '#101010',
        isStatusBarLightIcon: true
      })
    })
  }


  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}