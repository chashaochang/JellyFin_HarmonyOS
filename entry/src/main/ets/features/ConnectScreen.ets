import { MainViewModel } from "../pages/MainViewModel"
import Theme from "../ui/Theme"
import { ServerSelection } from "./ServerSelection"

@Component
export struct ConnectScreen{

  @Consume viewModel:MainViewModel
  @Consume showExternalConnectionError:boolean

  build() {
    Column(){
      LogoHeader()
      ServerSelection({
        onConnected :(hostname) =>{
          this.viewModel.switchServer(hostname)
        }
      })
    }.width('100%').height('100%').padding({left:16,right:16}).backgroundColor(Theme.colors.background)
  }
}

@Component
struct LogoHeader{
  build() {
    Row(){
      Image($r('app.media.app_logo')).height(72)
    }.padding({top:25,bottom:25})
  }
}