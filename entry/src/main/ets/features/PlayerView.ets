import { GlobalContext, PlayerType, StandardGSYVideoPlayer } from "@ohos/gsyvideoplayer"
import { ToastUtil } from "@pura/harmony-utils"
import { PlayOptions } from "../player/interaction/PlayOptions"
import { PlayerException } from "../player/PlayerException"
import { PlayerViewModel } from "./PlayerViewModel"

@Component
struct PlayerView{

  @Prop options:PlayOptions

  @State viewModel:PlayerViewModel = new PlayerViewModel()
  @StorageProp('url') url:string=''

  aboutToAppear(): void {
    GlobalContext.getContext().setObject("playType", PlayerType.IJK_PLAYER);
    switch (this.viewModel.queueManager.initializePlaybackQueue(this.options)){
      case PlayerException.InvalidPlayOptions:
        ToastUtil.showToast('无法解析播放信息')
        break
      case PlayerException.NetworkFailure:
        ToastUtil.showToast('无法从服务器加载媒体信息')
        break
      case PlayerException.UnsupportedContent:
        ToastUtil.showToast('该媒体无法在本设备上播放')
        break
      default:
        break
    }

  }
  private controller:VideoController=new VideoController()
  build() {
    NavDestination(){
      Column(){
        Video({
          src: this.url,
          // previewUri: this.previewUris,
          controller: this.controller,
        }).autoPlay(true).layoutWeight(1)
      }
    }.hideTitleBar(false)
  }
}

@Builder
export function PlayerViewViewBuilder(_name:string,options:PlayOptions){
  PlayerView({
    options:options
  })
}