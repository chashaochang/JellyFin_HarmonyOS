import { ConnectScreen } from '../features/connect/ConnectScreen'
import { WebViewScreen } from '../webapp/WebViewScreen'
import mainViewModel, { MainViewModel, ServerState } from './MainViewModel'
import { common } from '@kit.AbilityKit';
import { ActivityEventHandler } from '../events/ActivityEventHandler';
import { AttributeUpdater } from '@kit.ArkUI';
import { HMDefaultGlobalAnimator, HMNavigation, HMRouterMgr } from '@hadss/hmrouter';
import { Constants } from '../utils/Constants';
import { BackController } from '../webapp/BackController';
import { JumpInfoInterceptor } from '../router/interceptors/JumpInfoInterceptor';
import { PlayerLifecycle } from '../router/lifecycles/PlayerLifecycle';
import { OhosSmartDialog } from 'ohos_smart_dialog';

@Entry
@ComponentV2
struct Index {
  private eventHub: common.EventHub = (getContext() as common.UIAbilityContext).eventHub;
  @Provider() mainViewModel: MainViewModel = mainViewModel
  @Provider() activityEventHandler: ActivityEventHandler = new ActivityEventHandler(this.eventHub, this.mainViewModel)
  @Provider() showExternalConnectionError: boolean = false
  modifier: NavModifier = new NavModifier();
  backController?: BackController

  aboutToAppear(): void {
    HMRouterMgr.registerGlobalInterceptor({
      interceptor: new JumpInfoInterceptor(),
      interceptorName: "jumpInfoInterceptor",
      priority: 5
    })
    HMRouterMgr.registerGlobalLifecycle({
      lifecycle: new PlayerLifecycle(),
      lifecycleName: 'playerLifecycle',
      priority: 5
    })
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
          modifier: this.modifier
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

class NavModifier extends AttributeUpdater<NavigationAttribute> {
  initializeModifier(instance: NavigationAttribute): void {
    instance.mode(NavigationMode.Stack);
    instance.navBarWidth('100%');
    instance.hideTitleBar(true);
    instance.hideToolBar(true);
  }
}