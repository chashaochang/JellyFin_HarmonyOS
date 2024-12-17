import { HMRouter, HMRouterMgr } from "@hadss/hmrouter"
import { BaseVideoPlayer, StandardGSYVideoModel, StandardGSYVideoPlayer } from "@ohos/gsyvideoplayer"
import { GlobalContext, ToastUtil } from "@pura/harmony-utils"
import { PlayOptions } from "../../player/interaction/PlayOptions"
import { PlayerException } from "../../player/PlayerException"
import { PlayerViewModel } from "./PlayerViewModel"

@HMRouter({
  pageUrl: '/Player',
  interceptors: ['jumpInfoInterceptor'],
  lifecycle: 'playerLifecycle',
  animator: 'pageAnimator'
})
@ComponentV2
export struct PlayerView {
  options: PlayOptions = HMRouterMgr.getCurrentParam() as PlayOptions
  @Local viewModel: PlayerViewModel = new PlayerViewModel()

  aboutToAppear(): void {
    switch (this.viewModel.queueManager.initializePlaybackQueue(this.options)) {
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

  build() {
    Column() {
      if (this.viewModel.uiState.url) {
        CustomVideoPlayer({
          url:this.viewModel.uiState.url
        })
      }
    }.width('100%')
    .height('100%')
  }
}

@ComponentV2
struct CustomVideoPlayer {
  @Param @Require url: string
  @Local videoModel: StandardGSYVideoModel | null = null
  backClickListener: () => void = () => {
    let player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.stop();
    }
    HMRouterMgr.pop()
  }

  aboutToAppear(): void {
    this.videoModel = new StandardGSYVideoModel();
    this.videoModel.setUrl(this.url, true);
    this.videoModel.setTitle('');
    this.videoModel.setBackClickListener(this.backClickListener);
    // this.videoModel.setFullClickListener(this.fullClickListener);
    this.videoModel.setCoverImage($r('app.media.app_icon'));
  }

  aboutToDisappear(): void {
    let player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.stop();
      player.release()
    }
  }

  build() {
    if (this.videoModel) {
      StandardGSYVideoPlayer({
        videoModel: this.videoModel
      }).height('100%')
    }
  }
}