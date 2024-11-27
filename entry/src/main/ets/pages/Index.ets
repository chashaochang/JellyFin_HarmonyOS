import { ConnectScreen } from '../features/ConnectScreen'
import { MainViewModel, ServerState } from './MainViewModel'

@Entry
@Component
struct Index {
  // pathStack: NavPathStack = new NavPathStack()
  @Provide viewModel: MainViewModel = new MainViewModel()
  @Provide showExternalConnectionError: boolean = false

  build() {
    // Navigation(this.pathStack){
    Stack() {
      if (this.viewModel.serverState === ServerState.Unset) {
        ConnectScreen()
      } else {
        Text('666')
      }
    }.width('100%').height('100%')

    // }.hideNavBar(true)
    // .mode(NavigationMode.Stack)
  }
}