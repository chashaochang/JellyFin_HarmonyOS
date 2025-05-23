import { AbilityConstant, common, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { HMRouterMgr } from '@hadss/hmrouter';
import { DBManager } from '../data/DBManager';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    AppStorage.setOrCreate('context', this.context);
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    //预初始化
    webview.WebviewController.initializeWebEngine()
    HMRouterMgr.init({
      context: this.context
    })
    DBManager.getInstance().init(this.context)
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
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
      // 保存 UIContext， 在后续的同层渲染绘制中会用到。
      AppStorage.setOrCreate<UIContext>("UIContext", windowClass.getUIContext());
      let avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      AppStorage.setOrCreate<number>('navBarHeight', px2vp(avoidArea.bottomRect.height))
    })
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
    this.context.eventHub.emit('onForeground')
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
    this.context.eventHub.emit('onBackground')
  }
}