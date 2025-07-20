import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, display, mediaquery, window } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { HMRouterMgr } from '@hadss/hmrouter';
import { DBManager } from '../data/DBManager';
import { AppUIState } from '../entity/AppUIState';
import { OneMoreUtil } from '../utils/OneMoreUtil';

export default class EntryAbility extends UIAbility {
  listener?: mediaquery.MediaQueryListener
  appUIState: AppUIState = AppStorageV2.connect(AppUIState, () => new AppUIState())!;

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
    AppStorage.setOrCreate('windowStage', windowStage);
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });

    windowStage.getMainWindow().then((windowClass) => {
      setTimeout(()=>{
        windowClass.setWindowBackgroundColor('#ff101010')
        windowClass.setWindowSystemBarProperties({
          statusBarColor: '#ff101010',
          navigationBarColor: '#ff101010',
          navigationBarContentColor: '#ff101010',
          isStatusBarLightIcon: true
        })
      },200)
      // 保存 UIContext， 在后续的同层渲染绘制中会用到。
      AppStorage.setOrCreate<UIContext>("UIContext", windowClass.getUIContext());
      let avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      AppStorage.setOrCreate<number>('navBarHeight', windowClass.getUIContext().px2vp(avoidArea.bottomRect.height))
      this.listener = windowClass.getUIContext().getMediaQuery().matchMediaSync('(orientation: landscape)');
      this.listener.on('change', this.onPortrait)
      //一多适配放开了旋转,这里判断手机端锁定
      if (OneMoreUtil.isNormalPhone()) {
        windowClass.setPreferredOrientation(window.Orientation.PORTRAIT)
      }
    })
  }

  onPortrait = (mediaQueryResult: mediaquery.MediaQueryResult) => { // 当满足媒体查询条件时，触发回调
    if (mediaQueryResult.matches as boolean) { // 若设备为横屏状态，更改相应的页面布局
      this.appUIState.orientation = display.Orientation.LANDSCAPE
    } else {
      this.appUIState.orientation = display.Orientation.PORTRAIT;
    }
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