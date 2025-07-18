import { ConnectScreen } from '../features/connect/ConnectScreen'
import { WebViewScreen } from '../webapp/WebViewScreen'
import mainViewModel, { MainViewModel, ServerState } from './MainViewModel'
import { common } from '@kit.AbilityKit';
import { ActivityEventHandler } from '../events/ActivityEventHandler';
import { AppStorageV2, AttributeUpdater } from '@kit.ArkUI';
import { HMDefaultGlobalAnimator, HMNavigation } from '@hadss/hmrouter';
import { Constants } from '../utils/Constants';
import { BackController } from '../webapp/BackController';
import { OhosSmartDialog } from 'ohos_smart_dialog';
import { OneMoreUtil } from '../utils/OneMoreUtil';
import { AppUIState } from '../entity/AppUIState';

@Entry
@ComponentV2
struct Index {
  private eventHub: common.EventHub = (getContext() as common.UIAbilityContext).eventHub;
  @Provider() mainViewModel: MainViewModel = mainViewModel
  @Provider() activityEventHandler: ActivityEventHandler = new ActivityEventHandler(this.eventHub, this.mainViewModel)
  @Provider() showExternalConnectionError: boolean = false
  modifier: NavModifier = new NavModifier();
  backController?: BackController
  @Local appUIState: AppUIState = AppStorageV2.connect(AppUIState, () => new AppUIState())!;

  @Monitor('appUIState.orientation')
  onBreakpointChanged() {
    OneMoreUtil.updateNavModifier(this.appUIState)
  }

  @Monitor('appUIState.isFullScreen')
  onFullScreenChanged() {
    if (OneMoreUtil.isBigScreen()) {
      if (this.appUIState.isFullScreen) {
        this.modifier.instance?.navBarWidth(0)
      } else {
        this.modifier.instance?.navBarWidth('33%')
      }
    }
  }

  onPageShow(): void {
    AppStorage.setOrCreate('modifier', this.modifier)
  }

  aboutToAppear(): void {
    this.mainViewModel.refreshServer()
    this.activityEventHandler.subscribe()
  }

  aboutToDisappear(): void {
    this.activityEventHandler.unsubscribe()
  }

  build() {
    // @Entry中需要再套一层容器组件,Column或者Stack
    Stack() {
      // 使用HMNavigation容器
      HMNavigation({
        navigationId: Constants.NAVIGATION_ID, options: {
          standardAnimator: HMDefaultGlobalAnimator.STANDARD_ANIMATOR,
          dialogAnimator: HMDefaultGlobalAnimator.DIALOG_ANIMATOR,
          modifier: this.modifier,
        }
      }) {
        Stack() {
          if (this.mainViewModel.serverState === ServerState.Unset || this.showExternalConnectionError) {
            ConnectScreen()
          } else {
            WebViewScreen({
              onBackController: (controller: BackController) => {
                this.backController = controller
              }
            })
          }
        }.width('100%').height('100%')
      }

      // here dialog init
      OhosSmartDialog()
    }
    .height('100%')
    .width('100%')
  }

  onBackPress(): boolean | void {
    console.log('Index', 'onBackPress');
    return this.backController?.onBackPress()
  }
}

export class NavModifier extends AttributeUpdater<NavigationAttribute> {
  instance?: NavigationAttribute

  initializeModifier(instance: NavigationAttribute): void {
    this.instance = instance
    instance.hideTitleBar(true)
    let appUIState: AppUIState = AppStorageV2.connect(AppUIState, () => new AppUIState())!;
    OneMoreUtil.updateNavModifier(appUIState, instance)
  }
}