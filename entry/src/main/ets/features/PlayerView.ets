import { HMRouter, HMRouterMgr } from "@hadss/hmrouter"
import { GlobalContext, PlayerType, StandardGSYVideoPlayer } from "@ohos/gsyvideoplayer"
import { ToastUtil } from "@pura/harmony-utils"
import { PlayOptions } from "../player/interaction/PlayOptions"
import { PlayerException } from "../player/PlayerException"
import { PlayerViewModel } from "./PlayerViewModel"

@HMRouter({
  pageUrl: '/Player',
  interceptors:['jumpInfoInterceptor'],
  lifecycle: 'pageLifecycle',
  animator: 'pageAnimator' })
@Component
export struct PlayerView {

  @State options:PlayOptions = HMRouterMgr.getCurrentParam() as PlayOptions

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
      Column(){
        Stack(){
          Video({
            src: this.url,
            // previewUri: this.previewUris,
            controller: this.controller,
          }).autoPlay(true)
            .width('100%')
            .height('100%')
          Button(){
            Image($r('app.media.ic_back')).width(36).height(36)
          }.width(48).height(48).margin(12).backgroundColor(Color.Transparent)
          .onClick(()=>{
            HMRouterMgr.pop()
          })
        }.alignContent(Alignment.TopStart)

      }
  }
}