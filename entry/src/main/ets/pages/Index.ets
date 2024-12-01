import { ConnectScreen } from '../features/ConnectScreen'
import { WebViewScreen } from '../features/WebViewScreen'
import { MainViewModel, ServerState } from './MainViewModel'

@Entry
@Component
struct Index {
  // pathStack: NavPathStack = new NavPathStack()
  @Provide viewModel: MainViewModel = new MainViewModel()
  @Provide showExternalConnectionError: boolean = false

  aboutToAppear(): void {
    setTimeout(()=>{
      this.viewModel.refreshServer()
    },200)
  }

  build() {
    // Navigation(this.pathStack){
    Stack() {
      if (this.viewModel.serverState === ServerState.Unset) {
        ConnectScreen()
      } else {
        WebViewScreen({
          hostname:this.viewModel.serverState.server?.hostname
        })
      }
    }.width('100%').height('100%')

    // }.hideNavBar(true)
    // .mode(NavigationMode.Stack)
  }
}