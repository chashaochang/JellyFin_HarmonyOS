import { ConnectScreen } from '../features/ConnectScreen'
import { WebViewScreen } from '../features/WebViewScreen'
import { MainViewModel, ServerState } from './MainViewModel'
import { common } from '@kit.AbilityKit';
import { ActivityEventHandler } from '../events/ActivityEventHandler';

@Entry
@Component
struct Index {
  @Provide('appPathStack') pathStack: NavPathStack = new NavPathStack()
  private eventHub: common.EventHub = (getContext() as common.UIAbilityContext).eventHub;
  private activityEventHandler: ActivityEventHandler = new ActivityEventHandler(this.eventHub)
  @Provide viewModel: MainViewModel = new MainViewModel()
  @Provide showExternalConnectionError: boolean = false

  aboutToAppear(): void {
    setTimeout(() => {
      this.viewModel.refreshServer()
    }, 200)
    this.activityEventHandler.subscribe(this.pathStack)
  }

  aboutToDisappear(): void {
    this.activityEventHandler.unsubscribe()
  }

  build() {
    Navigation(this.pathStack) {
      Stack() {
        if (this.viewModel.serverState === ServerState.Unset) {
          ConnectScreen()
        } else {
          WebViewScreen({
            hostname: this.viewModel.serverState.server?.hostname
          })
        }
      }.width('100%').height('100%')
    }.hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .width('100%').height('100%')
  }
}