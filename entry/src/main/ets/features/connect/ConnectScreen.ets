import mainViewModel, { MainViewModel } from "../../pages/MainViewModel"
import Theme from "../../ui/Theme"
import { ServerSelection } from "./ServerSelection"

@ComponentV2
export struct ConnectScreen {
  @Consumer() mainViewModel: MainViewModel = mainViewModel

  build() {
    Column() {
      LogoHeader()
      ServerSelection({
        onConnected: (hostname) => {
          this.mainViewModel.switchServer(hostname)
        }
      }).width('100%').layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, bottom: AppStorage.get<number>('navBarHeight') })
    .backgroundColor(Theme.colors.background)
  }
}

@ComponentV2
struct LogoHeader {
  build() {
    Row() {
      Image($r('app.media.app_logo')).height(72)
    }.padding({ top: 25, bottom: 25 })
  }
}