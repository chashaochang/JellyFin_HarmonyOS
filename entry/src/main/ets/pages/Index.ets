import { ConnectScreen } from '../features/ConnectScreen'
import { WebViewScreen } from '../features/WebViewScreen'
import { MainViewModel, ServerState } from './MainViewModel'
import { common } from '@kit.AbilityKit';
import { ActivityEventHandler } from '../events/ActivityEventHandler';
import { AttributeUpdater } from '@kit.ArkUI';
import { HMDefaultGlobalAnimator, HMNavigation } from '@hadss/hmrouter';
import { GlobalContext } from '@ohos/gsyvideoplayer/src/main/ets/components/mainpage/GlobalContext';
import { BaseVideoPlayer } from '@ohos/gsyvideoplayer/Index';

@Entry
@Component
struct Index {

  private eventHub: common.EventHub = (getContext() as common.UIAbilityContext).eventHub;
  private activityEventHandler: ActivityEventHandler = new ActivityEventHandler(this.eventHub)
  @Provide viewModel: MainViewModel = new MainViewModel()
  @Provide showExternalConnectionError: boolean = false

  modifier: NavModifier = new NavModifier();

  aboutToAppear(): void {
    setTimeout(() => {
      this.viewModel.refreshServer()
    }, 200)
    this.activityEventHandler.subscribe()
  }

  aboutToDisappear(): void {
    this.activityEventHandler.unsubscribe()
  }



  build() {
    // @Entry中需要再套一层容器组件,Column或者Stack
    Column(){
      // 使用HMNavigation容器
      HMNavigation({
        navigationId: 'mainNavigation', options: {
          standardAnimator: HMDefaultGlobalAnimator.STANDARD_ANIMATOR,
          dialogAnimator: HMDefaultGlobalAnimator.DIALOG_ANIMATOR,
          modifier: this.modifier
        }
      }) {
        Stack() {
          if (this.viewModel.serverState === ServerState.Unset) {
            ConnectScreen()
          } else {
            WebViewScreen({
              server: this.viewModel.serverState.server
            })
          }
        }.width('100%').height('100%')
      }
    }
    .height('100%')
    .width('100%')
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