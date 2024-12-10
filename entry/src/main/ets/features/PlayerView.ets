import { HMLifecycle, HMLifecycleContext, HMRouter, HMRouterMgr, IHMLifecycle } from "@hadss/hmrouter"
import { GlobalContext, ToastUtil } from "@pura/harmony-utils"
import AvPlayManager from "../player/AvPlayManager"
import { PlayOptions } from "../player/interaction/PlayOptions"
import { PlayerException } from "../player/PlayerException"
import { PlayerViewModel } from "./PlayerViewModel"
import { media } from "@kit.MediaKit"
import { BaseVideoPlayer, StandardGSYVideoModel, StandardGSYVideoPlayer } from "@ohos/gsyvideoplayer/Index"

@HMRouter({
  pageUrl: '/Player',
  interceptors: ['jumpInfoInterceptor'],
  lifecycle: 'playerPageLifecycle',
  animator: 'pageAnimator'
})
@Component
export struct PlayerView {
  @State options: PlayOptions = HMRouterMgr.getCurrentParam() as PlayOptions
  backClickListener: () => void = () => {
    let player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.stop();
    }
    HMRouterMgr.pop()
  }
  @State videoModel: StandardGSYVideoModel | null = null
  @State viewModel: PlayerViewModel = new PlayerViewModel()
  @StorageProp('url') @Watch('onUrl') url: string = ''

  onUrl() {
    console.log('PlayNetWithCacheDemo', this.url)
    this.videoModel = new StandardGSYVideoModel();
    this.videoModel.setUrl(this.url, true);
    this.videoModel.setTitle('');
    this.videoModel.setBackClickListener(this.backClickListener);
    // this.videoModel.setFullClickListener(this.fullClickListener);
    this.videoModel.setCoverImage($r('app.media.app_icon'));
  }

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

  aboutToDisappear(): void {
    let player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.stop();
      player.release()
    }
  }

  build() {
    Column() {
      if (this.videoModel) {
        StandardGSYVideoPlayer({
          videoModel: this.videoModel
        }).height('100%')
      }
    }.width('100%')
    .height('100%')
  }
}

@HMLifecycle({ lifecycleName: 'playerPageLifecycle' })
export class PlayerPageLifecycle implements IHMLifecycle {
  onPageShow() {
    let player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.resumePlay();
    }
  }

  onPageHide() {
    let player = GlobalContext.getContext().getObject("currentPlayer") as BaseVideoPlayer;
    if (player) {
      player.pause();
    }
  }

  onShown(ctx: HMLifecycleContext): void {

  }

  onHidden(ctx: HMLifecycleContext): void {

  }
}